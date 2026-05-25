class_name ModifierIconBadge extends PanelContainer
## Rounded badge (texture or initial) — modifiers, relics, shop bag, drag cursor.

const DEFAULT_SIZE := Vector2(28, 28)
const RELIC_BADGE_COLOR := Color("#4DA8B0")


static func create_for_modifier(modifier_id: String, badge_size: Vector2 = DEFAULT_SIZE) -> ModifierIconBadge:
	var badge := ModifierIconBadge.new()
	badge.custom_minimum_size = badge_size
	badge.size = badge_size
	badge.setup_modifier(modifier_id)
	return badge


static func create_for_relic(relic_id: String, badge_size: Vector2 = DEFAULT_SIZE) -> ModifierIconBadge:
	var badge := ModifierIconBadge.new()
	badge.custom_minimum_size = badge_size
	badge.size = badge_size
	var texture: Texture2D = null
	var initial := "?"
	var rd: RelicData = DataRegistry.get_relic(relic_id)
	if rd != null:
		texture = rd.icon
		if not rd.display_name.is_empty():
			initial = rd.display_name[0]
		elif not relic_id.is_empty():
			initial = relic_id[0]
	badge._apply_badge(texture, RELIC_BADGE_COLOR, initial)
	return badge


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func setup_modifier(modifier_id: String) -> void:
	for child in get_children():
		child.queue_free()

	if modifier_id.is_empty():
		visible = false
		return

	visible = true
	var texture: Texture2D = null
	var bg_color := UITheme.ACCENT
	var initial := "?"

	var md: ModifierData = DataRegistry.get_modifier(modifier_id)
	if md:
		texture = md.icon
		bg_color = md.badge_color
		initial = md.initial if not md.initial.is_empty() else modifier_id[0]
	else:
		initial = PieceVisualUtil.modifier_initial(modifier_id)
		bg_color = PieceVisualUtil.modifier_badge_color(modifier_id)

	_apply_badge(texture, bg_color, initial)


func _apply_badge(texture: Texture2D, bg_color: Color, initial: String) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_color
	sb.border_color = UITheme.SURFACE_BORDER
	sb.set_border_width_all(2)
	var corner := int(minf(size.x, size.y) * 0.5)
	sb.set_corner_radius_all(corner)
	add_theme_stylebox_override("panel", sb)

	if texture != null:
		var tex_rect := TextureRect.new()
		tex_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		tex_rect.offset_left = 4.0
		tex_rect.offset_top = 4.0
		tex_rect.offset_right = -4.0
		tex_rect.offset_bottom = -4.0
		tex_rect.texture = texture
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(tex_rect)
	else:
		var label := Label.new()
		label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		label.text = initial
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", int(size.y * 0.45))
		label.add_theme_color_override("font_color", UITheme.TEXT_ON_SURFACE)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(label)
