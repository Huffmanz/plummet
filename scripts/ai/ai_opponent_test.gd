extends Node

var _passed: int = 0
var _failed: int = 0


func _ready() -> void:
	# AIOpponent — column selection
	test_choose_column_returns_valid_column()
	test_choose_column_returns_minus_one_when_board_full()
	test_heuristic_prefers_ai_clear()
	test_heuristic_blocks_player_clear()
	test_heuristic_penalizes_giving_player_a_clear()
	test_heuristic_height_penalty()
	test_heuristic_extends_ai_line()
	test_noise_zero_is_deterministic()
	test_noise_full_picks_random()
	test_tie_broken_among_equal_columns()

	# AIOpponent — piece queue
	test_advance_queue_shifts_pieces()

	# AIOpponent — gimmick hooks
	test_on_turn_start_fires_before_selection()
	test_on_column_selected_can_override_column()
	test_on_column_selected_ignores_full_column_override()
	test_on_piece_landed_fires()
	test_on_cascade_complete_fires()
	test_on_player_turn_start_fires()
	test_on_player_piece_landed_fires()

	# TurnManager
	test_turn_manager_starts_on_player()
	test_turn_manager_alternates()
	test_turn_manager_ends_on_turn_exhaustion()
	test_turn_manager_ends_on_board_full()
	test_turn_manager_on_ai_skipped_ends_match()
	test_turn_manager_no_signal_after_match_end()

	print("-----------------------------")
	print("Results: %d passed, %d failed" % [_passed, _failed])


func _assert(label: String, condition: bool) -> void:
	if condition:
		print("[PASS] %s" % label)
		_passed += 1
	else:
		print("[FAIL] %s" % label)
		_failed += 1


func _make_board() -> BoardEngine:
	return BoardEngine.new()


func _make_ai(p_noise: float = 0.0) -> AIOpponent:
	return AIOpponent.new(p_noise)


# --- AIOpponent column selection ---

func test_choose_column_returns_valid_column() -> void:
	var b := _make_board()
	var ai := _make_ai()
	var col: int = ai.choose_column(b)
	_assert("choose_column returns 0–6 on empty board", col >= 0 and col < BoardEngine.COLS)


func test_choose_column_returns_minus_one_when_board_full() -> void:
	var b := _make_board()
	for c in BoardEngine.COLS:
		for _r in BoardEngine.ROWS:
			b.drop_piece(c, Piece.new(Piece.Owner.PLAYER))
	var ai := _make_ai()
	_assert("choose_column returns -1 when board is full", ai.choose_column(b) == -1)


func test_heuristic_prefers_ai_clear() -> void:
	# 3 AI pieces in a row at cols 0-2 row 0 — col 3 completes the 4-in-a-row.
	var b := _make_board()
	for c in 3:
		b.drop_piece(c, Piece.new(Piece.Owner.AI))
	var ai := _make_ai()
	var col: int = ai.choose_column(b)
	_assert("heuristic picks col that completes AI 4-in-a-row", col == 3)


func test_heuristic_blocks_player_clear() -> void:
	# Player has 3-in-a-row at cols 0-2 row 0. Col 3 completes their threat.
	var b := _make_board()
	for c in 3:
		b.drop_piece(c, Piece.new(Piece.Owner.PLAYER))
	var ai := _make_ai()
	var col: int = ai.choose_column(b)
	_assert("heuristic blocks player 4-in-a-row threat", col == 3)


func test_heuristic_penalizes_giving_player_a_clear() -> void:
	# AI piece at col 0 blocks the left extension.
	# Player pieces at cols 1-3 → only threat is col 4.
	# Col 4: blocks (+800), player has no clear left → net 800.
	# Other cols: open col 4 to player (−500).
	var b := _make_board()
	b.drop_piece(0, Piece.new(Piece.Owner.AI))
	b.drop_piece(1, Piece.new(Piece.Owner.PLAYER))
	b.drop_piece(2, Piece.new(Piece.Owner.PLAYER))
	b.drop_piece(3, Piece.new(Piece.Owner.PLAYER))
	var ai := _make_ai()
	var col: int = ai.choose_column(b)
	_assert("heuristic avoids column that opens a player clear", col == 4)


