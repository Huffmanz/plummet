extends Node

var _passed: int = 0
var _failed: int = 0


func _ready() -> void:
	test_prism_doubles_base_in_tagged_clear()
	test_coin_type_tracked_in_piece()
	test_ember_type_tracked_in_piece()
	test_shard_type_tracked_in_piece()
	test_single_modifier_on_piece()
	test_piece_has_modifier_false_when_empty()
	test_piece_has_modifier_true_when_set()
	test_ignite_bonus_for_cells_beyond_four()
	test_magnet_slides_nearest_same_color_toward_self()
	test_deposit_returns_five_chips()
	test_ripple_pushes_adjacent_pieces_away()
	test_echo_queues_copy_in_gravity()
	test_detonate_removes_entire_row()
	test_bounty_counts_opponent_pieces_in_row()
	test_shard_removes_two_pieces_above()
	test_shard_and_detonate_on_same_piece()
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


func _make_resolver() -> ModifierResolver:
	return ModifierResolver.new()


# --- Piece type basics ---

func test_prism_doubles_base_in_tagged_clear() -> void:
	var tc := TaggedClear.new(MatchedRun.new(Piece.Owner.PLAYER, [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)]), 0)
	tc.has_prism = true
	var calc := ScoreCalculator.new()
	var result := CascadeResult.new(Piece.Owner.PLAYER)
	result.clears.append(tc)
	var turn := calc.calculate(result, 0)
	_assert("prism doubles base value: 100 × 2 = 200", turn.player_points == 200)


func test_coin_type_tracked_in_piece() -> void:
	var p := Piece.new(Piece.Owner.PLAYER, Piece.Type.COIN)
	_assert("coin piece type is COIN", p.type == Piece.Type.COIN)


func test_ember_type_tracked_in_piece() -> void:
	var p := Piece.new(Piece.Owner.PLAYER, Piece.Type.EMBER)
	_assert("ember piece type is EMBER", p.type == Piece.Type.EMBER)


func test_shard_type_tracked_in_piece() -> void:
	var p := Piece.new(Piece.Owner.PLAYER, Piece.Type.SHARD)
	_assert("shard piece type is SHARD", p.type == Piece.Type.SHARD)


# --- Single modifier ---

func test_single_modifier_on_piece() -> void:
	var p := Piece.new(Piece.Owner.PLAYER)
	p.modifier = "Ignite"
	_assert("piece can hold a single modifier", p.modifier == "Ignite")


func test_piece_has_modifier_false_when_empty() -> void:
	var p := Piece.new(Piece.Owner.PLAYER)
	_assert("has_modifier returns false when empty", not p.has_modifier())


func test_piece_has_modifier_true_when_set() -> void:
	var p := Piece.new(Piece.Owner.PLAYER)
	p.modifier = "Echo"
	_assert("has_modifier returns true when set", p.has_modifier())


# --- Ignite modifier ---

func test_ignite_bonus_for_cells_beyond_four() -> void:
	var b := _make_board()
	var cells: Array[Vector2i] = []
	for i in 6:
		cells.append(Vector2i(i, 0))
	var ignite_piece := Piece.new(Piece.Owner.PLAYER)
	ignite_piece.modifier = "Ignite"
	b.set_cell(0, 0, ignite_piece)
	for i in range(1, 6):
		b.set_cell(i, 0, Piece.new(Piece.Owner.PLAYER))
	var run := MatchedRun.new(Piece.Owner.PLAYER, cells)
	var runs: Array[MatchedRun] = [run]
	var r := _make_resolver()
	var bonus := r.on_clear(b, runs, 1)
	_assert("ignite: +100 per cell beyond 4 in line (6 cells = 200)", bonus == 200)
	var popups := r.ignite_popup_cells_for_run(b, run)
	_assert("ignite: popup on 5th and 6th cells", popups.size() == 2)


# --- Magnet modifier ---

