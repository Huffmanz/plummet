class_name ShopRelicSlot extends PanelContainer

signal relic_dropped(slot_index: int, data: Dictionary)

@onready var _icon: ShopOfferVisual = %ShopIcon
@onready var _name_lbl: Label = %NameLabel
@onready var _empty_lbl: Label = %EmptyLabel

var slot_index: int = 0
var _occupied: bool = false
var _drop_highlight: bool = false
var _pulse_tween: Tween = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	UITheme.style_label_primary(_name_lbl, true)
	_ignore_mouse_on_children(self)


func _exit_tree() -> void:
	GameTooltip.unbind(self)


func is_occupied() -> bool:
	return _occupied


func can_accept_relic_drop() -> bool:
	return not _occupied


func setup(index: int, relic_id: String) -> void:
	slot_index = index
	_occupied = not relic_id.is_empty()
	GameTooltip.unbind(self)
	if _occupied:
		var rd: RelicData = DataRegistry.get_relic(relic_id)
		_name_lbl.text = rd.display_name if rd else relic_id
		_icon.setup("relic", relic_id, Vector2(22, 22))
		_icon.visible = true
		_name_lbl.visible = true
		_empty_lbl.visible = false
		add_theme_stylebox_override("panel", UITheme.make_surface_style(8, UITheme.SURFACE_LIGHT))
		GameTooltip.bind(self, _tooltip_text(rd, relic_id))
	else:
		_icon.visible = false
		_name_lbl.visible = false
		_empty_lbl.visible = true
		_apply_empty_style()
	_update_highlight()


func _tooltip_text(rd: RelicData, id: String) -> String:
	if rd == null:
		return id
	return "%s\n%s" % [rd.display_name, rd.description]


func set_drop_highlight(on: bool) -> void:
	_drop_highlight = on
	_update_highlight()
	_update_pulse(on)


func is_drop_highlight_active() -> bool:
	return _drop_highlight


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if _occupied or typeof(data) != TYPE_DICTIONARY:
		return false
	return data.get("kind", "") == "relic"


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if not _can_drop_data(_at_position, data):
		return
	relic_dropped.emit(slot_index, data)
	get_viewport().set_input_as_handled()


func _apply_empty_style() -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color.TRANSPARENT
	sb.border_color = UITheme.TEXT_MUTED_ON_SURFACE
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 10.0
	sb.content_margin_right = 10.0
	sb.content_margin_top = 8.0
	sb.content_margin_bottom = 8.0
	add_theme_stylebox_override("panel", sb)


func _update_highlight() -> void:
	if _occupied:
		return
	if _drop_highlight:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(UITheme.ACCENT, 0.15)
		sb.border_color = UITheme.ACCENT
		sb.set_border_width_all(3)
		sb.set_corner_radius_all(8)
		add_theme_stylebox_override("panel", sb)
	else:
		_apply_empty_style()


func _update_pulse(on: bool) -> void:
	if _pulse_tween != null and _pulse_tween.is_valid():
		_pulse_tween.kill()
	_pulse_tween = null
	modulate = Color.WHITE
	if on and not _occupied:
		_pulse_tween = create_tween().set_loops()
		_pulse_tween.tween_property(self, "modulate", Color(1.15, 1.15, 1.15, 1.0), 0.5)
		_pulse_tween.tween_property(self, "modulate", Color.WHITE, 0.5)


func _ignore_mouse_on_children(node: Node) -> void:
	# IGNORE excludes children from hit-testing so this slot receives drops.
	for child in node.get_children():
		if child is Control:
			(child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ignore_mouse_on_children(child)
