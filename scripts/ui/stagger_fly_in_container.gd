class_name StaggerFlyInContainer extends VBoxContainer
## Staggers a fly-in from the left on each animatable child Control.

signal finished

@export var fly_offset: float = 56.0
@export var stagger: float = 0.07
@export var duration: float = 0.24
@export var play_on_ready: bool = false
@export var skip_empty_controls: bool = true
@export var auto_wrap_children: bool = true

var _tween: Tween
var _wrapped: bool = false


func _ready() -> void:
	if play_on_ready:
		play_fly_in()


func play_fly_in() -> void:
	_kill_tween()
	if auto_wrap_children:
		_wrap_children()
	var slots := _gather_slots()
	if slots.is_empty():
		finished.emit()
		return
	await get_tree().process_frame
	for slot in slots:
		slot._sync_minimum_size()
		slot._layout_pan()
	for slot in slots:
		slot.prepare_fly_in(fly_offset)
	await get_tree().process_frame
	_tween = create_tween().set_parallel(true)
	for i in slots.size():
		slots[i].tween_fly_in(_tween, duration, float(i) * stagger)
	await _tween.finished
	finished.emit()


func reset_targets() -> void:
	if auto_wrap_children:
		_wrap_children()
	for slot in _gather_slots():
		slot.prepare_fly_in(fly_offset)


func _wrap_children() -> void:
	if _wrapped:
		return
	var to_wrap: Array[Control] = []
	for child in get_children():
		if child is StaggerFlyInSlot:
			continue
		if child is Control and _should_animate(child as Control):
			to_wrap.append(child as Control)
	for ctrl in to_wrap:
		var slot := StaggerFlyInSlot.new()
		slot.size_flags_vertical = ctrl.size_flags_vertical
		var idx := ctrl.get_index()
		remove_child(ctrl)
		add_child(slot)
		move_child(slot, idx)
		slot.wrap(ctrl)
	_wrapped = true


func _gather_slots() -> Array[StaggerFlyInSlot]:
	var slots: Array[StaggerFlyInSlot] = []
	for child in get_children():
		if child is StaggerFlyInSlot:
			slots.append(child as StaggerFlyInSlot)
	return slots


func _should_animate(ctrl: Control) -> bool:
	if skip_empty_controls and ctrl.get_child_count() == 0 \
			and ctrl.custom_minimum_size.y > 0.0 \
			and ctrl.custom_minimum_size.x <= 0.0:
		return false
	return true


func _kill_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null
