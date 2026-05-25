class_name ThemeCozy extends ThemeBase

# Modifier visual data: icon path (future) + initial letter + badge color.
# If icon is null/empty, the initial is drawn instead.
const MODIFIER_DATA: Dictionary = {
	"Ignite":   {"initial": "I", "color": Color("#D93824")},
	"Magnet":   {"initial": "M", "color": Color("#3A90D4")},
	"Deposit":  {"initial": "D", "color": Color("#D9B81E")},
	"Ripple":   {"initial": "R", "color": Color("#25B8AE")},
	"Echo":     {"initial": "E", "color": Color("#9B6BB8")},
	"Detonate": {"initial": "X", "color": Color("#E87320")},
	"Bounty":   {"initial": "B", "color": Color("#52B85A")},
	"Surge":    {"initial": "Z", "color": Color("#EBD91F")},
}

var _font: Font


func _init() -> void:
	color_player = UITheme.PLAYER
	color_ai = UITheme.AI
	color_empty = UITheme.CELL_EMPTY
	color_bg = UITheme.BOARD_WELL
	color_locked = UITheme.LOCKED
	color_frozen_overlay = Color(0.55, 0.82, 0.98, 0.42)
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


func draw_ghost_piece(
	canvas: CanvasItem,
	rect: Rect2,
	piece_type: CellState.PieceType = CellState.PieceType.NORMAL,
	modifier: String = ""
) -> void:
	var ghost := Color(color_player.r, color_player.g, color_player.b, 0.35)
	_draw_piece(canvas, rect, ghost, piece_type, true)
	if not modifier.is_empty():
		draw_modifier_badge(canvas, rect, modifier)


func draw_piece(
	canvas: CanvasItem,
	rect: Rect2,
	color: Color,
	piece_type: CellState.PieceType = CellState.PieceType.NORMAL,
	modifier: String = ""
) -> void:
	_draw_piece(canvas, rect, color, piece_type)
	if not modifier.is_empty():
		draw_modifier_badge(canvas, rect, modifier)


func draw_locked_cell(canvas: CanvasItem, rect: Rect2) -> void:
	canvas.draw_rect(rect, color_locked)
	canvas.draw_rect(rect, UITheme.CELL_BORDER, false, 1.5)
	var font_size: int = int(rect.size.x * 0.42)
	var text := "■"
	var text_w: float = _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var pos := rect.get_center() + Vector2(-text_w * 0.5, _font.get_ascent(font_size) * 0.35)
	canvas.draw_string(_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, UITheme.TEXT_MUTED_ON_SURFACE)


func draw_frozen_cell(canvas: CanvasItem, rect: Rect2) -> void:
	var frost := Color(0.70, 0.88, 1.0, 0.35)
	canvas.draw_rect(rect, frost)
	canvas.draw_rect(rect, Color(0.45, 0.72, 0.95, 0.85), false, 2.0)


func draw_frozen_overlay(canvas: CanvasItem, rect: Rect2, turns_remaining: int) -> void:
	canvas.draw_rect(rect, color_frozen_overlay)
	canvas.draw_rect(rect.grow(-2.0), Color(0.35, 0.65, 0.92, 0.55), false, 3.0)
	if turns_remaining > 0:
		var label := str(turns_remaining)
		var font_size: int = clampi(int(rect.size.x * 0.22), 10, 16)
		var text_w: float = _font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var pos := rect.position + Vector2((rect.size.x - text_w) * 0.5, rect.size.y * 0.08)
		canvas.draw_string(
			_font, pos, label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size,
			Color(0.15, 0.35, 0.55, 0.9)
		)
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


