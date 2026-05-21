class_name ShopPieceSlot extends Control

signal offer_dropped(piece_index: int, data: Dictionary)

@onready var _preview: ShopPiecePreview = %PiecePreview
@onready var _mod_host: CenterContainer = %ModIconHost
@onready var _drop_ring: Control = %DropRing

var piece_index: int = 0
var _has_modifier: bool = false
var _modifier_id: String = ""
var _drop_highlight: bool = false
var _mod_badge: ModifierIconBadge = null

var reduced_motion: bool = false

var _morph_tween: Tween
var _badge_pop_tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	if _preview:
		_preview.mouse_filter = Control.MOUSE_FILTER_PASS
	if _mod_host:
		_mod_host.mouse_filter = Control.MOUSE_FILTER_PASS
	if _drop_ring:
		_drop_ring.mouse_filter = Control.MOUSE_FILTER_PASS
		_drop_ring.visible = false
	resized.connect(_on_resized)


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


func _sync_pivot() -> void:
	pivot_offset = size * 0.5


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
	_mod_badge.scale = Vector2.ONE
	_mod_badge.modulate = Color.WHITE
	_mod_host.add_child(_mod_badge)


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
