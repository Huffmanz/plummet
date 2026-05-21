class_name ShopPiecePreview extends Control

const _PIECE_SHADER := preload("res://shaders/piece_type.gdshader")

var _shader_style: int = 0

@onready var _piece_rect: ColorRect = %PieceRect


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_sync_piece_size)


func setup(piece: Piece) -> void:
	_shader_style = PieceVisualUtil.shader_style_index_from_piece(piece.type)
	if not is_node_ready():
		await ready
	_apply_material()
	_sync_piece_size()
	if _piece_rect != null:
		_piece_rect.modulate = Color.WHITE


func flash_type_change() -> void:
	if _piece_rect == null:
		return
	var flash := create_tween()
	_piece_rect.modulate = Color(1.4, 1.4, 1.4, 1.0)
	flash.tween_property(_piece_rect, "modulate", Color.WHITE, 0.1) \
		.set_ease(Tween.EASE_OUT)


func _sync_piece_size() -> void:
	if _piece_rect == null:
		return
	var side := minf(size.x, size.y) * 0.9
	var half := side * 0.5
	_piece_rect.offset_left = -half
	_piece_rect.offset_top = -half
	_piece_rect.offset_right = half
	_piece_rect.offset_bottom = half


func _apply_material() -> void:
	var mat := ShaderMaterial.new()
	mat.shader = _PIECE_SHADER
	mat.set_shader_parameter("base_color", UITheme.PLAYER)
	mat.set_shader_parameter("style", _shader_style)
	_piece_rect.material = mat