# Draws a modifier badge showing the initial letter (or icon when added later).
# modifier_name is a single modifier string (empty = no badge).
func draw_modifier_badge(canvas: CanvasItem, rect: Rect2, modifier_name: String) -> void:
	if modifier_name.is_empty():
		return

	var badge_color := PieceVisualUtil.modifier_badge_color(modifier_name)
	var initial := PieceVisualUtil.modifier_initial(modifier_name)
	var icon := PieceVisualUtil.modifier_icon(modifier_name)

	var side := minf(rect.size.x, rect.size.y) * 0.42
	var center := rect.get_center()
	var radius := side * 0.5
	canvas.draw_circle(center, radius, badge_color)
	canvas.draw_arc(center, radius, 0.0, TAU, 48, UITheme.SURFACE_BORDER, 2.0)

	if icon != null:
		var icon_side := side * 0.72
		var icon_rect := Rect2(center - Vector2(icon_side, icon_side) * 0.5, Vector2(icon_side, icon_side))
		canvas.draw_texture_rect(icon, icon_rect, false)
	else:
		var font_size: int = int(side * 0.45)
		var text_w: float = _font.get_string_size(initial, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var text_h: float = _font.get_ascent(font_size)
		var text_pos := Vector2(center.x - text_w * 0.5, center.y + text_h * 0.35)
		canvas.draw_string(_font, text_pos, initial, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, UITheme.TEXT_ON_SURFACE)


func draw_queue_entry(canvas: CanvasItem, rect: Rect2, entry: QueueEntry) -> void:
	_draw_piece(canvas, rect, color_player, entry.piece_type)
	draw_modifier_badge(canvas, rect, entry.modifier)


func get_modifier_initial(modifier_name: String) -> String:
	return PieceVisualUtil.modifier_initial(modifier_name)


func get_modifier_color(modifier_name: String) -> Color:
	return PieceVisualUtil.modifier_badge_color(modifier_name)


func get_piece_border_style(piece_type: CellState.PieceType) -> int:
	return PieceVisualUtil.shader_style_index(piece_type)


func _draw_piece(
	canvas: CanvasItem,
	rect: Rect2,
	color: Color,
	piece_type: CellState.PieceType,
	ghost_outline: bool = false
) -> void:
	var pixel_size := PieceShaderTextureCache.layout_pixel_size(minf(rect.size.x, rect.size.y))
	var tex := PieceShaderTextureCache.get_texture_sync(color, piece_type, pixel_size)
	if tex != null:
		var side := minf(rect.size.x, rect.size.y) * 0.9
		var draw_rect := Rect2(rect.get_center() - Vector2(side, side) * 0.5, Vector2(side, side))
		var modulate := Color.WHITE
		if ghost_outline:
			modulate = Color(1.0, 1.0, 1.0, 0.35)
		canvas.draw_texture_rect(tex, draw_rect, false, modulate)
		return

	_draw_piece_fallback(canvas, rect, color, piece_type, ghost_outline)


func _draw_piece_fallback(
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
		CellState.PieceType.PRISM:
			# Rainbow ring — spectral color bands rotating
			var t: float = Time.get_ticks_msec() * 0.001
			var hue_steps := 6
			for i in hue_steps:
				var hue := fmod(float(i) / hue_steps + t * 0.3, 1.0)
				var arc_color := Color.from_hsv(hue, 0.9, 1.0, 0.7)
				var start_a := float(i) / hue_steps * TAU
				var end_a := float(i + 1) / hue_steps * TAU
				canvas.draw_arc(center, radius * 1.06, start_a, end_a, 6, arc_color, 2.5)

		CellState.PieceType.COIN:
			# Gold shimmer ring + inner dollar-sign cross
			var gold := Color(1.0, 0.82, 0.18, 0.85)
			canvas.draw_arc(center, radius * 0.98, 0.0, TAU, 32, gold, 3.0)
			var inner_r := radius * 0.38
			canvas.draw_line(center + Vector2(0.0, -inner_r), center + Vector2(0.0, inner_r), gold, 2.0)
			canvas.draw_line(center + Vector2(-inner_r, 0.0), center + Vector2(inner_r, 0.0), gold, 2.0)

		CellState.PieceType.EMBER:
			# Smoldering glow — orange-red inner dot + outward spikes
			var glow := Color(1.0, 0.42, 0.08, 0.9)
			canvas.draw_circle(center, radius * 0.48, glow)
			for i in 4:
				var angle: float = i * TAU / 4.0 + TAU / 8.0
				var dir := Vector2(cos(angle), sin(angle))
				canvas.draw_line(center + dir * (radius * 0.55), center + dir * (radius * 1.02), glow, 2.0)

		CellState.PieceType.SHARD:
			# Crystal fracture lines — internal crack pattern
			var crystal := Color(0.78, 0.92, 1.0, 0.75)
			var crack_pts: Array[Vector2] = [
				center + Vector2(-radius * 0.1, radius * 0.05),
				center + Vector2(radius * 0.35, -radius * 0.25),
				center + Vector2(-radius * 0.3, -radius * 0.35),
				center + Vector2(radius * 0.15, radius * 0.38),
			]
			for i in crack_pts.size() - 1:
				canvas.draw_line(crack_pts[i], crack_pts[i + 1], crystal, 1.5)
			canvas.draw_line(crack_pts[0], crack_pts[2], crystal, 1.0)
			# Outer dashed ring
			var dash_arc: float = TAU / 14.0
			for i in 7:
				var start_angle: float = i * TAU / 7.0
				canvas.draw_arc(center, radius * 1.04, start_angle, start_angle + dash_arc, 6, crystal, 1.5)
