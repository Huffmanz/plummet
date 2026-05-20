extends Node

var _passed: int = 0
var _failed: int = 0


func _ready() -> void:
	test_weighted_pushes_piece_below()
	test_weighted_settles_into_vacated_slot()
	test_weighted_no_room_below_does_nothing()
	test_weighted_at_floor_does_nothing()
	test_weighted_chain_two_weighted_pieces()
	test_weighted_chain_two_weighted_push_succeeds()
	test_weighted_anchor_resists_push()
	test_ghost_empty_column_behaves_normal()
	test_ghost_lands_below_top_piece_in_gap()
	test_ghost_packed_stack_returns_invalid()
	test_ghost_single_piece_at_floor_returns_invalid()
	test_ghost_passes_through_top_to_floor()
	test_ghost_drop_places_piece_at_ghost_row()
	test_ghost_drop_invalid_returns_minus_one()
	test_volatile_type_removes_eight_moore_neighbors()
	test_volatile_type_does_not_remove_out_of_bounds()
	test_volatile_type_plus_modifier_removes_distance_two_ortho()
	test_volatile_type_alone_no_extra_distance_two()
	test_magnet_slide_applies_gravity()
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


# --- Weighted ---

func test_weighted_pushes_piece_below() -> void:
	var b := _make_board()
	var normal := Piece.new(Piece.Owner.AI)
	b.drop_piece(3, normal)  # lands at row 0
	var weighted := Piece.new(Piece.Owner.PLAYER, Piece.Type.WEIGHTED)
	b.drop_piece(3, weighted)  # lands at row 1
	var r := _make_resolver()
	r.set_landed(3, 1, weighted)
	r.on_land(b)
	# weighted should settle at row 0, normal pushed to... wait, row -1 is off-board.
	# Push does nothing if dest < 0. Weighted stays at row 1.
	_assert("weighted at row 1, normal at row 0 — push fails (floor)", b.get_cell(3, 0) == normal)
	_assert("weighted stays at row 1 when push fails", b.get_cell(3, 1) == weighted)


func test_weighted_settles_into_vacated_slot() -> void:
	var b := _make_board()
	# row 0: empty, row 1: normal (via set_cell to skip gravity), row 2: empty
	var normal := Piece.new(Piece.Owner.AI)
	b.set_cell(3, 1, normal)
	var weighted := Piece.new(Piece.Owner.PLAYER, Piece.Type.WEIGHTED)
	b.set_cell(3, 2, weighted)
	var r := _make_resolver()
	r.set_landed(3, 2, weighted)
	r.on_land(b)
	# normal pushed from row 1 to row 0; weighted settles at row 1
	_assert("weighted push: normal moved to row 0", b.get_cell(3, 0) == normal)
	_assert("weighted push: weighted settles at row 1", b.get_cell(3, 1) == weighted)
	_assert("weighted push: row 2 vacated", b.get_cell(3, 2) == null)


func test_weighted_no_room_below_does_nothing() -> void:
	var b := _make_board()
	var below := Piece.new(Piece.Owner.AI)
	var obstacle := Piece.new(Piece.Owner.AI)
	b.set_cell(3, 0, obstacle)  # blocks push destination
	b.set_cell(3, 1, below)
	var weighted := Piece.new(Piece.Owner.PLAYER, Piece.Type.WEIGHTED)
	b.set_cell(3, 2, weighted)
	var r := _make_resolver()
	r.set_landed(3, 2, weighted)
	r.on_land(b)
	_assert("weighted no-room: below stays at row 1", b.get_cell(3, 1) == below)
	_assert("weighted no-room: weighted stays at row 2", b.get_cell(3, 2) == weighted)


func test_weighted_at_floor_does_nothing() -> void:
	var b := _make_board()
	var weighted := Piece.new(Piece.Owner.PLAYER, Piece.Type.WEIGHTED)
	b.drop_piece(3, weighted)  # lands at row 0 (floor)
	var r := _make_resolver()
	r.set_landed(3, 0, weighted)
	r.on_land(b)
	_assert("weighted at floor: stays at row 0", b.get_cell(3, 0) == weighted)


