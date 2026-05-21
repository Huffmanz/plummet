extends Node
## Software hand cursor — avoids OS custom-cursor issues with canvas_items stretch.

enum Style { DEFAULT, OPEN, CLOSED }

const PATH_POINT := "res://assets/kenney_cursor-pack/PNG/Outline/Default/hand_point.png"
const PATH_OPEN := "res://assets/kenney_cursor-pack/PNG/Outline/Default/hand_open.png"
const PATH_CLOSED := "res://assets/kenney_cursor-pack/PNG/Outline/Default/hand_closed.png"

const HOTSPOT := Vector2(6, 2)
const CURSOR_SIZE := Vector2(16, 16)

var _textures: Dictionary = {}
var _style: Style = Style.DEFAULT
var _layer: CanvasLayer
var _sprite: TextureRect


func _ready() -> void:
	_textures[Style.DEFAULT] = load(PATH_POINT) as Texture2D
	_textures[Style.OPEN] = load(PATH_OPEN) as Texture2D
	_textures[Style.CLOSED] = load(PATH_CLOSED) as Texture2D
	for s in _textures:
		if _textures[s] == null:
			push_error("GameCursor: missing texture for style %s" % s)
	_layer = CanvasLayer.new()
	_layer.layer = 128
	add_child(_layer)
	_sprite = TextureRect.new()
	_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_sprite.custom_minimum_size = CURSOR_SIZE
	_sprite.size = CURSOR_SIZE
	_layer.add_child(_sprite)
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	call_deferred("apply_default")


func _process(_delta: float) -> void:
	var vp := get_viewport()
	if vp == null:
		return
	_sprite.position = vp.get_mouse_position() - HOTSPOT
	_update_sprite()


func apply_default() -> void:
	_set_style(Style.DEFAULT)


func apply_open() -> void:
	_set_style(Style.OPEN)


func apply_closed() -> void:
	_set_style(Style.CLOSED)


func _set_style(style: Style) -> void:
	if not _textures.has(style) or _textures[style] == null:
		return
	_style = style
	_update_sprite()


func _update_sprite() -> void:
	# Point + click: briefly show closed while LMB is held (finger press).
	if _style == Style.DEFAULT and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_sprite.texture = _textures[Style.CLOSED]
		return
	_sprite.texture = _textures[_style]
