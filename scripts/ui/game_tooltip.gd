extends Node
## Themed hover tooltips. Bind any Control; walks up the tree so child hits still count.
##
##   GameTooltip.bind(my_button, "Effect text here.")
##   GameTooltip.unbind(my_button)
##
## Or attach a TooltipTarget child node with exported text.

const MAX_WIDTH := 176.0
const SHOW_DELAY := 0.35
const ANCHOR_GAP := 8.0
const VIEWPORT_MARGIN := 8.0
const FONT_SIZE := 10

var _layer: CanvasLayer = null
var _panel: PanelContainer = null
var _label: Label = null

var _bindings: Dictionary = {}  # Control -> String
var _hover_target: Control = null
var _hover_time: float = 0.0
var _shown_target: Control = null


func _ready() -> void:
	_build_ui()


func bind(control: Control, text: String) -> void:
	if control == null:
		return
	if text.is_empty():
		unbind(control)
		return
	_bindings[control] = text
	control.tooltip_text = ""
	if _shown_target == control and _panel != null and _panel.visible:
		_label.text = text
		_label.reset_size()
		_panel.reset_size()
		call_deferred("_refresh_position")
	if not control.tree_exited.is_connected(_on_bound_tree_exited):
		control.tree_exited.connect(_on_bound_tree_exited.bind(control), CONNECT_ONE_SHOT)


func unbind(control: Control) -> void:
	if control == null:
		return
	_bindings.erase(control)
	if _hover_target == control:
		_hover_target = null
		_hover_time = 0.0
	if _shown_target == control:
		_hide()


func _on_bound_tree_exited(control: Control) -> void:
	unbind(control)


func _build_ui() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 120
	add_child(_layer)

	_panel = PanelContainer.new()
	_panel.visible = false
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_theme_stylebox_override("panel", UITheme.make_tooltip_style())
	_layer.add_child(_panel)

	_label = Label.new()
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.custom_minimum_size = Vector2(MAX_WIDTH, 0)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	UITheme.style_label_primary(_label, true)
	_label.add_theme_font_size_override("font_size", FONT_SIZE)
	_panel.add_child(_label)


func _process(delta: float) -> void:
	var vp := get_viewport()
	if vp == null:
		return

	var hovered := vp.gui_get_hovered_control()
	var target := _find_bound(hovered)

	if target != _hover_target:
		_hover_target = target
		_hover_time = 0.0
		if target == null:
			_hide()

	if target != null:
		_hover_time += delta
		if _hover_time >= SHOW_DELAY:
			_show(target)

	if _panel.visible:
		_position_panel(vp)


func _find_bound(control: Control) -> Control:
	var current := control
	while current != null:
		if _bindings.has(current):
			return current
		current = current.get_parent() as Control
	return null


func _show(target: Control) -> void:
	if not _bindings.has(target):
		return
	if _shown_target == target and _panel.visible:
		return
	_shown_target = target
	_label.text = _bindings[target]
	_panel.visible = true
	_label.reset_size()
	_panel.reset_size()
	call_deferred("_refresh_position")


func _refresh_position() -> void:
	var vp := get_viewport()
	if vp == null or not _panel.visible:
		return
	_position_panel(vp)


func _hide() -> void:
	_shown_target = null
	_panel.visible = false


func _position_panel(vp: Viewport) -> void:
	if _shown_target == null or not is_instance_valid(_shown_target):
		return

	_label.reset_size()
	_panel.reset_size()

	var vp_rect := vp.get_visible_rect()
	var anchor_rect := _shown_target.get_global_rect()
	var panel_size := _panel.get_minimum_size()
	if panel_size.y <= 0.0:
		panel_size = _label.get_minimum_size() + Vector2(20.0, 16.0)
	panel_size.x = maxf(panel_size.x, 1.0)
	panel_size.y = maxf(panel_size.y, 1.0)

	var space_above := anchor_rect.position.y - vp_rect.position.y - VIEWPORT_MARGIN
	var space_below := vp_rect.end.y - anchor_rect.end.y - VIEWPORT_MARGIN
	var prefer_above := space_below < panel_size.y + ANCHOR_GAP or space_above >= space_below

	var pos := Vector2.ZERO
	if prefer_above:
		pos.y = anchor_rect.position.y - panel_size.y - ANCHOR_GAP
	else:
		pos.y = anchor_rect.end.y + ANCHOR_GAP
	pos.x = anchor_rect.position.x + anchor_rect.size.x * 0.5 - panel_size.x * 0.5

	pos.x = clampf(pos.x, vp_rect.position.x + VIEWPORT_MARGIN, vp_rect.end.x - panel_size.x - VIEWPORT_MARGIN)
	pos.y = clampf(pos.y, vp_rect.position.y + VIEWPORT_MARGIN, vp_rect.end.y - panel_size.y - VIEWPORT_MARGIN)
	_panel.position = pos
