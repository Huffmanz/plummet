class_name ThemeJam extends ThemeBase

const MODIFIER_DATA: Dictionary = {
	"Ignite":   {"initial": "I", "color": Color(0.85, 0.22, 0.15)},
	"Magnet":   {"initial": "M", "color": Color(0.35, 0.56, 0.83)},
	"Deposit":  {"initial": "D", "color": Color(0.85, 0.72, 0.15)},
	"Ripple":   {"initial": "R", "color": Color(0.25, 0.72, 0.68)},
	"Echo":     {"initial": "E", "color": Color(0.6, 0.2, 0.8)},
	"Detonate": {"initial": "X", "color": Color(0.92, 0.45, 0.12)},
	"Bounty":   {"initial": "B", "color": Color(0.32, 0.72, 0.35)},
	"Surge":    {"initial": "Z", "color": Color(0.92, 0.85, 0.12)},
}

const _GRID_TILE_REGION := Rect2(0, 0, 16, 16)
const _PIECE_REGION := Rect2(16, 0, 16, 16)

var _font: Font
var _spritesheet: Texture2D


func _init() -> void:
	color_player = Color("#a146aa")
	color_ai = Color("#339ca3")
	color_empty = Color("#474394")
	color_bg = Color("#322d4d")
	color_locked = Color("#962f2c")
	color_frozen_overlay = Color(0.522, 0.875, 0.922, 0.25)
	_font = ThemeDB.fallback_font
	_spritesheet = load("res://assets/assets.png")


func draw_empty_cell(canvas: CanvasItem, rect: Rect2) -> void:
	canvas.draw_texture_rect_region(_spritesheet, rect, _GRID_TILE_REGION, color_empty)


func draw_player_piece(canvas: CanvasItem, rect: Rect2, piece_type: CellState.PieceType) -> void:
	_draw_piece_shape(canvas, rect, color_player, piece_type)


func draw_ai_piece(canvas: CanvasItem, rect: Rect2, piece_type: CellState.PieceType) -> void:
	_draw_piece_shape(canvas, rect, color_ai, piece_type)


func draw_ghost_piece(canvas: CanvasItem, rect: Rect2) -> void:
	var ghost_color := Color(color_player.r, color_player.g, color_player.b, 0.35)
	canvas.draw_texture_rect_region(_spritesheet, rect, _PIECE_REGION, ghost_color)


func draw_piece(canvas: CanvasItem, rect: Rect2, color: Color) -> void:
	canvas.draw_texture_rect_region(_spritesheet, rect, _PIECE_REGION, color)


func draw_locked_cell(canvas: CanvasItem, rect: Rect2) -> void:
	canvas.draw_texture_rect_region(_spritesheet, rect, _GRID_TILE_REGION, color_locked)
	var font_size: int = int(rect.size.x * 0.45)
	var text := "■"
	var text_h: float = _font.get_ascent(font_size)
	var text_w: float = _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var pos := rect.get_center() + Vector2(-text_w * 0.5, text_h * 0.35)
	canvas.draw_string(_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size,
		Color(0.75, 0.75, 0.75))


func draw_frozen_overlay(canvas: CanvasItem, rect: Rect2, _turns_remaining: int) -> void:
	canvas.draw_rect(rect, color_frozen_overlay)
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


func draw_modifier_badge(canvas: CanvasItem, rect: Rect2, modifier_name: String) -> void:
	if modifier_name.is_empty():
		return
	var data: Dictionary = MODIFIER_DATA.get(modifier_name, {})
	if data.is_empty():
		return
	var badge_color: Color = data.get("color", Color.WHITE)
	var initial: String = data.get("initial", "?")
	var font_size: int = int(rect.size.x * 0.48)
	var text_w: float = _font.get_string_size(initial, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var text_h: float = _font.get_ascent(font_size)
	var center := rect.get_center()
	var text_pos := Vector2(center.x - text_w * 0.5, center.y + text_h * 0.35)
	canvas.draw_string(_font, text_pos, initial, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, badge_color)


func draw_queue_entry(canvas: CanvasItem, rect: Rect2, entry: QueueEntry) -> void:
	_draw_piece_shape(canvas, rect, color_player, entry.piece_type)
	draw_modifier_badge(canvas, rect, entry.modifier)


func get_modifier_initial(modifier_name: String) -> String:
	var data: Dictionary = MODIFIER_DATA.get(modifier_name, {})
	return data.get("initial", "?")


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

	canvas.draw_texture_rect_region(_spritesheet, rect, _PIECE_REGION, color)

	match piece_type:
		CellState.PieceType.PRISM:
			var t: float = Time.get_ticks_msec() * 0.001
			for i in 6:
				var hue := fmod(float(i) / 6.0 + t * 0.3, 1.0)
				var arc_color := Color.from_hsv(hue, 0.9, 1.0, 0.65)
				var start_a := float(i) / 6.0 * TAU
				var end_a := float(i + 1) / 6.0 * TAU
				canvas.draw_arc(center, radius * 1.08, start_a, end_a, 6, arc_color, 2.5)

		CellState.PieceType.COIN:
			canvas.draw_arc(center, radius, 0.0, TAU, 32, Color(1.0, 0.82, 0.18, 0.85), 3.0)

		CellState.PieceType.EMBER:
			var glow := Color(1.0, 0.42, 0.08, 0.9)
			for i in 4:
				var angle: float = i * TAU / 4.0 + TAU / 8.0
				var dir := Vector2(cos(angle), sin(angle))
				canvas.draw_line(center + dir * (radius * 0.55), center + dir * (radius * 1.1), glow, 2.0)

		CellState.PieceType.SHARD:
			var crystal := Color(0.78, 0.92, 1.0, 0.7)
			var dash_arc: float = TAU / 14.0
			for i in 7:
				var start_angle: float = i * TAU / 7.0
				canvas.draw_arc(center, radius * 1.06, start_angle, start_angle + dash_arc, 6, crystal, 1.5)
