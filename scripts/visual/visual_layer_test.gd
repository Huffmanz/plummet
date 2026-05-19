extends Node

var _passed: int = 0
var _failed: int = 0

const MODIFIER_NAMES: Array[String] = [
	"Echo", "Magnet", "Heavy", "Anchor", "Catalyst", "Volatile", "Double Drop"
]


func _ready() -> void:
	test_render_state_has_84_cells()
	test_render_state_cells_start_empty()
	test_render_state_get_cell_correct()
	test_render_state_queue_has_two_pieces()
	test_render_state_landing_rows_initialized()
	test_jam_theme_player_color_distinct_from_ai()
	test_jam_theme_all_modifier_abbrevs_are_two_chars()
	test_jam_theme_modifier_colors_all_defined()
	test_jam_theme_piece_types_have_distinct_border_styles()
	test_board_renderer_col_from_position_inside_board()
	test_board_renderer_col_from_position_outside_board()
	test_board_renderer_is_col_valid_unfrozen_open()
	test_board_renderer_is_col_valid_frozen_column()
	test_board_renderer_is_col_valid_full_column()
	test_layout_manager_desktop_mode()
	test_layout_manager_too_small()
	test_layout_manager_cell_size_clamped()
	test_cell_state_defaults_empty()
	test_queue_entry_defaults_normal()
	test_frozen_column_stores_col_and_turns()
	test_render_state_builder_maps_84_cells()
	test_render_state_builder_maps_player_pieces()
	test_render_state_builder_maps_frozen_columns()
	test_render_state_builder_maps_locked_cells()
	test_render_state_builder_maps_scores()
	test_render_state_builder_maps_landing_rows()
	print("-----------------------------")
	print("Results: %d passed, %d failed" % [_passed, _failed])


func _assert(label: String, condition: bool) -> void:
	if condition:
		print("[PASS] %s" % label)
		_passed += 1
	else:
		print("[FAIL] %s" % label)
		_failed += 1


func _make_renderer() -> BoardRenderer:
	var r := BoardRenderer.new(ThemeCozy.new())
	var layout := LayoutManager.new().compute(Vector2(1280.0, 720.0))
	r.layout = layout
	return r


func _make_full_state_for_col(col: int) -> RenderState:
	var rs := RenderState.make_empty()
	for r in RenderState.ROWS:
		rs.get_cell(col, r).occupant = CellState.Occupant.PLAYER
	rs.landing_rows[col] = -1
	return rs


# --- RenderState ---

func test_render_state_has_84_cells() -> void:
	var rs := RenderState.make_empty()
	_assert("RenderState has 84 cells (7×12)", rs.cells.size() == 84)


func test_render_state_cells_start_empty() -> void:
	var rs := RenderState.make_empty()
	var all_empty := true
	for cs in rs.cells:
		if cs.occupant != CellState.Occupant.EMPTY:
			all_empty = false
	_assert("All 84 cells start empty", all_empty)


func test_render_state_get_cell_correct() -> void:
	var rs := RenderState.make_empty()
	var cs := rs.get_cell(3, 5)
	_assert("get_cell(3,5) returns col=3", cs.col == 3)
	_assert("get_cell(3,5) returns row=5", cs.row == 5)


func test_render_state_queue_has_two_pieces() -> void:
	var rs := RenderState.make_empty()
	_assert("player_queue has 2 entries", rs.player_queue.size() == 2)


func test_render_state_landing_rows_initialized() -> void:
	var rs := RenderState.make_empty()
	_assert("landing_rows has 7 entries", rs.landing_rows.size() == RenderState.COLS)


# --- ThemeCozy ---

func test_cozy_theme_player_color_distinct_from_ai() -> void:
	var t := ThemeCozy.new()
	_assert("Player and AI colors are distinct", t.color_player != t.color_ai)


func test_cozy_theme_all_modifier_abbrevs_are_two_chars() -> void:
	var t := ThemeCozy.new()
	var all_ok := true
	for name in MODIFIER_NAMES:
		if t.get_modifier_abbrev(name).length() != 2:
			all_ok = false
	_assert("All modifier abbreviations are 2 characters", all_ok)


