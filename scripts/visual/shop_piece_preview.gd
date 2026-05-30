class_name ShopPiecePreview extends Control
## Bag / offer piece disc — baked shader texture, live shader, or vector fallback.

const DISC_FILL_RATIO := 0.9

var _piece_type: CellState.PieceType = CellState.PieceType.NORMAL
var _disc_texture: Texture2D = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	resized.connect(_on_resized)


func setup(piece: Piece) -> void:
	_piece_type = PieceVisualUtil.cell_piece_type(piece.type)
	if not is_node_ready():
		await ready
	await _apply_disc_visual()


func flash_type_change() -> void:
	var flash := create_tween()
	modulate = Color(1.4, 1.4, 1.4, 1.0)
	flash.tween_property(self, "modulate", Color.WHITE, 0.1) \
		.set_ease(Tween.EASE_OUT)


func _apply_disc_visual() -> void:
	if size.x < 8.0 or size.y < 8.0:
		return
	_disc_texture = null
	var pixel_size := PieceShaderTextureCache.layout_pixel_size(minf(size.x, size.y) * DISC_FILL_RATIO)
	_disc_texture = await PieceShaderTextureCache.get_or_bake_texture_async(
		UITheme.PLAYER,
		_piece_type,
		pixel_size
	)
	modulate = Color.WHITE
	queue_redraw()


func _on_resized() -> void:
	queue_redraw()


func _draw() -> void:
	if size.x < 1.0 or size.y < 1.0:
		return
	var side := minf(size.x, size.y) * DISC_FILL_RATIO
	var draw_rect := Rect2(size * 0.5 - Vector2(side, side) * 0.5, Vector2(side, side))
	if _disc_texture != null:
		draw_texture_rect(_disc_texture, draw_rect, false)
		return
	_draw_vector_disc(draw_rect)


func _draw_vector_disc(rect: Rect2) -> void:
	var color := UITheme.PLAYER
	var center := rect.get_center()
	var radius: float = minf(rect.size.x, rect.size.y) * 0.42
	var outline := color.darkened(0.32)
	draw_circle(center, radius, color)
	draw_arc(center, radius, 0.0, TAU, 32, outline, 2.5)

	match _piece_type:
		CellState.PieceType.PRISM:
			var t: float = Time.get_ticks_msec() * 0.001
			var hue_steps := 6
			for i in hue_steps:
				var hue := fmod(float(i) / float(hue_steps) + t * 0.3, 1.0)
				var arc_color := Color.from_hsv(hue, 0.9, 1.0, 0.7)
				var start_a := float(i) / float(hue_steps) * TAU
				var end_a := float(i + 1) / float(hue_steps) * TAU
				draw_arc(center, radius * 1.06, start_a, end_a, 6, arc_color, 2.5)
		CellState.PieceType.COIN:
			var gold := Color(1.0, 0.82, 0.18, 0.85)
			draw_arc(center, radius * 0.98, 0.0, TAU, 32, gold, 3.0)
			var inner_r := radius * 0.38
			draw_line(center + Vector2(0.0, -inner_r), center + Vector2(0.0, inner_r), gold, 2.0)
			draw_line(center + Vector2(-inner_r, 0.0), center + Vector2(inner_r, 0.0), gold, 2.0)
		CellState.PieceType.EMBER:
			var glow := Color(1.0, 0.42, 0.08, 0.9)
			draw_circle(center, radius * 0.48, glow)
			for i in 4:
				var angle: float = i * TAU / 4.0 + TAU / 8.0
				var dir := Vector2(cos(angle), sin(angle))
				draw_line(center + dir * (radius * 0.55), center + dir * (radius * 1.02), glow, 2.0)
		CellState.PieceType.SHARD:
			var crystal := Color(0.78, 0.92, 1.0, 0.75)
			var crack_pts: Array[Vector2] = [
				center + Vector2(-radius * 0.1, radius * 0.05),
				center + Vector2(radius * 0.35, -radius * 0.25),
				center + Vector2(-radius * 0.3, -radius * 0.35),
				center + Vector2(radius * 0.15, radius * 0.38),
			]
			for i in crack_pts.size() - 1:
				draw_line(crack_pts[i], crack_pts[i + 1], crystal, 1.5)
			draw_line(crack_pts[0], crack_pts[2], crystal, 1.0)
			var dash_arc: float = TAU / 14.0
			for i in 7:
				var start_angle: float = i * TAU / 7.0
				draw_arc(center, radius * 1.04, start_angle, start_angle + dash_arc, 6, crystal, 1.5)
