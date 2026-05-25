class_name ShopIcon extends PanelContainer
## Bordered icon badge for shop offer cards, relic slots, piece info, etc.

const RELIC_BORDER := Color("#4DA8B0")
const DEFAULT_GLYPH := Color(0.95, 0.93, 0.9, 1)

@export var texture_min_size: Vector2 = Vector2(14, 14)
@export var glyph_min_size: Vector2 = Vector2(10, 10)
@export var corner_radius: int = 4

@onready var _icon_texture: TextureRect = %IconTexture
@onready var _icon_glyph: ColorRect = %IconGlyph


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icon_texture.custom_minimum_size = texture_min_size
	_icon_glyph.custom_minimum_size = glyph_min_size


func setup(texture: Texture2D, border_color: Color) -> void:
	if not is_node_ready():
		await ready
	var sb := StyleBoxFlat.new()
	sb.bg_color = UITheme.SURFACE
	sb.border_color = border_color
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(corner_radius)
	add_theme_stylebox_override("panel", sb)

	if texture != null:
		_icon_texture.texture = texture
		_icon_texture.modulate = Color.WHITE
		_icon_texture.visible = true
		_icon_glyph.visible = false
	else:
		_icon_texture.visible = false
		_icon_glyph.visible = true
		if border_color == UITheme.PLAYER:
			_icon_glyph.color = border_color.lightened(0.22)
		else:
			_icon_glyph.color = DEFAULT_GLYPH


func setup_relic(texture: Texture2D) -> void:
	setup(texture, RELIC_BORDER)
