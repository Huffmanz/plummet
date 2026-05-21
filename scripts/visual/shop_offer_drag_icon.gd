class_name ShopOfferDragIcon extends PanelContainer
## Cursor-following badge for shop offer drags (texture or color + initial).

const BADGE_SIZE := Vector2(40, 40)

var _badge: ModifierIconBadge = null
var _snapping: bool = false


static func create_for_offer(kind: String, id: String) -> ShopOfferDragIcon:
	var icon := ShopOfferDragIcon.new()
	match kind:
		"modifier":
			icon._build_modifier(id)
		"piece_type":
			icon._build_piece_type(id)
		_:
			icon._build_relic(id)
	return icon


func _init() -> void:
	custom_minimum_size = BADGE_SIZE
	size = BADGE_SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 1000


func _build_modifier(modifier_id: String) -> void:
	_badge = ModifierIconBadge.create_for_modifier(modifier_id, BADGE_SIZE)
	add_child(_badge)


func _build_piece_type(type_id: String) -> void:
	var td: PieceTypeData = DataRegistry.get_piece_type(type_id)
	var initial := td.initial if td and not td.initial.is_empty() else type_id[0]
	_badge = _make_simple_badge(UITheme.PLAYER, initial, 20)
	add_child(_badge)


func _build_relic(relic_id: String) -> void:
	var rd: RelicData = DataRegistry.get_relic(relic_id)
	var initial := rd.display_name[0] if rd and not rd.display_name.is_empty() else relic_id[0]
	_badge = _make_simple_badge(ShopOfferCard.RELIC_BORDER, initial)
	add_child(_badge)


func _make_simple_badge(bg_color: Color, initial: String, corner_radius: int = -1) -> ModifierIconBadge:
	var badge := ModifierIconBadge.new()
	badge.custom_minimum_size = BADGE_SIZE
	badge.size = BADGE_SIZE
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_color
	sb.border_color = UITheme.SURFACE_BORDER
	sb.set_border_width_all(2)
	var corner := corner_radius if corner_radius >= 0 else int(minf(BADGE_SIZE.x, BADGE_SIZE.y) * 0.5)
	sb.set_corner_radius_all(corner)
	badge.add_theme_stylebox_override("panel", sb)
	var label := Label.new()
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.text = initial
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", UITheme.TEXT_ON_SURFACE)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_child(label)
	return badge


func follow_cursor(viewport: Viewport) -> void:
	if _snapping:
		return
	position = viewport.get_mouse_position() - size * 0.5


func snap_to(target_global_pos: Vector2, callback: Callable, reduced_motion: bool = false) -> void:
	_snapping = true
	if reduced_motion:
		queue_free()
		callback.call()
		return
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(self, "global_position", target_global_pos - size * 0.5, 0.16) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	t.tween_property(self, "scale", Vector2(0.4, 0.4), 0.16).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "modulate:a", 0.0, 0.14).set_ease(Tween.EASE_IN)
	t.chain().tween_callback(func() -> void:
		queue_free()
		callback.call()
	)
