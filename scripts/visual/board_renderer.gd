class_name BoardRenderer extends RefCounted

var theme: ThemeBase
var layout: LayoutManager.LayoutResult
var hovered_col: int = -1


func _init(p_theme: ThemeBase) -> void:
	theme = p_theme


func render_board(state: RenderState, canvas: CanvasItem) -> void:
	if state == null or layout == null or theme == null:
		return

	var board_rect := _board_rect()
	canvas.draw_rect(board_rect, theme.color_bg)

	for fc in state.frozen_columns:
		theme.draw_frozen_overlay(canvas, _column_rect(fc.col), fc.turns_remaining)

	for c in RenderState.COLS:
		for r in RenderState.ROWS:
			var cs: CellState = state.get_cell(c, r)
			var rect := cell_rect(c, r, state.gravity_flipped)
			if cs.locked:
				theme.draw_locked_cell(canvas, rect)
			elif cs.occupant == CellState.Occupant.EMPTY:
				theme.draw_empty_cell(canvas, rect)
			else:
				if cs.occupant == CellState.Occupant.PLAYER:
					theme.draw_player_piece(canvas, rect, cs.piece_type)
				else:
					theme.draw_ai_piece(canvas, rect, cs.piece_type)
				for i in mini(cs.modifiers.size(), 3):
					theme.draw_modifier_badge(canvas, rect, cs.modifiers[i], i)


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
	theme.draw_ghost_piece(canvas, cell_rect(hovered_col, landing_row, state.gravity_flipped))


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
