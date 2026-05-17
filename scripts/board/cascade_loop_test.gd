extends Node

var _passed: int = 0
var _failed: int = 0


func _ready() -> void:
	test_no_clears_exits_immediately()
	test_cascade_depth_1()
	test_cascade_depth_reports_correctly()
	test_attribution_covers_all_clears()
	test_cross_color_player_ai_player()
	test_cross_color_not_set_player_ai_only()
	test_simultaneous_clears_same_depth()
	test_loop_terminates_on_stable_board()
	test_hooks_called_in_order()
	print("-----------------------------")
	print("Results: %d passed, %d failed" % [_passed, _failed])


func _assert(label: String, condition: bool) -> void:
	if condition:
		print("[PASS] %s" % label)
		_passed += 1
	else:
		print("[FAIL] %s" % label)
		_failed += 1


func _make_loop() -> CascadeLoop:
	return CascadeLoop.new()


func _make_board() -> BoardEngine:
	return BoardEngine.new()


func _p() -> Piece:
	return Piece.new(Piece.Owner.PLAYER)


func _ai() -> Piece:
	return Piece.new(Piece.Owner.AI)


# No clears on drop → loop exits immediately with empty result.
func test_no_clears_exits_immediately() -> void:
	var board := _make_board()
	board.drop_piece(0, _p())
	var result := _make_loop().run(board, Piece.Owner.PLAYER)
	_assert("no clears: result.clears is empty", result.clears.is_empty())
	_assert("no clears: max_depth is 0", result.max_depth == 0)
	_assert("no clears: cross_color is false", result.cross_color == false)


# Setup: AI vertical in col 0 (rows 0-3), player at col 0 row 4 and cols 1-3 row 0.
# Depth 0: AI vertical clears. Gravity drops player from row 4 to row 0.
# Depth 1: PLAYER horizontal at row 0 (cols 0-3) clears.
func test_cascade_depth_1() -> void:
	var board := _make_board()
	for r in 4:
		board.set_cell(0, r, _ai())
	board.set_cell(0, 4, _p())
	board.set_cell(1, 0, _p())
	board.set_cell(2, 0, _p())
	board.set_cell(3, 0, _p())

	var result := _make_loop().run(board, Piece.Owner.AI)
	_assert("depth 1 cascade: 2 clear rounds recorded", result.clears.size() == 2)
	_assert("depth 1 cascade: max_depth is 1", result.max_depth == 1)


# Same board — verify the second clear is tagged at depth 1.
func test_cascade_depth_reports_correctly() -> void:
	var board := _make_board()
	for r in 4:
		board.set_cell(0, r, _ai())
	board.set_cell(0, 4, _p())
	board.set_cell(1, 0, _p())
	board.set_cell(2, 0, _p())
	board.set_cell(3, 0, _p())

	var result := _make_loop().run(board, Piece.Owner.AI)
	var depths: Array = []
	for tc: TaggedClear in result.clears:
		depths.append(tc.depth)
	_assert("depth tags: first clear at depth 0", depths.has(0))
	_assert("depth tags: second clear at depth 1", depths.has(1))


# Col 0: AI vertical (rows 0-3) cascades into a player horizontal at row 0.
# Verifies result.attribution == PLAYER even though an AI clear occurs in the chain.
func test_attribution_covers_all_clears() -> void:
	var board := _make_board()
	for r in 4:
		board.set_cell(0, r, _ai())
	board.set_cell(0, 4, _p())
	board.set_cell(1, 0, _p())
	board.set_cell(2, 0, _p())
	board.set_cell(3, 0, _p())

	var result := _make_loop().run(board, Piece.Owner.PLAYER)
	var has_ai_clear := result.clears.any(func(tc: TaggedClear) -> bool: return tc.run.owner == Piece.Owner.AI)
	_assert("attribution: AI clears present in chain", has_ai_clear)
	_assert("attribution: result.attribution is PLAYER", result.attribution == Piece.Owner.PLAYER)


# Cols 0-2: P(row0), AI(row1), P(row2). Col 3: P(row0), AI(row1), P(row3).
# Depth 0: player horizontal (row 0) + AI horizontal (row 1) simultaneously → ai_cleared = true.
# After gravity all four cols land player at row 0 → depth 1: player clear → cross_color confirmed.
# Col 3 has P at row 3 (not row 2) to avoid a simultaneous row-2 player detection at depth 0.
func test_cross_color_player_ai_player() -> void:
	var board := _make_board()
	for c in 3:
		board.set_cell(c, 0, _p())
		board.set_cell(c, 1, _ai())
		board.set_cell(c, 2, _p())
	board.set_cell(3, 0, _p())
	board.set_cell(3, 1, _ai())
	board.set_cell(3, 3, _p())

	var result := _make_loop().run(board, Piece.Owner.PLAYER)
	_assert("cross_color: player→AI→player sets flag", result.cross_color == true)


# Col 0 stacked P(0-3), AI(4-7) — no further player clear after AI.
func test_cross_color_not_set_player_ai_only() -> void:
	var board := _make_board()
	for r in 4:
		board.set_cell(0, r, _p())
	for r in range(4, 8):
		board.set_cell(0, r, _ai())

	var result := _make_loop().run(board, Piece.Owner.PLAYER)
	_assert("cross_color: player→AI only does not set flag", result.cross_color == false)


# Row 0: 4 player pieces. Row 1: 4 AI pieces.
# Both detected at depth 0 simultaneously.
func test_simultaneous_clears_same_depth() -> void:
	var board := _make_board()
	for c in 4:
		board.set_cell(c, 0, _p())
		board.set_cell(c, 1, _ai())

	var result := _make_loop().run(board, Piece.Owner.PLAYER)
	_assert("simultaneous: 2 clears total", result.clears.size() == 2)
	var all_depth_zero := result.clears.all(func(tc: TaggedClear) -> bool: return tc.depth == 0)
	_assert("simultaneous: both recorded at depth 0", all_depth_zero)


# Verifies the loop exits cleanly on a board that stabilises after one clear round.
func test_loop_terminates_on_stable_board() -> void:
	var board := _make_board()
	for c in 4:
		board.drop_piece(c, _p())

	var result := _make_loop().run(board, Piece.Owner.PLAYER)
	_assert("terminates: loop exits after single clear round", result.clears.size() == 1)


# Verifies hooks fire at the right points and in order.
func test_hooks_called_in_order() -> void:
	var board := _make_board()
	for c in 4:
		board.drop_piece(c, _p())

	var events: Array[String] = []
	var loop := _make_loop()
	loop.register_on_land(func(_b: BoardEngine) -> void: events.append("land"))
	loop.register_on_clear(func(_b: BoardEngine, _r: Array) -> void: events.append("clear"))
	loop.register_on_gravity(func(_b: BoardEngine) -> void: events.append("gravity"))

	loop.run(board, Piece.Owner.PLAYER)

	_assert("hooks: land fires first", events.size() >= 1 and events[0] == "land")
	_assert("hooks: clear fires second", events.size() >= 2 and events[1] == "clear")
	_assert("hooks: gravity fires third", events.size() >= 3 and events[2] == "gravity")
