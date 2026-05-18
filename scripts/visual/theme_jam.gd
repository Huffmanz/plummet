class_name ThemeJam extends ThemeBase

const MODIFIER_DATA: Dictionary = {
	"Echo":        {"abbrev": "EC", "color": Color(0.6, 0.2, 0.8)},
	"Magnet":      {"abbrev": "MG", "color": Color(0.2, 0.4, 0.9)},
	"Heavy":       {"abbrev": "HV", "color": Color(0.9, 0.5, 0.1)},
	"Anchor":      {"abbrev": "AN", "color": Color(0.5, 0.5, 0.5)},
	"Catalyst":    {"abbrev": "CT", "color": Color(0.9, 0.8, 0.1)},
	"Double Drop": {"abbrev": "DD", "color": Color(0.2, 0.8, 0.3)},
}

var _font: Font


func _init() -> void:
	color_player = Color(0.6, 0.2, 0.8)
	color_ai = Color(0.1, 0.7, 0.6)
	color_empty = Color(0.3, 0.3, 0.3, 0.5)
	color_bg = Color(0.12, 0.12, 0.15)
	color_locked = Color(0.4, 0.4, 0.4)
	color_frozen_overlay = Color(0.2, 0.5, 0.9, 0.25)
	_font = ThemeDB.fallback_font


func draw_empty_cell(canvas: CanvasItem, rect: Rect2) -> void:
	canvas.draw_rect(rect, color_empty, false, 1.0)


func draw_player_piece(canvas: CanvasItem, rect: Rect2, piece_type: CellState.PieceType) -> void:
	_draw_piece_shape(canvas, rect, color_player, piece_type)


func draw_ai_piece(canvas: CanvasItem, rect: Rect2, piece_type: CellState.PieceType) -> void:
	_draw_piece_shape(canvas, rect, color_ai, piece_type)
	# Small square center dot for accessibility — shape distinguishes AI without relying on color
	var dot_size: float = rect.size.x * 0.15
	var center := rect.get_center()
	canvas.draw_rect(
		Rect2(center - Vector2(dot_size, dot_size) * 0.5, Vector2(dot_size, dot_size) * 1.0),
		Color.WHITE
	)


func draw_ghost_piece(canvas: CanvasItem, rect: Rect2) -> void:
	var center := rect.get_center()
	var radius: float = rect.size.x * 0.42
	canvas.draw_circle(center, radius, Color(color_player.r, color_player.g, color_player.b, 0.35))
	canvas.draw_arc(center, radius, 0.0, TAU, 32,
		Color(color_player.r, color_player.g, color_player.b, 0.70), 1.5)


func draw_locked_cell(canvas: CanvasItem, rect: Rect2) -> void:
	canvas.draw_rect(rect, color_locked)
	var font_size: int = int(rect.size.x * 0.45)
	var text := "■"
	var text_h: float = _font.get_ascent(font_size)
	var text_w: float = _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var pos := rect.get_center() + Vector2(-text_w * 0.5, text_h * 0.35)
	canvas.draw_string(_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size,
		Color(0.75, 0.75, 0.75))


func draw_frozen_overlay(canvas: CanvasItem, rect: Rect2, _turns_remaining: int) -> void:
	canvas.draw_rect(rect, color_frozen_overlay)
	# Frost hatching — diagonal lines at 45°
	var hatch_color := Color(0.65, 0.88, 1.0, 0.28)
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
	var badge_w: float = rect.size.x * 0.38
	var badge_h: float = rect.size.y * 0.26
	var badge_y: float = rect.position.y + rect.size.y - badge_h

	var badge_x: float
	match slot:
		0:
			badge_x = rect.position.x
		1:
			badge_x = rect.position.x + (rect.size.x - badge_w) * 0.5
		_:
			badge_x = rect.position.x + rect.size.x - badge_w

	var badge_rect := Rect2(badge_x, badge_y, badge_w, badge_h)
	var badge_color: Color = get_modifier_color(modifier_name)
	canvas.draw_rect(badge_rect, badge_color)

	var abbrev: String = get_modifier_abbrev(modifier_name)
	var font_size: int = int(badge_h * 0.70)
	var ascent: float = _font.get_ascent(font_size)
	canvas.draw_string(_font, Vector2(badge_rect.position.x + 1.0, badge_rect.position.y + ascent),
		abbrev, HORIZONTAL_ALIGNMENT_LEFT, badge_w, font_size, Color.BLACK)


func draw_queue_entry(canvas: CanvasItem, rect: Rect2, entry: QueueEntry) -> void:
	_draw_piece_shape(canvas, rect, color_player, entry.piece_type)
	for i in mini(entry.modifiers.size(), 3):
		draw_modifier_badge(canvas, rect, entry.modifiers[i], i)


func get_modifier_abbrev(modifier_name: String) -> String:
	var data: Dictionary = MODIFIER_DATA.get(modifier_name, {})
	return data.get("abbrev", "?")


func get_modifier_color(modifier_name: String) -> Color:
	var data: Dictionary = MODIFIER_DATA.get(modifier_name, {})
	return data.get("color", Color(0.5, 0.5, 0.5))


func get_piece_border_style(piece_type: CellState.PieceType) -> int:
	return piece_type


func _draw_piece_shape(
	canvas: CanvasItem,
	rect: Rect2,
	color: Color,
	piece_type: CellState.PieceType
) -> void:
	var center := rect.get_center()
	var radius: float = rect.size.x * 0.42

	match piece_type:
		CellState.PieceType.NORMAL:
			canvas.draw_circle(center, radius, color)

		CellState.PieceType.WEIGHTED:
			canvas.draw_circle(center, radius, color)
			canvas.draw_arc(center, radius, 0.0, TAU, 32, Color.WHITE, 3.0)

		CellState.PieceType.GHOST:
			canvas.draw_circle(center, radius, color.darkened(0.3))
			# Dashed border: 8 short arcs with gaps
			var dash_arc: float = TAU / 16.0
			for i in 8:
				var start_angle: float = i * TAU / 8.0
				canvas.draw_arc(center, radius, start_angle, start_angle + dash_arc, 8, color, 1.5)

		CellState.PieceType.VOLATILE:
			canvas.draw_circle(center, radius, color)
			# Spiky border: 8 short lines radiating outward
			var spike_color := Color(0.95, 0.35, 0.1)
			for i in 8:
				var angle: float = i * TAU / 8.0
				var dir := Vector2(cos(angle), sin(angle))
				canvas.draw_line(
					center + dir * (radius * 0.80),
					center + dir * (radius * 1.20),
					spike_color, 2.0
				)
