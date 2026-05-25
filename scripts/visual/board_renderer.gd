class_name BoardRenderer extends RefCounted

var theme: ThemeBase
var layout: LayoutManager.LayoutResult
var hovered_col: int = -1
var gravity_hidden_cells: Array[Vector2i] = []
var dissolve_hidden_cells: Array[Vector2i] = []
var idle_breathe_scale: float = 1.0
var cascade_heat: float = 0.0


func _init(p_theme: ThemeBase) -> void:
	theme = p_theme


func render_board(state: RenderState, canvas: CanvasItem) -> void:
	render_board_under(state, canvas)
	render_board_tiles(state, canvas)
	_render_frozen_columns(state, canvas)


func render_board_under(state: RenderState, canvas: CanvasItem) -> void:
	if state == null or layout == null or theme == null:
		return
	var board_rect := _board_rect()
	var glow_color := theme.color_player if state.active_player == CellState.Occupant.PLAYER else theme.color_ai
	canvas.draw_rect(board_rect.grow(8.0), Color(glow_color.r, glow_color.g, glow_color.b, 0.06), false, 2.0)
	canvas.draw_rect(board_rect.grow(5.0), Color(glow_color.r, glow_color.g, glow_color.b, 0.12), false, 2.0)
	var heat_bg := theme.color_bg.lerp(UITheme.BOARD_HEAT, cascade_heat)
	var tray := board_rect.grow(4.0)
	canvas.draw_rect(tray, heat_bg)
	canvas.draw_rect(tray, UITheme.SURFACE_BORDER_MUTED, false, 3.0)
	for c in RenderState.COLS:
		for r in RenderState.ROWS:
			var cs: CellState = state.get_cell(c, r)
			if gravity_hidden_cells.has(Vector2i(c, r)) or dissolve_hidden_cells.has(Vector2i(c, r)) or cs.locked:
				continue
			var rect := cell_rect(c, r, state.gravity_flipped)
			if cs.occupant == CellState.Occupant.PLAYER:
				theme.draw_player_piece(canvas, rect, cs.piece_type)
			elif cs.occupant == CellState.Occupant.AI:
				theme.draw_ai_piece(canvas, rect, cs.piece_type)


func render_board_tiles(state: RenderState, canvas: CanvasItem) -> void:
	if state == null or layout == null or theme == null:
		return
	for c in RenderState.COLS:
		for r in RenderState.ROWS:
			var cs: CellState = state.get_cell(c, r)
			var rect := cell_rect(c, r, state.gravity_flipped)
			if gravity_hidden_cells.has(Vector2i(c, r)) or dissolve_hidden_cells.has(Vector2i(c, r)):
				continue
			if cs.locked:
				theme.draw_locked_cell(canvas, rect)
				continue
			if cs.occupant == CellState.Occupant.EMPTY:
				theme.draw_empty_cell(canvas, rect)
			if cs.frozen:
				theme.draw_frozen_cell(canvas, rect)
			if not cs.modifier.is_empty():
				theme.draw_modifier_badge(canvas, rect, cs.modifier)
	var t_ms := Time.get_ticks_msec() * 0.006
	for c in RenderState.COLS:
		var lr := state.landing_rows[c] if c < state.landing_rows.size() else -1
		var near_full := false
		if lr >= 0:
			if state.gravity_flipped:
				near_full = lr <= 1
			else:
				near_full = lr >= RenderState.ROWS - 2
		if near_full:
			var pulse := 0.5 + 0.5 * sin(t_ms)
			var at_limit := lr <= 0 if state.gravity_flipped else lr >= RenderState.ROWS - 1
			var base_alpha := 0.35 if at_limit else 0.18
			canvas.draw_rect(_column_rect(c), Color(UITheme.DANGER.r, UITheme.DANGER.g, UITheme.DANGER.b, base_alpha * pulse))


func _render_frozen_columns(state: RenderState, canvas: CanvasItem) -> void:
	if state == null or layout == null or theme == null:
		return
	for fc in state.frozen_columns:
		theme.draw_frozen_overlay(canvas, _column_rect(fc.col), fc.turns_remaining)