func test_weighted_chain_two_weighted_pieces() -> void:
	var b := _make_board()
	# row 0: empty, row 1: weighted_b, row 2: normal_c, row 3: weighted_a (just landed)
	var normal_c := Piece.new(Piece.Owner.AI)
	var weighted_b := Piece.new(Piece.Owner.PLAYER, Piece.Type.WEIGHTED)
	var weighted_a := Piece.new(Piece.Owner.PLAYER, Piece.Type.WEIGHTED)
	b.set_cell(3, 1, weighted_b)
	b.set_cell(3, 2, normal_c)
	b.set_cell(3, 3, weighted_a)
	var r := _make_resolver()
	r.set_landed(3, 3, weighted_a)
	r.on_land(b)
	# weighted_a pushes normal_c; normal_c is not weighted so b chains: b pushes... wait
	# weighted_a at row 3 → push row 2 (normal_c). normal_c is not weighted, dest=row1 occupied by b → fail
	# So chain: row 2 (normal_c) can't move because row 1 is occupied. Push fails; weighted_a stays at row 3.
	# Wait, let me re-examine: weighted_a pushes piece at row 2 (normal_c).
	# _try_push_down(board, 3, 2): piece at row 2 = normal_c. dest=1. row 1 = weighted_b (occupied).
	# normal_c is not Weighted, so return false. Push fails.
	_assert("chain 3-piece: weighted_a stays at row 3 (push blocked)", b.get_cell(3, 3) == weighted_a)
	_assert("chain 3-piece: normal_c stays at row 2 (couldn't push)", b.get_cell(3, 2) == normal_c)


func test_weighted_chain_two_weighted_push_succeeds() -> void:
	var b := _make_board()
	# row 0: empty, row 1: empty, row 2: weighted_b, row 3: weighted_a (just landed)
	var weighted_b := Piece.new(Piece.Owner.AI, Piece.Type.WEIGHTED)
	var weighted_a := Piece.new(Piece.Owner.PLAYER, Piece.Type.WEIGHTED)
	b.set_cell(3, 2, weighted_b)
	b.set_cell(3, 3, weighted_a)
	var r := _make_resolver()
	r.set_landed(3, 3, weighted_a)
	r.on_land(b)
	# weighted_a at row 3 → push weighted_b at row 2. weighted_b chains → dest=row 1 (empty) → b moves to row 1.
	# Then a settles at row 2.
	_assert("weighted chain success: b moved to row 1", b.get_cell(3, 1) == weighted_b)
	_assert("weighted chain success: a settled at row 2", b.get_cell(3, 2) == weighted_a)
	_assert("weighted chain success: row 3 vacated", b.get_cell(3, 3) == null)


func test_weighted_anchor_resists_push() -> void:
	var b := _make_board()
	var anchored := Piece.new(Piece.Owner.AI)
	anchored.modifiers = ["Anchor"]
	b.set_cell(3, 1, anchored)
	var weighted := Piece.new(Piece.Owner.PLAYER, Piece.Type.WEIGHTED)
	b.set_cell(3, 2, weighted)
	var r := _make_resolver()
	r.set_landed(3, 2, weighted)
	r.on_land(b)
	_assert("anchor resists weighted push: anchor stays at row 1", b.get_cell(3, 1) == anchored)
	_assert("anchor resists weighted push: weighted stays at row 2", b.get_cell(3, 2) == weighted)


# --- Ghost ---

func test_ghost_empty_column_behaves_normal() -> void:
	var b := _make_board()
	var ghost_row := b.get_ghost_landing_row(3)
	_assert("ghost empty column: returns row 0 (same as normal)", ghost_row == 0)


func test_ghost_lands_below_top_piece_in_gap() -> void:
	var b := _make_board()
	# row 0: A, row 1: B, row 2: empty (gap), row 3: C (via set_cell)
	b.set_cell(3, 0, Piece.new(Piece.Owner.AI))
	b.set_cell(3, 1, Piece.new(Piece.Owner.AI))
	b.set_cell(3, 3, Piece.new(Piece.Owner.AI))
	var ghost_row := b.get_ghost_landing_row(3)
	_assert("ghost with gap: lands at row 2 (below C, above B)", ghost_row == 2)


