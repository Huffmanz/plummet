class_name ShopPieceSlot extends Control

signal remove_pressed(piece_index: int)
signal slot_clicked(piece_index: int)
signal offer_dropped(piece_index: int, data: Dictionary)

@onready var _preview: ShopPiecePreview = %PiecePreview
@onready var _mod_host: CenterContainer = %ModIconHost
@onready var _drop_ring: Control = %DropRing
@onready var _remove_btn: Button = %RemoveBtn

var piece_index: int = 0
var _has_modifier: bool = false
var _modifier_id: String = ""
var _drop_highlight: bool = false
var _mod_badge: ModifierIconBadge = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_remove_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	UITheme.style_button(_remove_btn, UITheme.DANGER, UITheme.DANGER.lightened(0.08))
	if _preview:
		_preview.mouse_filter = Control.MOUSE_FILTER_PASS
	if _mod_host:
		_mod_host.mouse_filter = Control.MOUSE_FILTER_PASS
	if _drop_ring:
		_drop_ring.mouse_filter = Control.MOUSE_FILTER_PASS
		_drop_ring.visible = false
	resized.connect(_on_resized)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	_remove_btn.pressed.connect(func(): remove_pressed.emit(piece_index))
	gui_input.connect(_on_gui_input)


func setup(index: int, piece: Piece) -> void:
	piece_index = index
	_has_modifier = not piece.modifier.is_empty()
	if not is_node_ready():
		await ready
	_preview.setup(piece)
	_update_modifier_icon(piece.modifier)
	if _drop_ring != null and _drop_ring.has_method("set_active"):
		_drop_ring.set_active(_drop_highlight)


func set_drop_highlight(on: bool) -> void:
	_drop_highlight = on
	if _drop_ring != null and _drop_ring.has_method("set_active"):
		_drop_ring.set_active(on)


func set_remove_enabled(enabled: bool) -> void:
	_remove_btn.disabled = not enabled


func _on_resized() -> void:
	if _modifier_id.is_empty():
		return
	_update_modifier_icon(_modifier_id)


func _update_modifier_icon(modifier_id: String) -> void:
	_modifier_id = modifier_id
	if _mod_badge != null:
		_mod_badge.queue_free()
		_mod_badge = null
	if modifier_id.is_empty():
		return
	var side := minf(size.x, size.y) * 0.42
	var badge_size := Vector2(side, side)
	_mod_badge = ModifierIconBadge.create_for_modifier(modifier_id, badge_size)
	_mod_host.add_child(_mod_badge)


func _on_mouse_entered() -> void:
	if _has_modifier:
		_remove_btn.visible = true


func _on_mouse_exited() -> void:
	_remove_btn.visible = false


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false
	var kind: String = data.get("kind", "")
	if kind == "modifier":
		return not _has_modifier
	if kind == "piece_type":
		return true
	return false


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if not _can_drop_data(_at_position, data):
		return
	offer_dropped.emit(piece_index, data)
	get_viewport().set_input_as_handled()


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed and not mb.double_click:
			slot_clicked.emit(piece_index)


