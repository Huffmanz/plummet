extends Node

var _passed: int = 0
var _failed: int = 0


func _ready() -> void:
	test_drop_lands_at_correct_row()
	test_drop_stacks_on_existing_pieces()
	test_drop_into_full_column_returns_invalid()
	test_drop_full_column_does_not_modify_board()
	test_gravity_packs_to_bottom()
	test_gravity_noop_on_full_column()
	test_gravity_noop_on_empty_column()
	test_detect_horizontal_clear()
	test_detect_vertical_clear()
	test_detect_diagonal_ascending_clear()
	test_detect_diagonal_descending_clear()
	test_run_of_five_returns_all_five()
	test_intersection_cell_appears_in_both_runs()
	test_intersection_cell_removed_once()
	test_mixed_owner_no_clear()
	test_empty_board_no_clears()
	test_landing_row_stacks_above_highest_piece()
	test_landing_row_ignores_internal_gap()
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


func test_drop_lands_at_correct_row() -> void:
	var b := _make_board()
	var row := b.drop_piece(3, Piece.new(Piece.Owner.PLAYER))
	_assert("drop into empty column lands at row 0", row == 0)


func test_drop_stacks_on_existing_pieces() -> void:
	var b := _make_board()
	b.drop_piece(3, Piece.new(Piece.Owner.PLAYER))
	b.drop_piece(3, Piece.new(Piece.Owner.PLAYER))
	var row := b.drop_piece(3, Piece.new(Piece.Owner.PLAYER))
	_assert("third drop in column 3 lands at row 2", row == 2)


func test_drop_into_full_column_returns_invalid() -> void:
	var b := _make_board()
	for i in BoardEngine.ROWS:
		b.drop_piece(0, Piece.new(Piece.Owner.PLAYER))
	var row := b.drop_piece(0, Piece.new(Piece.Owner.PLAYER))
	_assert("drop into full column returns -1", row == -1)


func test_drop_full_column_does_not_modify_board() -> void:
	var b := _make_board()
	for i in BoardEngine.ROWS:
		b.drop_piece(0, Piece.new(Piece.Owner.PLAYER))
	b.drop_piece(0, Piece.new(Piece.Owner.AI))
	var top: Piece = b.get_cell(0, BoardEngine.ROWS - 1)
	_assert("full column top cell unchanged after rejected drop", top != null and top.owner == Piece.Owner.PLAYER)


func test_gravity_packs_to_bottom() -> void:
	var b := _make_board()
	# Place pieces at rows 0 and 2 by dropping 3 and removing the middle one.
	b.drop_piece(0, Piece.new(Piece.Owner.PLAYER))
	b.drop_piece(0, Piece.new(Piece.Owner.AI))
	b.drop_piece(0, Piece.new(Piece.Owner.PLAYER))
	# Manually clear row 1 to simulate a removal.
	var runs: Array[MatchedRun] = [MatchedRun.new(Piece.Owner.AI, [Vector2i(0, 1)])]
	b.remove_clears(runs)
	b.apply_gravity()
	var r0: Piece = b.get_cell(0, 0)
	var r1: Piece = b.get_cell(0, 1)
	var r2: Piece = b.get_cell(0, 2)
	_assert("gravity: row 0 occupied after settle", r0 != null)
	_assert("gravity: row 1 occupied after settle", r1 != null)
	_assert("gravity: row 2 empty after settle", r2 == null)


func test_gravity_noop_on_full_column() -> void:
	var b := _make_board()
	for i in BoardEngine.ROWS:
		b.drop_piece(0, Piece.new(Piece.Owner.PLAYER))
	b.apply_gravity()
	_assert("gravity noop on full column: top still filled", b.get_cell(0, BoardEngine.ROWS - 1) != null)


func test_gravity_noop_on_empty_column() -> void:
	var b := _make_board()
	b.apply_gravity()
	_assert("gravity noop on empty column: row 0 still null", b.get_cell(0, 0) == null)


func test_detect_horizontal_clear() -> void:
	var b := _make_board()
	for c in 4:
		b.drop_piece(c, Piece.new(Piece.Owner.PLAYER))
	var runs := b.detect_clears()
	_assert("horizontal 4-in-a-row detected", runs.size() == 1 and runs[0].cells.size() == 4)


func test_detect_vertical_clear() -> void:
	var b := _make_board()
	for _i in 4:
		b.drop_piece(0, Piece.new(Piece.Owner.PLAYER))
	var runs := b.detect_clears()
	_assert("vertical 4-in-a-row detected", runs.size() == 1 and runs[0].cells.size() == 4)


