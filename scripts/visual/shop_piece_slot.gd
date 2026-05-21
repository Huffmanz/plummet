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

var reduced_motion: bool = false

var _morph_tween: Tween
var _badge_pop_tween: Tween
var _remove_hover_tween: Tween


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
	_remove_btn.mouse_entered.connect(_on_remove_hover_in)
	_remove_btn.mouse_exited.connect(_on_remove_hover_out)
	_remove_btn.pressed.connect(_on_remove_pressed)
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


func play_attach_juice(kind: String) -> void:
	match kind:
		"modifier":
			play_modifier_attach_juice()
		"piece_type":
			play_piece_type_morph_juice()


func play_modifier_attach_juice() -> void:
	if reduced_motion or _modifier_id.is_empty() or _mod_badge == null:
		return
	_pop_modifier_badge()


func play_piece_type_morph_juice() -> void:
	if reduced_motion:
		return
	_play_type_morph()


func set_drop_highlight(on: bool) -> void:
	_drop_highlight = on
	if _drop_ring != null and _drop_ring.has_method("set_active"):
		_drop_ring.set_active(on)


func is_drop_highlight_active() -> bool:
	return _drop_highlight


func set_remove_enabled(enabled: bool) -> void:
	_remove_btn.disabled = not enabled


# --- Piece type morph (offer-card scale tween on self) ---

func _play_type_morph() -> void:
	if _morph_tween != null and _morph_tween.is_valid():
		_morph_tween.kill()
	if reduced_motion:
		return
	_sync_pivot()
	scale = Vector2.ONE
	_morph_tween = create_tween()
	_morph_tween.tween_property(self, "scale", Vector2(1.1, 0.85), 0.06) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_morph_tween.tween_callback(func() -> void:
		if _preview != null:
			_preview.flash_type_change()
	)
	_morph_tween.tween_property(self, "scale", Vector2.ONE, 0.12) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


# --- Modifier badge pop ---

func _pop_modifier_badge() -> void:
	if _mod_badge == null:
		return
	if _badge_pop_tween != null and _badge_pop_tween.is_valid():
		_badge_pop_tween.kill()
	_mod_badge.pivot_offset = _mod_badge.size * 0.5
	_mod_badge.scale = Vector2(0.3, 0.3)
	_mod_badge.modulate = Color.WHITE
	_badge_pop_tween = create_tween()
	_badge_pop_tween.tween_property(_mod_badge, "scale", Vector2(1.15, 1.15), 0.1) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_badge_pop_tween.tween_property(_mod_badge, "scale", Vector2.ONE, 0.08) \
		.set_ease(Tween.EASE_OUT)


func _play_modifier_remove_out(on_complete: Callable) -> void:
	if _mod_badge == null:
		on_complete.call()
		return
	if _badge_pop_tween != null and _badge_pop_tween.is_valid():
		_badge_pop_tween.kill()
	_mod_badge.pivot_offset = _mod_badge.size * 0.5
	var t := create_tween().set_parallel(true)
	t.tween_property(_mod_badge, "scale", Vector2.ZERO, 0.12) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	t.tween_property(_mod_badge, "modulate:a", 0.0, 0.12).set_ease(Tween.EASE_IN)
	t.set_parallel(false)
	t.tween_callback(func() -> void:
		if _mod_badge != null:
			_mod_badge.queue_free()
			_mod_badge = null
		on_complete.call()
	)


# --- Remove button hover ---

func _on_remove_hover_in() -> void:
	if _remove_btn.disabled:
		return
	if _remove_hover_tween != null and _remove_hover_tween.is_valid():
		_remove_hover_tween.kill()
	_remove_btn.pivot_offset = _remove_btn.size * 0.5
	_remove_hover_tween = create_tween()
	_remove_hover_tween.tween_property(_remove_btn, "scale", Vector2(1.1, 1.1), 0.14) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)


func _on_remove_hover_out() -> void:
	if _remove_btn.disabled:
		return
	if _remove_hover_tween != null and _remove_hover_tween.is_valid():
		_remove_hover_tween.kill()
	_remove_hover_tween = null
	var t := create_tween()
	t.tween_property(_remove_btn, "scale", Vector2.ONE, 0.1).set_ease(Tween.EASE_OUT)


func _sync_pivot() -> void:
	pivot_offset = size * 0.5


func _on_resized() -> void:
	if _modifier_id.is_empty():
		return
	_update_modifier_icon(_modifier_id)
	_remove_btn.pivot_offset = _remove_btn.size * 0.5


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
	_mod_badge.scale = Vector2.ONE
	_mod_badge.modulate = Color.WHITE
	_mod_host.add_child(_mod_badge)


func _on_mouse_entered() -> void:
	if _has_modifier:
		_remove_btn.visible = true


func _on_mouse_exited() -> void:
	_remove_btn.visible = false


func _on_remove_pressed() -> void:
	if _remove_btn.disabled:
		return
	if reduced_motion:
		remove_pressed.emit(piece_index)
		return
	if _remove_hover_tween != null and _remove_hover_tween.is_valid():
		_remove_hover_tween.kill()
	_remove_btn.pivot_offset = _remove_btn.size * 0.5
	var press := create_tween()
	press.tween_property(_remove_btn, "scale", Vector2(0.9, 0.9), 0.05) \
		.set_ease(Tween.EASE_OUT)
	press.tween_property(_remove_btn, "scale", Vector2.ONE, 0.06)
	press.tween_callback(func() -> void:
		_play_modifier_remove_out(func() -> void:
			remove_pressed.emit(piece_index)
		)
	)


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
