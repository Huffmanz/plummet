class_name ShopPieceInfoPopup extends PanelContainer

const PANEL_WIDTH := 200.0
const MAX_PANEL_HEIGHT := 220.0
const VIEWPORT_MARGIN := 8.0
const ANCHOR_GAP := 8.0

@onready var _scroll: ScrollContainer = %ScrollRoot
@onready var _body: VBoxContainer = %Body
@onready var _type_icon_frame: PanelContainer = %TypeIconFrame
@onready var _type_icon_texture: TextureRect = %TypeIconTexture
@onready var _type_icon_glyph: ColorRect = %TypeIconGlyph
@onready var _type_name_lbl: Label = %TypeNameLabel
@onready var _type_kind_lbl: Label = %TypeKindLabel
@onready var _type_desc_lbl: Label = %TypeDescLabel
@onready var _modifier_block: VBoxContainer = %ModifierBlock
@onready var _mod_icon_frame: PanelContainer = %ModIconFrame
@onready var _mod_icon_texture: TextureRect = %ModIconTexture
@onready var _mod_icon_glyph: ColorRect = %ModIconGlyph
@onready var _mod_name_lbl: Label = %ModNameLabel
@onready var _mod_kind_lbl: Label = %ModKindLabel
@onready var _mod_desc_lbl: Label = %ModDescLabel

var _anchor: Control = null


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_stylebox_override("panel", UITheme.make_surface_style(10, UITheme.SURFACE_LIGHT))
	_style_labels()
	custom_minimum_size.x = PANEL_WIDTH


func _style_labels() -> void:
	UITheme.style_label_primary(_type_name_lbl, true)
	UITheme.style_label_muted(_type_kind_lbl, true)
	UITheme.style_label_primary(_type_desc_lbl, true)
	_type_desc_lbl.add_theme_font_size_override("font_size", 9)
	UITheme.style_label_primary(_mod_name_lbl, true)
	UITheme.style_label_muted(_mod_kind_lbl, true)
	UITheme.style_label_primary(_mod_desc_lbl, true)
	_mod_desc_lbl.add_theme_font_size_override("font_size", 9)


func show_for(anchor: Control, piece: Piece) -> void:
	if anchor == null:
		hide_popup()
		return
	var same_anchor := _anchor == anchor and visible
	_anchor = anchor
	if not same_anchor:
		_apply_piece(piece)
	visible = true
	call_deferred("_reposition")


func hide_popup() -> void:
	_anchor = null
	visible = false


func _apply_piece(piece: Piece) -> void:
	var type_data := _piece_type_data(piece.type)
	if type_data != null:
		_type_name_lbl.text = type_data.display_name
		_type_kind_lbl.text = ShopOfferCard.format_piece_type()
		_type_desc_lbl.text = type_data.description
		_apply_icon(
			_type_icon_frame,
			_type_icon_texture,
			_type_icon_glyph,
			type_data.icon,
			UITheme.PLAYER if piece.type == Piece.Type.NORMAL else UITheme.PLAYER
		)
	else:
		_type_name_lbl.text = "?"
		_type_kind_lbl.text = ""
		_type_desc_lbl.text = ""

	var has_modifier := not piece.modifier.is_empty()
	_modifier_block.visible = has_modifier
	if not has_modifier:
		return

	var mod_data: ModifierData = DataRegistry.get_modifier(piece.modifier)
	if mod_data != null:
		_mod_name_lbl.text = mod_data.display_name
		_mod_kind_lbl.text = ShopOfferCard.format_modifier_type(mod_data.trigger)
		_mod_desc_lbl.text = mod_data.description
		_apply_icon(
			_mod_icon_frame,
			_mod_icon_texture,
			_mod_icon_glyph,
			mod_data.icon,
			mod_data.badge_color
		)
	else:
		_mod_name_lbl.text = piece.modifier
		_mod_kind_lbl.text = "Modifier"
		_mod_desc_lbl.text = ""


func _apply_icon(
	frame: PanelContainer,
	texture_rect: TextureRect,
	glyph: ColorRect,
	texture: Texture2D,
	border_color: Color
) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = UITheme.SURFACE
	sb.border_color = border_color
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(4)
	frame.add_theme_stylebox_override("panel", sb)

	if texture != null:
		texture_rect.texture = texture
		texture_rect.visible = true
		glyph.visible = false
	else:
		texture_rect.visible = false
		glyph.visible = true
		if border_color == UITheme.PLAYER:
			glyph.color = border_color.lightened(0.22)
		else:
			glyph.color = Color(0.95, 0.93, 0.9, 1)


func _reposition() -> void:
	if _anchor == null or not is_instance_valid(_anchor):
		hide_popup()
		return

	var vp := get_viewport().get_visible_rect()
	var anchor_rect := _anchor.get_global_rect()

	_body.custom_minimum_size.x = PANEL_WIDTH - 16.0
	_scroll.custom_minimum_size = Vector2.ZERO
	reset_size()

	var natural_h := _body.get_combined_minimum_size().y + 8.0
	var space_above := anchor_rect.position.y - vp.position.y - VIEWPORT_MARGIN
	var space_below := vp.end.y - anchor_rect.end.y - VIEWPORT_MARGIN
	var prefer_above := space_above >= space_below
	var max_h := MAX_PANEL_HEIGHT
	if prefer_above:
		max_h = minf(max_h, space_above - ANCHOR_GAP)
	else:
		max_h = minf(max_h, space_below - ANCHOR_GAP)
	max_h = maxf(max_h, 48.0)

	var panel_h := minf(natural_h, max_h)
	_scroll.custom_minimum_size = Vector2(PANEL_WIDTH - 16.0, panel_h)
	reset_size()

	var panel_size := size
	var pos := Vector2.ZERO
	if prefer_above:
		pos.y = anchor_rect.position.y - panel_size.y - ANCHOR_GAP
	else:
		pos.y = anchor_rect.end.y + ANCHOR_GAP
	pos.x = anchor_rect.position.x + anchor_rect.size.x * 0.5 - panel_size.x * 0.5

	pos.x = clampf(pos.x, vp.position.x + VIEWPORT_MARGIN, vp.end.x - panel_size.x - VIEWPORT_MARGIN)
	pos.y = clampf(pos.y, vp.position.y + VIEWPORT_MARGIN, vp.end.y - panel_size.y - VIEWPORT_MARGIN)
	global_position = pos


static func _piece_type_data(t: Piece.Type) -> PieceTypeData:
	return PieceVisualUtil.piece_type_data_from_piece(t)