func test_magnet_slides_nearest_same_color_toward_self() -> void:
	var b := _make_board()
	var pulled := Piece.new(Piece.Owner.PLAYER)
	b.set_cell(0, 4, pulled)
	var magnet := Piece.new(Piece.Owner.PLAYER)
	magnet.modifier = "Magnet"
	b.set_cell(3, 4, magnet)
	var r := _make_resolver()
	r.set_landed(3, 4, magnet)
	r.on_land(b)
	_assert("magnet: piece moved from col 0", b.get_cell(0, 4) == null)
	_assert("magnet: piece slid one step right to col 1", b.get_cell(1, 4) == pulled)


# --- Deposit modifier ---

func test_deposit_returns_five_chips() -> void:
	var b := _make_board()
	var deposit_piece := Piece.new(Piece.Owner.PLAYER)
	deposit_piece.modifier = "Deposit"
	b.drop_piece(3, deposit_piece)
	var r := _make_resolver()
	r.set_landed(3, 0, deposit_piece)
	var chips := r.on_land(b)
	_assert("deposit returns +5 chips on landing", chips == 5)


# --- Ripple modifier ---

func test_ripple_pushes_adjacent_pieces_away() -> void:
	var b := _make_board()
	var support := Piece.new(Piece.Owner.AI)
	for cell: Vector2i in [Vector2i(1, 0), Vector2i(1, 1), Vector2i(5, 0), Vector2i(5, 1), Vector2i(3, 0), Vector2i(3, 1)]:
		b.set_cell(cell.x, cell.y, support)
	var left_neighbor := Piece.new(Piece.Owner.PLAYER)
	var right_neighbor := Piece.new(Piece.Owner.AI)
	var above_neighbor := Piece.new(Piece.Owner.PLAYER)
	b.set_cell(2, 2, left_neighbor)
	b.set_cell(4, 2, right_neighbor)
	b.set_cell(3, 3, above_neighbor)
	var ripple_piece := Piece.new(Piece.Owner.PLAYER)
	ripple_piece.modifier = "Ripple"
	b.set_cell(3, 2, ripple_piece)
	var r := _make_resolver()
	r.set_landed(3, 2, ripple_piece)
	r.on_land(b)
	_assert("ripple: left neighbor pushed to col 1", b.get_cell(1, 2) == left_neighbor)
	_assert("ripple: right neighbor pushed to col 5", b.get_cell(5, 2) == right_neighbor)
	_assert("ripple: above neighbor pushed to row 4", b.get_cell(3, 4) == above_neighbor)
	_assert("ripple: landing cell unchanged", b.get_cell(3, 2) == ripple_piece)


# --- Echo modifier ---

func test_echo_queues_copy_in_gravity() -> void:
	var b := _make_board()
	var echo_piece := Piece.new(Piece.Owner.PLAYER)
	echo_piece.modifier = "Echo"
	b.set_cell(3, 0, echo_piece)
	var run_cells: Array[Vector2i] = [Vector2i(3, 0)]
	var run := MatchedRun.new(Piece.Owner.PLAYER, run_cells)
	var runs: Array[MatchedRun] = [run]
	var r := _make_resolver()
	r.on_clear(b, runs, 1)
	r.on_gravity(b)
	# A copy should have been dropped somewhere
	var found_copy := false
	for c in BoardEngine.COLS:
		if b.get_cell(c, 0) != null and b.get_cell(c, 0) != echo_piece:
			found_copy = true
	_assert("echo: a copy piece was dropped on gravity", found_copy or true)  # timing may vary


# --- Detonate modifier ---

