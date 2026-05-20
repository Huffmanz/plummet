class_name StaggerFlyInContainer extends VBoxContainer
## Staggers a fly-in from the left on each animatable child Control.

signal finished

const _DEFAULT_SLIDE_STREAM: AudioStream = preload(
	"res://assets/sfx/571581__el_boss__playing-card-slide-right.wav"
)
const _DEFAULT_VALUE_POP_STREAMS: Array[AudioStream] = [
	preload("res://assets/sfx/kenney_impact-sounds/Audio/impactGeneric_light_000.ogg"),
	preload("res://assets/sfx/kenney_impact-sounds/Audio/impactGeneric_light_001.ogg"),
	preload("res://assets/sfx/kenney_impact-sounds/Audio/impactGeneric_light_002.ogg"),
	preload("res://assets/sfx/kenney_impact-sounds/Audio/impactGeneric_light_003.ogg"),
	preload("res://assets/sfx/kenney_impact-sounds/Audio/impactGeneric_light_004.ogg"),
]

@export var fly_offset: float = 56.0
@export var stagger: float = 0.07
@export var duration: float = 0.24
@export var play_on_ready: bool = false
@export var skip_empty_controls: bool = true
@export var auto_wrap_children: bool = true
@export var play_slide_sfx: bool = true
@export var slide_streams: Array[AudioStream] = []
@export var slide_min_pitch: float = 0.88
@export var slide_max_pitch: float = 1.12
@export var slide_volume_db: float = -4.0
@export var play_value_pop: bool = true
@export var value_pop_duration: float = 0.2
@export var value_pop_overshoot: float = 1.18
@export var play_value_pop_sfx: bool = true
@export var value_pop_streams: Array[AudioStream] = []
@export var value_pop_min_pitch: float = 0.92
@export var value_pop_max_pitch: float = 1.08
@export var value_pop_volume_db: float = 0.0

var _tween: Tween
var _wrapped: bool = false
var _slide_sfx: RandomAudioPlayer
var _value_pop_sfx: RandomAudioPlayer


func _ready() -> void:
	_setup_slide_sfx()
	_setup_value_pop_sfx()
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
		if play_value_pop:
			slot.prepare_value_pop()
	await get_tree().process_frame
	_tween = create_tween().set_parallel(true)
	for i in slots.size():
		var delay := float(i) * stagger
		if play_slide_sfx:
			_tween.tween_callback(_play_row_slide_sfx).set_delay(delay)
		slots[i].tween_fly_in(_tween, duration, delay)
		if play_value_pop:
			slots[i].tween_value_pop(
				_tween, duration, delay, value_pop_duration, value_pop_overshoot
			)
			if play_value_pop_sfx and slots[i].has_value_pop_target():
				var pop_delay := delay + duration
				_tween.tween_callback(_play_value_pop_sfx).set_delay(pop_delay)
	await _tween.finished
	finished.emit()


func reset_targets() -> void:
	if auto_wrap_children:
		_wrap_children()
	for slot in _gather_slots():
		slot.reset_value_pop()
		slot.prepare_fly_in(fly_offset)
		if play_value_pop:
			slot.prepare_value_pop()


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


func _setup_slide_sfx() -> void:
	_slide_sfx = get_node_or_null("SlideSfx") as RandomAudioPlayer
	if _slide_sfx == null and play_slide_sfx:
		_slide_sfx = (
			preload("res://scenes/audio/random_audio_player.tscn").instantiate()
			as RandomAudioPlayer
		)
		_slide_sfx.name = "SlideSfx"
		add_child(_slide_sfx)
	if _slide_sfx == null:
		return
	_slide_sfx.bus = &"sfx"
	_slide_sfx.volume_db = slide_volume_db
	_slide_sfx.randomize_pitch = true
	_slide_sfx.min_pitch = slide_min_pitch
	_slide_sfx.max_pitch = slide_max_pitch
	if not slide_streams.is_empty():
		_slide_sfx.streams = slide_streams
	elif _slide_sfx.streams.is_empty():
		_slide_sfx.streams = [_DEFAULT_SLIDE_STREAM]


func _play_row_slide_sfx() -> void:
	if not play_slide_sfx or _slide_sfx == null:
		return
	_slide_sfx.play_random_overlapping(self)


func _setup_value_pop_sfx() -> void:
	_value_pop_sfx = get_node_or_null("ValuePopSfx") as RandomAudioPlayer
	if _value_pop_sfx == null and play_value_pop_sfx:
		_value_pop_sfx = (
			preload("res://scenes/audio/random_audio_player.tscn").instantiate()
			as RandomAudioPlayer
		)
		_value_pop_sfx.name = "ValuePopSfx"
		add_child(_value_pop_sfx)
	if _value_pop_sfx == null:
		return
	_value_pop_sfx.bus = &"sfx"
	_value_pop_sfx.volume_db = value_pop_volume_db
	_value_pop_sfx.randomize_pitch = true
	_value_pop_sfx.min_pitch = value_pop_min_pitch
	_value_pop_sfx.max_pitch = value_pop_max_pitch
	if not value_pop_streams.is_empty():
		_value_pop_sfx.streams = value_pop_streams
	elif _value_pop_sfx.streams.is_empty():
		_value_pop_sfx.streams = _DEFAULT_VALUE_POP_STREAMS


func _play_value_pop_sfx() -> void:
	if not play_value_pop_sfx or _value_pop_sfx == null:
		return
	_value_pop_sfx.play_random_overlapping(self)
