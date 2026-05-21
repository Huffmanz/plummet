extends Node
## Themed hover tooltips. Bind any Control; walks up the tree so child hits still count.
##
##   GameTooltip.bind(my_button, "Effect text here.")
##   GameTooltip.unbind(my_button)
##
## Or attach a TooltipTarget child node with exported text.

const MAX_WIDTH := 176.0
const SHOW_DELAY := 0.35
const CURSOR_OFFSET := Vector2(14.0, 18.0)
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
		_panel.reset_size()
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
	_panel.reset_size()


func _hide() -> void:
	_shown_target = null
	_panel.visible = false


func _position_panel(vp: Viewport) -> void:
	var mouse := vp.get_mouse_position()
	var panel_size := _panel.size
	var pos := mouse + CURSOR_OFFSET

	if pos.x + panel_size.x > vp.size.x - VIEWPORT_MARGIN:
		pos.x = mouse.x - panel_size.x - 8.0
	if pos.y + panel_size.y > vp.size.y - VIEWPORT_MARGIN:
		pos.y = mouse.y - panel_size.y - 8.0

	pos.x = clampf(pos.x, VIEWPORT_MARGIN, vp.size.x - panel_size.x - VIEWPORT_MARGIN)
	pos.y = clampf(pos.y, VIEWPORT_MARGIN, vp.size.y - panel_size.y - VIEWPORT_MARGIN)
	_panel.position = pos