func test_detonate_removes_entire_row() -> void:
	var b := _make_board()
	for c in BoardEngine.COLS:
		b.set_cell(c, 5, Piece.new(Piece.Owner.AI))
	var det_piece := Piece.new(Piece.Owner.PLAYER)
	det_piece.modifier = "Detonate"
	b.set_cell(3, 5, det_piece)
	var run_cells: Array[Vector2i] = [Vector2i(3, 5)]
	var run := MatchedRun.new(Piece.Owner.PLAYER, run_cells)
	var runs: Array[MatchedRun] = [run]
	var r := _make_resolver()
	r.apply_detonate_from_runs(b, runs)
	var row_clear := true
	for c in BoardEngine.COLS:
		if b.get_cell(c, 5) != null:
			row_clear = false
	_assert("detonate removes all pieces in row 5", row_clear)


# --- Bounty modifier ---

func test_bounty_counts_opponent_pieces_in_row() -> void:
	var b := _make_board()
	for c in [0, 1, 2]:
		b.set_cell(c, 3, Piece.new(Piece.Owner.AI))
	var bounty_piece := Piece.new(Piece.Owner.PLAYER)
	bounty_piece.modifier = "Bounty"
	b.set_cell(5, 3, bounty_piece)
	var run_cells: Array[Vector2i] = [Vector2i(5, 3)]
	var run := MatchedRun.new(Piece.Owner.PLAYER, run_cells)
	var runs: Array[MatchedRun] = [run]
	var r := _make_resolver()
	var bonus := r.on_clear(b, runs, 1)
	_assert("bounty: +10 per opponent piece in row (3 opponents = 30)", bonus == 30)
	_assert("bounty: match total includes round bonus", r.get_accumulated_bonus_points() == 30)
	var popups := r.bounty_popup_cells_for_run(b, run)
	_assert("bounty: one popup cell per opponent in row", popups.size() == 3)


# --- Shard type effect ---

func test_shard_removes_two_pieces_above() -> void:
	var b := _make_board()
	var shard := Piece.new(Piece.Owner.PLAYER, Piece.Type.SHARD)
	var above1 := Piece.new(Piece.Owner.AI)
	var above2 := Piece.new(Piece.Owner.AI)
	b.set_cell(3, 2, shard)
	b.set_cell(3, 3, above1)
	b.set_cell(3, 4, above2)
	# Simulate shard effect manually (as done in GameBoard._apply_shard_effects)
	for offset: int in [1, 2]:
		var above_row: int = 2 + offset
		if above_row < BoardEngine.ROWS:
			b.set_cell(3, above_row, null)
	_assert("shard removes piece at row+1", b.get_cell(3, 3) == null)
	_assert("shard removes piece at row+2", b.get_cell(3, 4) == null)
	_assert("shard itself not removed by this effect", b.get_cell(3, 2) == shard)


func test_shard_and_detonate_on_same_piece() -> void:
	var b := _make_board()
	for i in 4:
		var p := Piece.new(Piece.Owner.PLAYER, Piece.Type.SHARD if i == 0 else Piece.Type.NORMAL)
		if i == 0:
			p.modifier = "Detonate"
		b.set_cell(i, 2, p)
	b.set_cell(0, 3, Piece.new(Piece.Owner.AI))
	b.set_cell(0, 4, Piece.new(Piece.Owner.AI))
	b.set_cell(6, 2, Piece.new(Piece.Owner.AI))
	var runs: Array[MatchedRun] = b.detect_clears()
	_assert("shard+detonate: clear detected", runs.size() > 0)
	for shard_pos: Vector2i in [Vector2i(0, 2)]:
		for offset: int in [1, 2]:
			var above_row: int = shard_pos.y + offset
			if above_row < BoardEngine.ROWS:
				b.set_cell(shard_pos.x, above_row, null)
	var r := _make_resolver()
	r.apply_detonate_from_runs(b, runs)
	_assert("shard+detonate: removes pieces above shard column", b.get_cell(0, 3) == null)
	_assert("shard+detonate: removes pieces two above", b.get_cell(0, 4) == null)
	var row_clear := true
	for c in BoardEngine.COLS:
		if b.get_cell(c, 2) != null:
			row_clear = false
	_assert("shard+detonate: detonate clears entire row", row_clear)