func test_cozy_theme_modifier_colors_all_defined() -> void:
	var t := ThemeCozy.new()
	var all_defined := true
	for name in MODIFIER_NAMES:
		if not ThemeCozy.MODIFIER_DATA.has(name):
			all_defined = false
	_assert("All modifiers have entries in MODIFIER_DATA", all_defined)


func test_cozy_theme_piece_types_have_distinct_border_styles() -> void:
	var t := ThemeCozy.new()
	var styles: Array[int] = []
	for pt in [CellState.PieceType.NORMAL, CellState.PieceType.WEIGHTED,
			CellState.PieceType.GHOST, CellState.PieceType.VOLATILE]:
		var s := t.get_piece_border_style(pt)
		if s in styles:
			_assert("All 4 piece types have distinct border styles", false)
			return
		styles.append(s)
	_assert("All 4 piece types have distinct border styles", true)


# --- BoardRenderer ---

func test_board_renderer_col_from_position_inside_board() -> void:
	var r := _make_renderer()
	var board_left: float = r.layout.board_origin.x
	var step: float = r.layout.cell_size + LayoutManager.CELL_GAP
	var x := board_left + step * 3.0 + r.layout.cell_size * 0.5
	_assert("col_from_position returns col 3 for center of col 3", r.col_from_position(x) == 3)


func test_board_renderer_col_from_position_outside_board() -> void:
	var r := _make_renderer()
	_assert("col_from_position returns -1 for x=0 (left of board)", r.col_from_position(0.0) == -1)


func test_board_renderer_is_col_valid_unfrozen_open() -> void:
	var r := _make_renderer()
	var rs := RenderState.make_empty()
	_assert("Open unfrozen column is valid", r.is_col_valid(rs, 3))


func test_board_renderer_is_col_valid_frozen_column() -> void:
	var r := _make_renderer()
	var rs := RenderState.make_empty()
	rs.frozen_columns.append(FrozenColumn.new(3, 2))
	_assert("Frozen column 3 is invalid", not r.is_col_valid(rs, 3))


func test_board_renderer_is_col_valid_full_column() -> void:
	var r := _make_renderer()
	var rs := _make_full_state_for_col(4)
	_assert("Full column 4 is invalid (landing_row -1)", not r.is_col_valid(rs, 4))


# --- LayoutManager ---

func test_layout_manager_desktop_mode() -> void:
	var lm := LayoutManager.new()
	var result := lm.compute(Vector2(1280.0, 720.0))
	_assert("1280×720 → DESKTOP mode", result.mode == LayoutManager.LayoutMode.DESKTOP)


func test_layout_manager_too_small() -> void:
	var lm := LayoutManager.new()
	var result := lm.compute(Vector2(200.0, 180.0))
	_assert("200×180 → TOO_SMALL mode", result.mode == LayoutManager.LayoutMode.TOO_SMALL)


func test_layout_manager_cell_size_clamped() -> void:
	var lm := LayoutManager.new()
	var result := lm.compute(Vector2(2560.0, 1440.0))
	_assert("Cell size does not exceed 48px on large screen",
		result.cell_size <= LayoutManager.MAX_CELL_SIZE)


# --- CellState / QueueEntry / FrozenColumn ---

func test_cell_state_defaults_empty() -> void:
	var cs := CellState.new()
	_assert("CellState defaults to EMPTY occupant", cs.occupant == CellState.Occupant.EMPTY)
	_assert("CellState defaults to no modifiers", cs.modifiers.is_empty())
	_assert("CellState defaults not locked", not cs.locked)
	_assert("CellState defaults not frozen", not cs.frozen)


func test_queue_entry_defaults_normal() -> void:
	var qe := QueueEntry.new()
	_assert("QueueEntry defaults to NORMAL piece type", qe.piece_type == CellState.PieceType.NORMAL)
	_assert("QueueEntry defaults to no modifiers", qe.modifiers.is_empty())


