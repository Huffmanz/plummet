class_name PieceShaderTextureCache extends RefCounted
## Cached shader-rendered piece textures for board/queue canvas drawing.

static var _textures: Dictionary = {}
static var _baker: PieceShaderBaker = null


static func clear() -> void:
	_textures.clear()


static func warm_for_layout_async(pixel_size: int, player_color: Color, ai_color: Color) -> void:
	var baker := _ensure_baker()
	var size := maxi(8, pixel_size)
	for piece_type in CellState.PieceType.values():
		var pt := piece_type as CellState.PieceType
		var style := PieceVisualUtil.shader_style_index(pt)
		_store(player_color, pt, size, await baker.bake(player_color, style, size))
		_store(ai_color, pt, size, await baker.bake(ai_color, style, size))


static func get_texture_sync(base_color: Color, piece_type: CellState.PieceType, pixel_size: int) -> Texture2D:
	var key := _cache_key(base_color, piece_type, maxi(8, pixel_size))
	if _textures.has(key):
		return _textures[key] as Texture2D
	return null


static func _store(base_color: Color, piece_type: CellState.PieceType, pixel_size: int, tex: Texture2D) -> void:
	_textures[_cache_key(base_color, piece_type, pixel_size)] = tex


static func _cache_key(base_color: Color, piece_type: CellState.PieceType, pixel_size: int) -> String:
	var style := PieceVisualUtil.shader_style_index(piece_type)
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
		var root: Node = Engine.get_main_loop().root
		root.add_child(_baker)
		_baker._initialize()
	return _baker
