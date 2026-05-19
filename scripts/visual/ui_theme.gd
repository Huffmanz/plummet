class_name UITheme extends RefCounted
## Light Cozy design tokens and shared Control styling.

# Canvas
const CANVAS := Color("#F2EBE0")
const CANVAS_PATTERN := Color("#C9BFB0", 0.12)
const CANVAS_STAR := Color("#D4C9B8", 0.35)

# Surfaces
const SURFACE := Color("#2E2A3D")
const SURFACE_LIGHT := Color("#3D3854")
const SURFACE_BORDER := Color("#F2EBE0")
const SURFACE_BORDER_MUTED := Color("#D4C9B8")

# Accents
const ACCENT := Color("#7BAE7F")
const ACCENT_HOVER := Color("#8FC193")
const ACCENT_POP := Color("#E8C84A")
const DANGER := Color("#D4736E")
const VICTORY := Color("#5A9E62")
const DEFEAT := Color("#D4736E")

# Players (softened for cream backgrounds)
const PLAYER := Color("#B86BC4")
const AI := Color("#4DA8B0")

# Board
const CELL_EMPTY := Color("#3D3854")
const CELL_BORDER := Color("#524D68")
const BOARD_WELL := Color("#2E2A3D")
const BOARD_HEAT := Color("#8B4540")
const LOCKED := Color("#6B6578")

# Text
const TEXT_ON_CANVAS := Color("#2E2A3D")
const TEXT_ON_SURFACE := Color("#F2EBE0")
const TEXT_MUTED := Color("#9A94A8")
const TEXT_MUTED_ON_SURFACE := Color("#B8B2C4")

const RADIUS_CARD := 14
const RADIUS_BUTTON := 10
const RADIUS_CELL := 5


static func make_surface_style(radius: int = RADIUS_CARD, fill: Color = SURFACE) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = SURFACE_BORDER
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = 14.0
	sb.content_margin_right = 14.0
	sb.content_margin_top = 12.0
	sb.content_margin_bottom = 12.0
	sb.shadow_color = Color(0.0, 0.0, 0.0, 0.12)
	sb.shadow_size = 4
	sb.shadow_offset = Vector2(0, 2)
	return sb


static func make_button_style(normal: Color = ACCENT, hover: Color = ACCENT_HOVER) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = normal
	sb.border_color = SURFACE_BORDER
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(RADIUS_BUTTON)
	sb.content_margin_left = 16.0
	sb.content_margin_right = 16.0
	sb.content_margin_top = 10.0
	sb.content_margin_bottom = 10.0
	return sb


static func style_button(btn: Button, normal: Color = ACCENT, hover: Color = ACCENT_HOVER) -> void:
	var normal_sb := make_button_style(normal, hover)
	var hover_sb := make_button_style(hover, hover)
	btn.add_theme_color_override("font_color", TEXT_ON_SURFACE)
	btn.add_theme_color_override("font_hover_color", TEXT_ON_SURFACE)
	btn.add_theme_color_override("font_pressed_color", TEXT_ON_SURFACE)
	btn.add_theme_color_override("font_disabled_color", TEXT_MUTED_ON_SURFACE)
	btn.add_theme_stylebox_override("normal", normal_sb)
	btn.add_theme_stylebox_override("hover", hover_sb)
	btn.add_theme_stylebox_override("pressed", hover_sb)
	btn.add_theme_stylebox_override("focus", normal_sb)
	btn.add_theme_stylebox_override("disabled", make_button_style(SURFACE_LIGHT, SURFACE_LIGHT))


static func style_label_primary(label: Label, on_surface: bool = false) -> void:
	label.add_theme_color_override(
		"font_color", TEXT_ON_SURFACE if on_surface else TEXT_ON_CANVAS
	)


static func style_label_muted(label: Label, on_surface: bool = false) -> void:
	label.add_theme_color_override(
		"font_color", TEXT_MUTED_ON_SURFACE if on_surface else TEXT_MUTED
	)


static func apply_canvas_bg(node: ColorRect) -> void:
	node.color = CANVAS


static func draw_star_pattern(canvas: CanvasItem, rect: Rect2) -> void:
	canvas.draw_rect(rect, CANVAS)
	var step := 28.0
	var y := rect.position.y + step * 0.5
	while y < rect.end.y:
		var x := rect.position.x + step * 0.3
		var flip := false
		while x < rect.end.x:
			_draw_star(canvas, Vector2(x, y), 2.5 if not flip else 2.0)
			x += step
			flip = not flip
		y += step


static func _draw_star(canvas: CanvasItem, center: Vector2, size: float) -> void:
	var pts := PackedVector2Array()
	for i in 4:
		var a := i * TAU / 4.0 + PI * 0.25
		pts.append(center + Vector2(cos(a), sin(a)) * size)
		var a2 := a + TAU / 8.0
		pts.append(center + Vector2(cos(a2), sin(a2)) * size * 0.4)
	canvas.draw_colored_polygon(pts, CANVAS_STAR)


static func draw_rounded_rect(
	canvas: CanvasItem,
	rect: Rect2,
	radius: float,
	fill: Color,
	border: Color = Color.TRANSPARENT,
	border_width: float = 0.0
) -> void:
	var r := mini(radius, mini(rect.size.x * 0.5, rect.size.y * 0.5))
	if r <= 0.0:
		canvas.draw_rect(rect, fill)
		if border_width > 0.0:
			canvas.draw_rect(rect, border, false, border_width)
		return
	# Center cross + corner circles
	var inner := Rect2(rect.position + Vector2(r, r), rect.size - Vector2(r, r) * 2.0)
	canvas.draw_rect(inner, fill)
	canvas.draw_rect(Rect2(rect.position.x, rect.position.y + r, rect.size.x, rect.size.y - r * 2.0), fill)
	canvas.draw_rect(Rect2(rect.position.x + r, rect.position.y, rect.size.x - r * 2.0, rect.size.y), fill)
	canvas.draw_circle(rect.position + Vector2(r, r), r, fill)
	canvas.draw_circle(Vector2(rect.end.x - r, rect.position.y + r), r, fill)
	canvas.draw_circle(Vector2(rect.position.x + r, rect.end.y - r), r, fill)
	canvas.draw_circle(rect.end - Vector2(r, r), r, fill)
	if border_width > 0.0:
		canvas.draw_rect(rect, border, false, border_width)