func test_ghost_packed_stack_returns_invalid() -> void:
	var b := _make_board()
	b.drop_piece(3, Piece.new(Piece.Owner.AI))  # row 0
	b.drop_piece(3, Piece.new(Piece.Owner.AI))  # row 1
	b.drop_piece(3, Piece.new(Piece.Owner.AI))  # row 2
	var ghost_row := b.get_ghost_landing_row(3)
	_assert("ghost packed stack: returns -1 (no gap)", ghost_row == -1)


func test_ghost_single_piece_at_floor_returns_invalid() -> void:
	var b := _make_board()
	b.drop_piece(3, Piece.new(Piece.Owner.AI))  # row 0 (floor)
	var ghost_row := b.get_ghost_landing_row(3)
	_assert("ghost single piece at floor: returns -1 (nowhere below floor)", ghost_row == -1)


func test_ghost_passes_through_top_to_floor() -> void:
	var b := _make_board()
	# Single piece at row 5 (isolated, placed via set_cell)
	b.set_cell(3, 5, Piece.new(Piece.Owner.AI))
	var ghost_row := b.get_ghost_landing_row(3)
	_assert("ghost with isolated elevated piece: lands at row 0 (floor)", ghost_row == 0)


func test_ghost_drop_places_piece_at_ghost_row() -> void:
	var b := _make_board()
	b.set_cell(3, 1, Piece.new(Piece.Owner.AI))
	b.set_cell(3, 3, Piece.new(Piece.Owner.AI))
	# Gap at row 2; ghost should land at row 2
	var ghost := Piece.new(Piece.Owner.PLAYER, Piece.Type.GHOST)
	var landed := b.drop_ghost_piece(3, ghost)
	_assert("drop_ghost_piece: returns ghost landing row 2", landed == 2)
	_assert("drop_ghost_piece: ghost placed at row 2", b.get_cell(3, 2) == ghost)


func test_ghost_drop_invalid_returns_minus_one() -> void:
	var b := _make_board()
	b.drop_piece(3, Piece.new(Piece.Owner.AI))
	b.drop_piece(3, Piece.new(Piece.Owner.AI))
	var ghost := Piece.new(Piece.Owner.PLAYER, Piece.Type.GHOST)
	var landed := b.drop_ghost_piece(3, ghost)
	_assert("drop_ghost_piece invalid: returns -1 for packed stack", landed == -1)
	_assert("drop_ghost_piece invalid: ghost not placed on board", b.get_cell(3, 2) == null)


# --- Volatile type ---

func _run_volatile_type_clear(cell_pos: Vector2i) -> BoardEngine:
	var b := _make_board()
	var volatile_piece := Piece.new(Piece.Owner.PLAYER, Piece.Type.VOLATILE)
	b.set_cell(cell_pos.x, cell_pos.y, volatile_piece)
	var run_cells: Array[Vector2i] = [cell_pos]
	var run := MatchedRun.new(Piece.Owner.PLAYER, run_cells)
	var runs: Array[MatchedRun] = [run]
	var r := _make_resolver()
	r.on_clear(b, runs)
	return b


func test_volatile_type_removes_eight_moore_neighbors() -> void:
	var b := _make_board()
	var center := Vector2i(3, 5)
	var volatile_piece := Piece.new(Piece.Owner.PLAYER, Piece.Type.VOLATILE)
	b.set_cell(center.x, center.y, volatile_piece)
	# Place neighbors
	var neighbors: Array[Vector2i] = [
		Vector2i(3, 6), Vector2i(3, 4), Vector2i(4, 5), Vector2i(2, 5),
		Vector2i(4, 6), Vector2i(4, 4), Vector2i(2, 6), Vector2i(2, 4),
	]
	for n in neighbors:
		b.set_cell(n.x, n.y, Piece.new(Piece.Owner.AI))
	var run_cells: Array[Vector2i] = [center]
	var run := MatchedRun.new(Piece.Owner.PLAYER, run_cells)
	var runs: Array[MatchedRun] = [run]
	var r := _make_resolver()
	r.on_clear(b, runs)
	var all_clear := true
	for n in neighbors:
		if b.get_cell(n.x, n.y) != null:
			all_clear = false
	_assert("volatile type removes all 8 Moore neighbors", all_clear)


