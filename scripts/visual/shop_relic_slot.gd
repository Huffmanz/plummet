class_name ShopRelicSlot extends PanelContainer

signal relic_dropped(slot_index: int, data: Dictionary)

@onready var _icon: ColorRect = %Icon
@onready var _name_lbl: Label = %NameLabel
@onready var _summary_lbl: Label = %SummaryLabel
@onready var _empty_lbl: Label = %EmptyLabel

var slot_index: int = 0
var _occupied: bool = false
var _drop_highlight: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_ignore_mouse_on_children(self)


func is_occupied() -> bool:
	return _occupied


func can_accept_relic_drop() -> bool:
	return not _occupied


func setup(index: int, relic_id: String) -> void:
	slot_index = index
	_occupied = not relic_id.is_empty()
	if _occupied:
		var rd: RelicData = DataRegistry.get_relic(relic_id)
		_name_lbl.text = rd.display_name if rd else relic_id
		_summary_lbl.text = rd.description if rd else ""
		_icon.color = ShopOfferCard.RELIC_BORDER
		_icon.visible = true
		_name_lbl.visible = true
		_summary_lbl.visible = true
		_empty_lbl.visible = false
		add_theme_stylebox_override("panel", UITheme.make_surface_style(8, UITheme.SURFACE_LIGHT))
	else:
		_icon.visible = false
		_name_lbl.visible = false
		_summary_lbl.visible = false
		_empty_lbl.visible = true
		_apply_empty_style()
	_update_highlight()


func set_drop_highlight(on: bool) -> void:
	_drop_highlight = on
	_update_highlight()


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


func _ignore_mouse_on_children(node: Node) -> void:
	# PASS so drags hit this slot; IGNORE would pass through to controls behind.
	for child in node.get_children():
		if child is Control:
			(child as Control).mouse_filter = Control.MOUSE_FILTER_PASS
		_ignore_mouse_on_children(child)
