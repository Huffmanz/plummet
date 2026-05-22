class_name PieceShaderBaker extends Node
## Renders piece_type.gdshader into a unique ImageTexture for canvas drawing.

const _PIECE_SHADER := preload("res://shaders/piece_type.gdshader")

var _viewport: SubViewport
var _rect: ColorRect
var _material: ShaderMaterial


func _ready() -> void:
	_initialize()


func _initialize() -> void:
	if _viewport != null:
		return

	_viewport = SubViewport.new()
	_viewport.transparent_bg = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(_viewport)

	_rect = ColorRect.new()
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_viewport.add_child(_rect)

	_material = ShaderMaterial.new()
	_material.shader = _PIECE_SHADER
	_rect.material = _material


func bake(base_color: Color, style: int, pixel_size: int) -> Texture2D:
	_initialize()
	if not is_inside_tree():
		await tree_entered

	var size := maxi(8, pixel_size)
	_viewport.size = Vector2i(size, size)
	_rect.size = Vector2(size, size)
	_material.set_shader_parameter("base_color", base_color)
	_material.set_shader_parameter("style", style)
	_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	await get_tree().process_frame
	await get_tree().process_frame

	var viewport_tex := _viewport.get_texture()
	if viewport_tex == null:
		return null
	var img := viewport_tex.get_image()
	if img == null or img.is_empty():
		return null
	return ImageTexture.create_from_image(img)