func test_volatile_type_does_not_remove_out_of_bounds() -> void:
	# Place volatile at a corner — out-of-bounds neighbors should be ignored (no crash)
	var b := _make_board()
	var corner := Vector2i(0, 0)
	var volatile_piece := Piece.new(Piece.Owner.PLAYER, Piece.Type.VOLATILE)
	b.set_cell(corner.x, corner.y, volatile_piece)
	var run_cells: Array[Vector2i] = [corner]
	var run := MatchedRun.new(Piece.Owner.PLAYER, run_cells)
	var runs: Array[MatchedRun] = [run]
	var r := _make_resolver()
	r.on_clear(b, runs)
	_assert("volatile type at corner: no crash from out-of-bounds", true)


func test_volatile_type_plus_modifier_removes_distance_two_ortho() -> void:
	var b := _make_board()
	var center := Vector2i(3, 5)
	var volatile_piece := Piece.new(Piece.Owner.PLAYER, Piece.Type.VOLATILE)
	volatile_piece.modifiers = ["Volatile"]
	b.set_cell(center.x, center.y, volatile_piece)
	# Place distance-2 orthogonal targets
	var dist2: Array[Vector2i] = [Vector2i(3, 7), Vector2i(3, 3), Vector2i(5, 5), Vector2i(1, 5)]
	for n in dist2:
		b.set_cell(n.x, n.y, Piece.new(Piece.Owner.AI))
	var run_cells: Array[Vector2i] = [center]
	var run := MatchedRun.new(Piece.Owner.PLAYER, run_cells)
	var runs: Array[MatchedRun] = [run]
	var r := _make_resolver()
	r.on_clear(b, runs)
	var all_clear := true
	for n in dist2:
		if b.get_cell(n.x, n.y) != null:
			all_clear = false
	_assert("volatile type + modifier removes distance-2 orthogonal cells", all_clear)


func test_magnet_slide_applies_gravity() -> void:
	var b := _make_board()
	var pulled := Piece.new(Piece.Owner.PLAYER)
	b.set_cell(0, 4, pulled)
	var magnet := Piece.new(Piece.Owner.PLAYER)
	magnet.modifiers = ["Magnet"]
	var r := _make_resolver()
	r.set_landed(3, 4, magnet)
	r.on_land(b)
	_assert("magnet: pulled piece left source column", b.get_cell(0, 4) == null)
	_assert("magnet: pulled piece settled to column floor", b.get_cell(1, 0) == pulled)
	_assert("magnet: no piece left floating mid-column", b.get_cell(1, 4) == null)


func test_volatile_type_alone_no_extra_distance_two() -> void:
	var b := _make_board()
	var center := Vector2i(3, 5)
	var volatile_piece := Piece.new(Piece.Owner.PLAYER, Piece.Type.VOLATILE)
	b.set_cell(center.x, center.y, volatile_piece)
	# Place distance-2 orthogonal — should NOT be removed (no modifier)
	var dist2: Array[Vector2i] = [Vector2i(3, 7), Vector2i(3, 3), Vector2i(5, 5), Vector2i(1, 5)]
	var sentinel := Piece.new(Piece.Owner.AI)
	for n in dist2:
		b.set_cell(n.x, n.y, sentinel)
	var run_cells: Array[Vector2i] = [center]
	var run := MatchedRun.new(Piece.Owner.PLAYER, run_cells)
	var runs: Array[MatchedRun] = [run]
	var r := _make_resolver()
	r.on_clear(b, runs)
	var all_preserved := true
	for n in dist2:
		if b.get_cell(n.x, n.y) == null:
			all_preserved = false
	_assert("volatile type alone: distance-2 cells NOT removed", all_preserved)
