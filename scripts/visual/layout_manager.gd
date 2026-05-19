class_name LayoutManager extends RefCounted

const MIN_CELL_SIZE: float = 16.0
const MAX_CELL_SIZE: float = 32.0
const CELL_GAP: float = 0.0
const PANEL_WIDTH: float = 160.0
const BOTTOM_STRIP_HEIGHT: float = 8.0
const DESKTOP_MIN_WIDTH: float = 700.0

enum LayoutMode { DESKTOP, MOBILE, TOO_SMALL }


class LayoutResult extends RefCounted:
	var mode: LayoutManager.LayoutMode = LayoutManager.LayoutMode.DESKTOP
	var cell_size: float = MAX_CELL_SIZE
	var board_origin: Vector2 = Vector2.ZERO
	var panel_width: float = PANEL_WIDTH
	var bottom_height: float = BOTTOM_STRIP_HEIGHT
	var viewport_size: Vector2 = Vector2.ZERO


func compute(viewport_size: Vector2) -> LayoutResult:
	var result := LayoutResult.new()
	result.viewport_size = viewport_size
	result.panel_width = PANEL_WIDTH
	result.bottom_height = BOTTOM_STRIP_HEIGHT

	var is_desktop: bool = viewport_size.x >= DESKTOP_MIN_WIDTH
	var available_w: float = viewport_size.x - (PANEL_WIDTH * 2.0 if is_desktop else 0.0)
	var available_h: float = viewport_size.y - BOTTOM_STRIP_HEIGHT

	var cols: int = RenderState.COLS
	var rows: int = RenderState.ROWS
	var cell_from_w: float = (available_w - (cols - 1) * CELL_GAP) / float(cols)
	var cell_from_h: float = (available_h - (rows - 1) * CELL_GAP) / float(rows)
	var raw_cell: float = minf(cell_from_w, cell_from_h)

	if raw_cell < MIN_CELL_SIZE:
		result.mode = LayoutMode.TOO_SMALL
		result.cell_size = MIN_CELL_SIZE
	else:
		result.mode = LayoutMode.DESKTOP if is_desktop else LayoutMode.MOBILE
		result.cell_size = minf(raw_cell, MAX_CELL_SIZE)

	var board_w: float = cols * result.cell_size + (cols - 1) * CELL_GAP
	var board_h: float = rows * result.cell_size + (rows - 1) * CELL_GAP

	if is_desktop:
		result.board_origin = Vector2(
			PANEL_WIDTH + (available_w - board_w) / 2.0,
			(available_h - board_h) / 2.0
		)
	else:
		result.board_origin = Vector2(
			(viewport_size.x - board_w) / 2.0,
			(available_h - board_h) / 2.0
		)

	return result
