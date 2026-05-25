class_name PieceShaderTextureCache extends RefCounted
## Cached shader-rendered piece textures for board/queue canvas drawing.

static var _textures: Dictionary = {}
static var _baker: PieceShaderBaker = null
static var _warmed_pixel_size: int = -1


static func clear() -> void:
	_textures.clear()
	_warmed_pixel_size = -1


static func warm_for_layout_async(pixel_size: int, player_color: Color, ai_color: Color) -> void:
	var size := maxi(8, pixel_size)
	if size == _warmed_pixel_size and not _textures.is_empty():
		return
	# SubViewport readback is unreliable on WebGL; ThemeCozy falls back to vector drawing.
	if OS.has_feature("web"):
		_warmed_pixel_size = size
		return

	_textures.clear()
	var baker := _ensure_baker()
	for style in 5:
		_store_style(player_color, style, size, await baker.bake(player_color, style, size))
		_store_style(ai_color, style, size, await baker.bake(ai_color, style, size))
	_warmed_pixel_size = size


static func get_texture_sync(base_color: Color, piece_type: CellState.PieceType, pixel_size: int) -> Texture2D:
	var size := maxi(8, pixel_size)
	var key := _cache_key(base_color, piece_type, size)
	if _textures.has(key):
		return _textures[key] as Texture2D
	return null


static func layout_pixel_size(cell_size: float) -> int:
	return maxi(8, int(cell_size))


static func _store_style(base_color: Color, style: int, pixel_size: int, tex: Texture2D) -> void:
	if tex == null:
		return
	_textures[_cache_key_for_style(base_color, style, pixel_size)] = tex


static func _store(base_color: Color, piece_type: CellState.PieceType, pixel_size: int, tex: Texture2D) -> void:
	_store_style(base_color, PieceVisualUtil.shader_style_index(piece_type), pixel_size, tex)


static func _cache_key(base_color: Color, piece_type: CellState.PieceType, pixel_size: int) -> String:
	return _cache_key_for_style(base_color, PieceVisualUtil.shader_style_index(piece_type), pixel_size)


static func _cache_key_for_style(base_color: Color, style: int, pixel_size: int) -> String:
	return "%d_%d_%d_%d_%d_%d" % [
		int(base_color.r * 255.0),
		int(base_color.g * 255.0),
		int(base_color.b * 255.0),
		int(base_color.a * 255.0),
		style,
		pixel_size,
	]


static func _ensure_baker() -> PieceShaderBaker:
	if _baker == null or not is_instance_valid(_baker):
		_baker = PieceShaderBaker.new()
	if _baker.get_parent() == null:
		var root: Node = Engine.get_main_loop().root
		root.add_child.call_deferred(_baker)
	return _baker