func test_heuristic_height_penalty() -> void:
	# Fill col 1 to row 10 (tall, but one slot left at the top).
	# Fill cols 2-6 completely. Only col 0 and col 1 are valid.
	# Col 1 landing row = 10 → above halfway (6) → penalty -40.
	var b := _make_board()
	for _r in (BoardEngine.ROWS - 1):
		b.drop_piece(1, Piece.new(Piece.Owner.PLAYER))
	for c in range(2, BoardEngine.COLS):
		for _r in BoardEngine.ROWS:
			b.drop_piece(c, Piece.new(Piece.Owner.PLAYER))
	var ai := _make_ai()
	var col: int = ai.choose_column(b)
	_assert("heuristic prefers lower column over tall one", col == 0)


func test_heuristic_extends_ai_line() -> void:
	# One AI piece at col 3 row 0. Cols 2 and 4 are horizontally adjacent (+100),
	# col 3 itself lands at row 1 (vertically adjacent, also +100). All three tie
	# and score higher than non-adjacent columns.
	var b := _make_board()
	b.drop_piece(3, Piece.new(Piece.Owner.AI))
	var ai := _make_ai()
	var col: int = ai.choose_column(b)
	_assert("heuristic prefers column adjacent to existing AI piece", col == 2 or col == 3 or col == 4)


func test_noise_zero_is_deterministic() -> void:
	var b := _make_board()
	b.drop_piece(0, Piece.new(Piece.Owner.AI))
	b.drop_piece(1, Piece.new(Piece.Owner.AI))
	b.drop_piece(2, Piece.new(Piece.Owner.AI))
	var ai := _make_ai(0.0)
	var first: int = ai.choose_column(b)
	var second: int = ai.choose_column(b)
	_assert("noise=0 gives same column on identical board", first == second)


func test_noise_full_picks_random() -> void:
	var b := _make_board()
	var ai := _make_ai(1.0)
	var seen: Dictionary = {}
	for _i in 50:
		seen[ai.choose_column(b)] = true
	_assert("noise=1.0 produces multiple distinct columns over 50 calls", seen.size() > 1)


func test_tie_broken_among_equal_columns() -> void:
	# On a completely empty board all columns score equally — tie-break picks randomly.
	var b := _make_board()
	var ai := _make_ai(0.0)
	var seen: Dictionary = {}
	for _i in 50:
		seen[ai.choose_column(b)] = true
	_assert("ties on empty board are broken randomly (>1 column seen in 50 calls)", seen.size() > 1)


# --- AIOpponent piece queue ---

func test_advance_queue_shifts_pieces() -> void:
	var ai := _make_ai()
	var original_next: Piece = ai.next_piece
	ai.advance_queue()
	_assert("advance_queue promotes next_piece to current_piece", ai.current_piece == original_next)
	_assert("advance_queue generates a new next_piece", ai.next_piece != original_next)


# --- AIOpponent gimmick hooks ---
# GDScript 4 captures primitives (bool, int) by value in lambdas, so state
# that must be mutated inside a lambda is wrapped in a single-element Array.

func test_on_turn_start_fires_before_selection() -> void:
	var b := _make_board()
	var ai := _make_ai()
	var fired: Array = [false]
	ai.register_on_turn_start(func(_board: BoardEngine) -> void:
		fired[0] = true
	)
	ai.choose_column(b)
	_assert("on_turn_start hook fires during choose_column", fired[0])


func test_on_column_selected_can_override_column() -> void:
	var b := _make_board()
	var ai := _make_ai()
	ai.register_on_column_selected(func(_board: BoardEngine, _col: int) -> int:
		return 5
	)
	var col: int = ai.choose_column(b)
	_assert("on_column_selected hook can override the chosen column", col == 5)


func test_on_column_selected_ignores_full_column_override() -> void:
	var b := _make_board()
	for _r in BoardEngine.ROWS:
		b.drop_piece(5, Piece.new(Piece.Owner.PLAYER))
	var ai := _make_ai()
	ai.register_on_column_selected(func(_board: BoardEngine, _col: int) -> int:
		return 5
	)
	var col: int = ai.choose_column(b)
	_assert("on_column_selected hook cannot redirect to a full column", col != 5)


func test_on_piece_landed_fires() -> void:
	var b := _make_board()
	var ai := _make_ai()
	var landed_col: Array = [-1]
	ai.register_on_piece_landed(func(_board: BoardEngine, c: int, _row: int) -> void:
		landed_col[0] = c
	)
	ai.fire_on_piece_landed(b, 3, 0)
	_assert("on_piece_landed hook receives correct column", landed_col[0] == 3)