func test_detect_diagonal_ascending_clear() -> void:
	var b := _make_board()
	# Build staircase so pieces land on the diagonal.
	# col 0: 1 piece (lands r0), col 1: 2 pieces (lands r1), etc.
	b.drop_piece(0, Piece.new(Piece.Owner.PLAYER))
	b.drop_piece(1, Piece.new(Piece.Owner.AI))
	b.drop_piece(1, Piece.new(Piece.Owner.PLAYER))
	b.drop_piece(2, Piece.new(Piece.Owner.AI))
	b.drop_piece(2, Piece.new(Piece.Owner.AI))
	b.drop_piece(2, Piece.new(Piece.Owner.PLAYER))
	b.drop_piece(3, Piece.new(Piece.Owner.AI))
	b.drop_piece(3, Piece.new(Piece.Owner.AI))
	b.drop_piece(3, Piece.new(Piece.Owner.AI))
	b.drop_piece(3, Piece.new(Piece.Owner.PLAYER))
	var runs := b.detect_clears()
	var found := false
	for run in runs:
		if run.owner == Piece.Owner.PLAYER and run.cells.size() >= 4:
			found = true
	_assert("diagonal ascending 4-in-a-row detected", found)


func test_detect_diagonal_descending_clear() -> void:
	var b := _make_board()
	# col 0: 4 fillers then player, col 1: 3 fillers then player, etc.
	# Descending: (0,3),(1,2),(2,1),(3,0)
	for _i in 3:
		b.drop_piece(0, Piece.new(Piece.Owner.AI))
	b.drop_piece(0, Piece.new(Piece.Owner.PLAYER))
	for _i in 2:
		b.drop_piece(1, Piece.new(Piece.Owner.AI))
	b.drop_piece(1, Piece.new(Piece.Owner.PLAYER))
	b.drop_piece(2, Piece.new(Piece.Owner.AI))
	b.drop_piece(2, Piece.new(Piece.Owner.PLAYER))
	b.drop_piece(3, Piece.new(Piece.Owner.PLAYER))
	var runs := b.detect_clears()
	var found := false
	for run in runs:
		if run.owner == Piece.Owner.PLAYER and run.cells.size() >= 4:
			found = true
	_assert("diagonal descending 4-in-a-row detected", found)


func test_run_of_five_returns_all_five() -> void:
	var b := _make_board()
	for c in 5:
		b.drop_piece(c, Piece.new(Piece.Owner.PLAYER))
	var runs := b.detect_clears()
	var has_five := false
	for run in runs:
		if run.cells.size() == 5:
			has_five = true
	_assert("run of 5 returns exactly 5 cells", has_five)


func test_intersection_cell_appears_in_both_runs() -> void:
	var b := _make_board()
	# Vertical 4 in col 2, rows 0-3.
	for _i in 4:
		b.drop_piece(2, Piece.new(Piece.Owner.PLAYER))
	# Horizontal 4 in row 0, cols 0-3 (col 2 row 0 is the intersection).
	b.drop_piece(0, Piece.new(Piece.Owner.PLAYER))
	b.drop_piece(1, Piece.new(Piece.Owner.PLAYER))
	b.drop_piece(3, Piece.new(Piece.Owner.PLAYER))
	var runs := b.detect_clears()
	var intersection := Vector2i(2, 0)
	var count := 0
	for run in runs:
		for cell in run.cells:
			if cell == intersection:
				count += 1
	_assert("intersection cell (2,0) appears in multiple runs", count >= 2)


func test_intersection_cell_removed_once() -> void:
	var b := _make_board()
	for _i in 4:
		b.drop_piece(2, Piece.new(Piece.Owner.PLAYER))
	b.drop_piece(0, Piece.new(Piece.Owner.PLAYER))
	b.drop_piece(1, Piece.new(Piece.Owner.PLAYER))
	b.drop_piece(3, Piece.new(Piece.Owner.PLAYER))
	var runs := b.detect_clears()
	b.remove_clears(runs)
	_assert("intersection cell removed once (not double-removed)", b.get_cell(2, 0) == null)


func test_mixed_owner_no_clear() -> void:
	var b := _make_board()
	b.drop_piece(0, Piece.new(Piece.Owner.PLAYER))
	b.drop_piece(1, Piece.new(Piece.Owner.AI))
	b.drop_piece(2, Piece.new(Piece.Owner.PLAYER))
	b.drop_piece(3, Piece.new(Piece.Owner.AI))
	var runs := b.detect_clears()
	_assert("mixed-owner row produces no clear", runs.size() == 0)


func test_empty_board_no_clears() -> void:
	var b := _make_board()
	var runs := b.detect_clears()
	_assert("empty board reports no clears", runs.size() == 0)


func test_landing_row_stacks_above_highest_piece() -> void:
	var b := _make_board()
	b.drop_piece(2, Piece.new(Piece.Owner.PLAYER))
	b.drop_piece(2, Piece.new(Piece.Owner.PLAYER))
	_assert("landing row stacks on top of column", b.get_landing_row(2) == 2)


func test_landing_row_ignores_internal_gap() -> void:
	var b := _make_board()
	b.set_cell(1, 0, Piece.new(Piece.Owner.PLAYER))
	b.set_cell(1, 2, Piece.new(Piece.Owner.PLAYER))
	_assert("internal gap does not steal landing row", b.get_landing_row(1) == 3)
	_assert("drop ignores internal gap", b.drop_piece(1, Piece.new(Piece.Owner.AI)) == 3)
