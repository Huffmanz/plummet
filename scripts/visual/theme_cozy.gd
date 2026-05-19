class_name ThemeCozy extends ThemeBase

const MODIFIER_DATA: Dictionary = {
	"Echo":         {"abbrev": "EC", "color": Color("#9B6BB8")},
	"Magnet":       {"abbrev": "MG", "color": Color("#5A8FD4")},
	"Heavy":        {"abbrev": "HV", "color": Color("#D4924A")},
	"Anchor":       {"abbrev": "AN", "color": Color("#8A8498")},
	"Catalyst":     {"abbrev": "CT", "color": Color("#D4B84A")},
	"Volatile":     {"abbrev": "VL", "color": Color("#D4736E")},
	"Double Drop":  {"abbrev": "DD", "color": Color("#5A9E62")},
}

var _font: Font


func _init() -> void:
	color_player = UITheme.PLAYER
	color_ai = UITheme.AI
	color_empty = UITheme.CELL_EMPTY
	color_bg = UITheme.BOARD_WELL
	color_locked = UITheme.LOCKED
	color_frozen_overlay = Color(0.55, 0.82, 0.92, 0.22)
	color_ui_bg = UITheme.CANVAS
	color_text_primary = UITheme.TEXT_ON_CANVAS
	color_text_secondary = UITheme.TEXT_MUTED
	cell_gap = 3.0
	_font = ThemeDB.fallback_font


func draw_empty_cell(canvas: CanvasItem, rect: Rect2) -> void:
	canvas.draw_rect(rect, color_empty)
	canvas.draw_rect(rect, UITheme.CELL_BORDER, false, 1.5)


func draw_player_piece(canvas: CanvasItem, rect: Rect2, piece_type: CellState.PieceType) -> void:
	_draw_piece(canvas, rect, color_player, piece_type)


func draw_ai_piece(canvas: CanvasItem, rect: Rect2, piece_type: CellState.PieceType) -> void:
	_draw_piece(canvas, rect, color_ai, piece_type)


func draw_ghost_piece(canvas: CanvasItem, rect: Rect2) -> void:
	var ghost := Color(color_player.r, color_player.g, color_player.b, 0.35)
	_draw_piece(canvas, rect, ghost, CellState.PieceType.NORMAL, true)


func draw_piece(canvas: CanvasItem, rect: Rect2, color: Color) -> void:
	_draw_piece(canvas, rect, color, CellState.PieceType.NORMAL)


func draw_locked_cell(canvas: CanvasItem, rect: Rect2) -> void:
	canvas.draw_rect(rect, color_locked)
	canvas.draw_rect(rect, UITheme.CELL_BORDER, false, 1.5)
	var font_size: int = int(rect.size.x * 0.42)
	var text := "■"
	var text_w: float = _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var pos := rect.get_center() + Vector2(-text_w * 0.5, _font.get_ascent(font_size) * 0.35)
	canvas.draw_string(_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, UITheme.TEXT_MUTED_ON_SURFACE)


func draw_frozen_overlay(canvas: CanvasItem, rect: Rect2, _turns_remaining: int) -> void:
	canvas.draw_rect(rect, color_frozen_overlay)
	var hatch_color := Color(0.75, 0.90, 0.98, 0.30)
	var spacing := 10.0
	var rx := rect.position.x
	var ry := rect.position.y
	var rw := rect.size.x
	var rh := rect.size.y
	var d := rx - rh
	while d <= rx + rw:
		var x1 := d
		var y1 := ry
		var x2 := d + rh
		var y2 := ry + rh
		if x1 < rx:
			var adj := rx - x1
			x1 = rx
			y1 += adj
		if x2 > rx + rw:
			var adj := x2 - (rx + rw)
			x2 = rx + rw
			y2 -= adj
		if y1 < ry + rh and y2 > ry and x1 <= x2:
			canvas.draw_line(Vector2(x1, y1), Vector2(x2, y2), hatch_color, 1.0)
		d += spacing


func draw_modifier_badge(canvas: CanvasItem, rect: Rect2, modifier_name: String, slot: int) -> void:
	var badge_w: float = rect.size.x * 0.40
	var badge_h: float = rect.size.y * 0.28
	var badge_y: float = rect.position.y + rect.size.y - badge_h
	var badge_x: float
	match slot:
		0: badge_x = rect.position.x
		1: badge_x = rect.position.x + (rect.size.x - badge_w) * 0.5
		_: badge_x = rect.position.x + rect.size.x - badge_w
	var badge_rect := Rect2(badge_x, badge_y, badge_w, badge_h)
	var badge_color: Color = get_modifier_color(modifier_name)
	UITheme.draw_rounded_rect(canvas, badge_rect, 3.0, badge_color, Color(0.12, 0.10, 0.16, 0.5), 1.0)
	var abbrev: String = get_modifier_abbrev(modifier_name)
	var font_size: int = int(badge_h * 0.68)
	var ascent: float = _font.get_ascent(font_size)
	canvas.draw_string(
		_font,
		Vector2(badge_rect.position.x + 2.0, badge_rect.position.y + ascent),
		abbrev, HORIZONTAL_ALIGNMENT_LEFT, badge_w, font_size, UITheme.TEXT_ON_SURFACE
	)


func draw_queue_entry(canvas: CanvasItem, rect: Rect2, entry: QueueEntry) -> void:
	_draw_piece(canvas, rect, color_player, entry.piece_type)
	for i in mini(entry.modifiers.size(), 3):
		draw_modifier_badge(canvas, rect, entry.modifiers[i], i)


func get_modifier_abbrev(modifier_name: String) -> String:
	var data: Dictionary = MODIFIER_DATA.get(modifier_name, {})
	return data.get("abbrev", "?")


func get_modifier_color(modifier_name: String) -> Color:
	var data: Dictionary = MODIFIER_DATA.get(modifier_name, {})
	return data.get("color", UITheme.TEXT_MUTED)


func _draw_piece(
	canvas: CanvasItem,
	rect: Rect2,
	color: Color,
	piece_type: CellState.PieceType,
	ghost_outline: bool = false
) -> void:
	var center := rect.get_center()
	var radius: float = minf(rect.size.x, rect.size.y) * 0.38
	var outline := color.darkened(0.32)
	if ghost_outline:
		outline = Color(outline.r, outline.g, outline.b, 0.5)
	canvas.draw_circle(center, radius, color)
	canvas.draw_arc(center, radius, 0.0, TAU, 32, outline, 2.5)

	match piece_type:
		CellState.PieceType.WEIGHTED:
			canvas.draw_arc(
				center + Vector2(0.0, radius * 0.15), radius * 0.72,
				PI * 0.15, PI * 0.85, 16, UITheme.TEXT_ON_SURFACE, 2.0
			)
		CellState.PieceType.GHOST:
			var dash_arc: float = TAU / 14.0
			for i in 8:
				var start_angle: float = i * TAU / 8.0
				canvas.draw_arc(center, radius * 1.02, start_angle, start_angle + dash_arc, 8, outline, 1.5)
		CellState.PieceType.VOLATILE:
			var spike := UITheme.ACCENT_POP
			for i in 4:
				var angle: float = i * TAU / 4.0
				var dir := Vector2(cos(angle), sin(angle))
				canvas.draw_line(
					center + dir * (radius * 0.55),
					center + dir * (radius * 1.05),
					spike, 2.0
				)