func test_on_cascade_complete_fires() -> void:
	var b := _make_board()
	var ai := _make_ai()
	var fired: Array = [false]
	ai.register_on_cascade_complete(func(_board: BoardEngine, _result: CascadeResult) -> void:
		fired[0] = true
	)
	var result := CascadeResult.new(Piece.Owner.AI)
	ai.fire_on_cascade_complete(b, result)
	_assert("on_cascade_complete hook fires", fired[0])


func test_on_player_turn_start_fires() -> void:
	var b := _make_board()
	var ai := _make_ai()
	var fired: Array = [false]
	ai.register_on_player_turn_start(func(_board: BoardEngine) -> void:
		fired[0] = true
	)
	ai.fire_on_player_turn_start(b)
	_assert("on_player_turn_start hook fires", fired[0])


func test_on_player_piece_landed_fires() -> void:
	var b := _make_board()
	var ai := _make_ai()
	var landed_row: Array = [-1]
	ai.register_on_player_piece_landed(func(_board: BoardEngine, _c: int, r: int) -> void:
		landed_row[0] = r
	)
	ai.fire_on_player_piece_landed(b, 0, 7)
	_assert("on_player_piece_landed hook receives correct row", landed_row[0] == 7)


# --- TurnManager ---

func test_turn_manager_starts_on_player() -> void:
	var tm := TurnManager.new()
	var got_player: Array = [false]
	tm.player_turn_started.connect(func(_remaining: int) -> void:
		got_player[0] = true
	)
	tm.start()
	_assert("TurnManager.start() emits player_turn_started", got_player[0])


func test_turn_manager_alternates() -> void:
	var b := _make_board()
	var tm := TurnManager.new()
	var sequence: Array[String] = []
	tm.player_turn_started.connect(func(_r: int) -> void: sequence.append("player"))
	tm.ai_turn_started.connect(func(_r: int) -> void: sequence.append("ai"))
	tm.start()
	tm.advance(b)
	tm.advance(b)
	_assert("TurnManager alternates: player→ai→player", sequence == ["player", "ai", "player"])


func test_turn_manager_ends_on_turn_exhaustion() -> void:
	var b := _make_board()
	var tm := TurnManager.new()
	var result: Array = [false, TurnManager.MatchEndReason.BOARD_FULL]
	tm.match_ended.connect(func(r: TurnManager.MatchEndReason) -> void:
		result[0] = true
		result[1] = r
	)
	tm.start()
	for _i in TurnManager.TURNS_PER_PLAYER * 2:
		tm.advance(b)
	_assert("TurnManager ends match after 80 advances", result[0])
	_assert("match_ended reason is TURNS_EXHAUSTED", result[1] == TurnManager.MatchEndReason.TURNS_EXHAUSTED)


func test_turn_manager_ends_on_board_full() -> void:
	var b := _make_board()
	for c in BoardEngine.COLS:
		for _r in BoardEngine.ROWS:
			b.drop_piece(c, Piece.new(Piece.Owner.PLAYER))
	var tm := TurnManager.new()
	var result: Array = [false, TurnManager.MatchEndReason.TURNS_EXHAUSTED]
	tm.match_ended.connect(func(r: TurnManager.MatchEndReason) -> void:
		result[0] = true
		result[1] = r
	)
	tm.start()
	tm.advance(b)
	_assert("TurnManager ends match when board is full", result[0])
	_assert("match_ended reason is BOARD_FULL", result[1] == TurnManager.MatchEndReason.BOARD_FULL)


func test_turn_manager_on_ai_skipped_ends_match() -> void:
	var tm := TurnManager.new()
	var ended: Array = [false]
	tm.match_ended.connect(func(_r: TurnManager.MatchEndReason) -> void: ended[0] = true)
	tm.start()
	tm.on_ai_skipped()
	_assert("on_ai_skipped ends the match", ended[0])


func test_turn_manager_no_signal_after_match_end() -> void:
	var tm := TurnManager.new()
	var end_count: Array = [0]
	tm.match_ended.connect(func(_r: TurnManager.MatchEndReason) -> void: end_count[0] += 1)
	tm.start()
	tm.on_ai_skipped()
	tm.on_ai_skipped()
	_assert("match_ended only fires once even after duplicate end calls", end_count[0] == 1)
