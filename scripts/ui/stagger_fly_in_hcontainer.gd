class_name StaggerFlyInHContainer extends HBoxContainer
## Staggers a fly-in from the right on each animatable child Control.
## Rightmost child animates first; wraps children in StaggerFlyInSlot clip/pan nodes.

signal finished

const _DEFAULT_SLIDE_STREAM: AudioStream = preload(
	"res://assets/sfx/571581__el_boss__playing-card-slide-right.wav"
)
const _DEFAULT_PAN_POP_STREAMS: Array[AudioStream] = [
	preload("res://assets/sfx/kenney_impact-sounds/Audio/impactGeneric_light_000.ogg"),
	preload("res://assets/sfx/kenney_impact-sounds/Audio/impactGeneric_light_001.ogg"),
	preload("res://assets/sfx/kenney_impact-sounds/Audio/impactGeneric_light_002.ogg"),
	preload("res://assets/sfx/kenney_impact-sounds/Audio/impactGeneric_light_003.ogg"),
	preload("res://assets/sfx/kenney_impact-sounds/Audio/impactGeneric_light_004.ogg"),
]

@export var fly_offset: float = 56.0
@export var stagger: float = 0.09
@export var duration: float = 0.22
@export var play_on_ready: bool = false
@export var play_slide_sfx: bool = true
@export var slide_streams: Array[AudioStream] = []
@export var slide_min_pitch: float = 0.88
@export var slide_max_pitch: float = 1.12
@export var slide_volume_db: float = -4.0
@export var play_pan_pop: bool = true
@export var pan_pop_duration: float = 0.22
@export var pan_pop_overshoot: float = 1.1
@export var play_pan_pop_sfx: bool = true
@export var pan_pop_streams: Array[AudioStream] = []
@export var pan_pop_min_pitch: float = 0.92
@export var pan_pop_max_pitch: float = 1.08
@export var pan_pop_volume_db: float = 0.0
@export var reduced_motion: bool = false

var _tween: Tween
var _slide_sfx: RandomAudioPlayer
var _pan_pop_sfx: RandomAudioPlayer


func _ready() -> void:
	_setup_slide_sfx()
	_setup_pan_pop_sfx()
	if play_on_ready:
		play_fly_in()


func play_fly_in() -> void:
	if reduced_motion:
		skip_animation_show_all()
		finished.emit()
		return
	await prepare_fly_in()
	await run_fly_in_tween()


## Unwrap fly-in slots and force full opacity (web / reduced motion).
func skip_animation_show_all() -> void:
	_kill_tween()
	for child in get_children().duplicate():
		if child is StaggerFlyInSlot:
			(child as StaggerFlyInSlot).reveal_immediately()
	_unwrap_children()
	for child in get_children():
		if child is Control:
			var ctrl := child as Control
			ctrl.modulate = Color.WHITE
			ctrl.scale = Vector2.ONE


func prepare_fly_in() -> void:
	if reduced_motion:
		return
	_kill_tween()
	_unwrap_children()
	await get_tree().process_frame
	_wrap_children()
	var slots := _gather_animatable_slots()
	if slots.is_empty():
		skip_animation_show_all()
		return
	await get_tree().process_frame
	for slot in slots:
		slot._sync_minimum_size()
		slot._layout_pan()
	for slot in slots:
		slot.prepare_fly_in_right(fly_offset)
		if play_pan_pop:
			slot.prepare_pan_pop()


func run_fly_in_tween() -> void:
	if reduced_motion:
		skip_animation_show_all()
		finished.emit()
		return
	var slots := _gather_animatable_slots()
	if slots.is_empty():
		skip_animation_show_all()
		finished.emit()
		return
	_tween = create_tween().set_parallel(true)
	var count := slots.size()
	for i in count:
		var reversed_i := count - 1 - i
		var delay := float(reversed_i) * stagger
		if play_slide_sfx:
			_tween.tween_callback(_play_row_slide_sfx).set_delay(delay)
		slots[i].tween_fly_in(_tween, duration, delay)
		if play_pan_pop:
			slots[i].tween_pan_pop(_tween, duration, delay, pan_pop_duration, pan_pop_overshoot)
			if play_pan_pop_sfx:
				_tween.tween_callback(_play_pan_pop_sfx).set_delay(delay + duration)
	await _tween.finished
	for slot in slots:
		slot.clear_fly_in_prep()
	finished.emit()


func _unwrap_children() -> void:
	for child in get_children().duplicate():
		if not (child is StaggerFlyInSlot):
			continue
		var slot := child as StaggerFlyInSlot
		var content := slot.get_content()
		var idx := slot.get_index()
		if content != null:
			var content_parent := content.get_parent()
			if content_parent != null:
				content_parent.remove_child(content)
		remove_child(slot)
		slot.free()
		if content == null:
			continue
		add_child(content)
		move_child(content, idx)


func _wrap_children() -> void:
	for child in get_children().duplicate():
		if child is StaggerFlyInSlot:
			continue
		if not (child is Control):
			continue
		var ctrl := child as Control
		if not ctrl.visible:
			continue
		var slot := StaggerFlyInSlot.new()
		slot.size_flags_horizontal = ctrl.size_flags_horizontal
		slot.size_flags_vertical = ctrl.size_flags_vertical
		var idx := ctrl.get_index()
		remove_child(ctrl)
		add_child(slot)
		move_child(slot, idx)
		slot.wrap(ctrl)


func _gather_animatable_slots() -> Array[StaggerFlyInSlot]:
	var slots: Array[StaggerFlyInSlot] = []
	for child in get_children():
		if not (child is StaggerFlyInSlot):
			continue
		var slot := child as StaggerFlyInSlot
		var content := slot.get_content()
		if content == null or not content.visible:
			continue
		slots.append(slot)
	return slots


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


func _setup_pan_pop_sfx() -> void:
	_pan_pop_sfx = get_node_or_null("PanPopSfx") as RandomAudioPlayer
	if _pan_pop_sfx == null and play_pan_pop_sfx:
		_pan_pop_sfx = (
			preload("res://scenes/audio/random_audio_player.tscn").instantiate()
			as RandomAudioPlayer
		)
		_pan_pop_sfx.name = "PanPopSfx"
		add_child(_pan_pop_sfx)
	if _pan_pop_sfx == null:
		return
	_pan_pop_sfx.bus = &"sfx"
	_pan_pop_sfx.volume_db = pan_pop_volume_db
	_pan_pop_sfx.randomize_pitch = true
	_pan_pop_sfx.min_pitch = pan_pop_min_pitch
	_pan_pop_sfx.max_pitch = pan_pop_max_pitch
	if not pan_pop_streams.is_empty():
		_pan_pop_sfx.streams = pan_pop_streams
	elif _pan_pop_sfx.streams.is_empty():
		_pan_pop_sfx.streams = _DEFAULT_PAN_POP_STREAMS


func _play_pan_pop_sfx() -> void:
	if not play_pan_pop_sfx or _pan_pop_sfx == null:
		return
	_pan_pop_sfx.play_random_overlapping(self)
