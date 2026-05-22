class_name MatchRelicEntry extends PanelContainer

@onready var _icon_frame: PanelContainer = %IconFrame
@onready var _icon_texture: TextureRect = %IconTexture
@onready var _icon_glyph: ColorRect = %IconGlyph

var relic_id: String = ""


func setup(id: String) -> void:
	relic_id = id
	var rd: RelicData = DataRegistry.get_relic(id)
	_apply_icon(rd.icon if rd != null else null)
	var sb := _make_canvas_stylebox(4)
	add_theme_stylebox_override("panel", sb)
	GameTooltip.unbind(self)
	GameTooltip.bind(self, _tooltip_text(rd, id))


func _exit_tree() -> void:
	GameTooltip.unbind(self)


func _tooltip_text(rd: RelicData, id: String) -> String:
	if rd == null:
		return id
	return "%s\n%s" % [rd.display_name, rd.description]


func _make_canvas_stylebox(radius: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = UITheme.CANVAS
	sb.border_color = UITheme.SURFACE_BORDER_MUTED
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = 2.0
	sb.content_margin_right = 2.0
	sb.content_margin_top = 2.0
	sb.content_margin_bottom = 2.0
	sb.shadow_color = Color(0.0, 0.0, 0.0, 0.08)
	sb.shadow_size = 2
	sb.shadow_offset = Vector2(0, 1)
	return sb


func _apply_icon(texture: Texture2D) -> void:
	var sb := _make_canvas_stylebox(4)
	sb.bg_color = UITheme.CANVAS.lightened(0.04)
	sb.border_color = ShopOfferCard.RELIC_BORDER
	_icon_frame.add_theme_stylebox_override("panel", sb)
	if texture != null:
		_icon_texture.texture = texture
		_icon_texture.modulate = UITheme.TEXT_ON_CANVAS
		_icon_texture.visible = true
		_icon_glyph.visible = false
	else:
		_icon_texture.visible = false
		_icon_glyph.visible = true
		_icon_glyph.color = ShopOfferCard.RELIC_BORDER