func test_frozen_column_stores_col_and_turns() -> void:
	var fc := FrozenColumn.new(5, 3)
	_assert("FrozenColumn stores col", fc.col == 5)
	_assert("FrozenColumn stores turns_remaining", fc.turns_remaining == 3)


# --- RenderStateBuilder ---

func test_render_state_builder_maps_84_cells() -> void:
	var b := BoardEngine.new()
	var st := ScoreTracker.new()
	var tm := TurnManager.new()
	tm.start()
	var builder := RenderStateBuilder.new()
	var rs := builder.build(b, st, tm, [], [], [], false, 1, 1, "", "", 0, false)
	_assert("Builder produces 84 cells from empty board", rs.cells.size() == 84)


func test_render_state_builder_maps_player_pieces() -> void:
	var b := BoardEngine.new()
	b.drop_piece(0, Piece.new(Piece.Owner.PLAYER))
	b.drop_piece(1, Piece.new(Piece.Owner.AI))
	var st := ScoreTracker.new()
	var tm := TurnManager.new()
	tm.start()
	var builder := RenderStateBuilder.new()
	var rs := builder.build(b, st, tm, [], [], [], false, 1, 1, "", "", 0, false)
	_assert("Builder maps PLAYER piece at (0,0)", rs.get_cell(0, 0).occupant == CellState.Occupant.PLAYER)
	_assert("Builder maps AI piece at (1,0)", rs.get_cell(1, 0).occupant == CellState.Occupant.AI)
	_assert("Builder leaves (2,0) empty", rs.get_cell(2, 0).occupant == CellState.Occupant.EMPTY)


func test_render_state_builder_maps_frozen_columns() -> void:
	var b := BoardEngine.new()
	var st := ScoreTracker.new()
	var tm := TurnManager.new()
	tm.start()
	var fc_data := [FrozenColumn.new(3, 2)]
	var builder := RenderStateBuilder.new()
	var rs := builder.build(b, st, tm, [], fc_data, [], false, 1, 1, "", "", 0, false)
	_assert("Builder maps frozen column 3", rs.frozen_columns.size() == 1)
	_assert("Frozen column index is 3", rs.frozen_columns[0].col == 3)
	_assert("Frozen column turns is 2", rs.frozen_columns[0].turns_remaining == 2)


func test_render_state_builder_maps_locked_cells() -> void:
	var b := BoardEngine.new()
	var st := ScoreTracker.new()
	var tm := TurnManager.new()
	tm.start()
	var locked: Array[Vector2i] = [Vector2i(2, 0)]
	var builder := RenderStateBuilder.new()
	var rs := builder.build(b, st, tm, [], [], locked, false, 1, 1, "", "", 0, false)
	_assert("Builder marks (2,0) as locked", rs.get_cell(2, 0).locked)
	_assert("Builder does not mark (3,0) as locked", not rs.get_cell(3, 0).locked)


func test_render_state_builder_maps_scores() -> void:
	var b := BoardEngine.new()
	var st := ScoreTracker.new()
	var turn_score := TurnScore.new()
	turn_score.player_points = 100
	turn_score.ai_points = 50
	st.add_turn(turn_score)
	var tm := TurnManager.new()
	tm.start()
	var builder := RenderStateBuilder.new()
	var rs := builder.build(b, st, tm, [], [], [], false, 1, 1, "", "", 0, false)
	_assert("Builder maps player_score=100", rs.player_score == 100)
	_assert("Builder maps ai_score=50", rs.ai_score == 50)


func test_render_state_builder_maps_landing_rows() -> void:
	var b := BoardEngine.new()
	b.drop_piece(0, Piece.new(Piece.Owner.PLAYER))
	b.drop_piece(0, Piece.new(Piece.Owner.PLAYER))
	var st := ScoreTracker.new()
	var tm := TurnManager.new()
	tm.start()
	var builder := RenderStateBuilder.new()
	var rs := builder.build(b, st, tm, [], [], [], false, 1, 1, "", "", 0, false)
	_assert("Landing row for col 0 with 2 pieces is row 2", rs.landing_rows[0] == 2)
	_assert("Landing row for empty col 1 is row 0", rs.landing_rows[1] == 0)