func render_ghost(state: RenderState, canvas: CanvasItem) -> void:
	if state == null or layout == null or theme == null:
		return
	if state.active_player != CellState.Occupant.PLAYER:
		return
	if state.input_locked:
		return
	if not is_col_valid(state, hovered_col):
		return
	var landing_row: int = state.landing_rows[hovered_col]
	if landing_row < 0:
		return
	# Column hover highlight — subtle vertical strip
	var col_rect := _column_rect(hovered_col)
	canvas.draw_rect(col_rect, Color(UITheme.ACCENT.r, UITheme.ACCENT.g, UITheme.ACCENT.b, 0.14))
	var ghost_rect := cell_rect(hovered_col, landing_row, state.gravity_flipped)
	var entry: QueueEntry = state.active_piece
	theme.draw_ghost_piece(canvas, ghost_rect, entry.piece_type, entry.modifier)


func render_queue(state: RenderState, canvas: CanvasItem, origin: Vector2) -> void:
	if state == null or layout == null or theme == null:
		return
	var cs: float = layout.cell_size
	var gap: float = LayoutManager.CELL_GAP
	for i in state.player_queue.size():
		var rect := Rect2(origin.x, origin.y + i * (cs + gap), cs, cs)
		theme.draw_queue_entry(canvas, rect, state.player_queue[i])


func cell_rect(col: int, row: int, gravity_flipped: bool = false) -> Rect2:
	var step: float = layout.cell_size + LayoutManager.CELL_GAP
	var display_row: int = row if gravity_flipped else (RenderState.ROWS - 1 - row)
	return Rect2(
		layout.board_origin.x + col * step,
		layout.board_origin.y + display_row * step,
		layout.cell_size,
		layout.cell_size
	)


func col_from_position(x: float) -> int:
	if layout == null:
		return -1
	var step: float = layout.cell_size + LayoutManager.CELL_GAP
	var board_left: float = layout.board_origin.x
	var board_right: float = board_left + RenderState.COLS * layout.cell_size + \
		(RenderState.COLS - 1) * LayoutManager.CELL_GAP
	if x < board_left or x >= board_right:
		return -1
	return clamp(int((x - board_left) / step), 0, RenderState.COLS - 1)


func cell_from_position(pos: Vector2, gravity_flipped: bool = false) -> Vector2i:
	var col := col_from_position(pos.x)
	if col < 0 or layout == null:
		return Vector2i(-1, -1)
	var step: float = layout.cell_size + LayoutManager.CELL_GAP
	var board_top: float = layout.board_origin.y
	var board_bottom: float = board_top + RenderState.ROWS * layout.cell_size + \
		(RenderState.ROWS - 1) * LayoutManager.CELL_GAP
	if pos.y < board_top or pos.y >= board_bottom:
		return Vector2i(-1, -1)
	var display_row := clampi(int((pos.y - board_top) / step), 0, RenderState.ROWS - 1)
	var row: int = display_row if gravity_flipped else (RenderState.ROWS - 1 - display_row)
	return Vector2i(col, row)


func is_col_valid(state: RenderState, col: int) -> bool:
	if col < 0 or col >= RenderState.COLS:
		return false
	for fc in state.frozen_columns:
		if fc.col == col:
			return false
	if col >= state.landing_rows.size():
		return false
	return state.landing_rows[col] >= 0


func _board_rect() -> Rect2:
	var w: float = RenderState.COLS * layout.cell_size + (RenderState.COLS - 1) * LayoutManager.CELL_GAP
	var h: float = RenderState.ROWS * layout.cell_size + (RenderState.ROWS - 1) * LayoutManager.CELL_GAP
	return Rect2(layout.board_origin, Vector2(w, h))


func _column_rect(col: int) -> Rect2:
	var board := _board_rect()
	var step: float = layout.cell_size + LayoutManager.CELL_GAP
	return Rect2(board.position.x + col * step, board.position.y, layout.cell_size, board.size.y)
