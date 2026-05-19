class_name JuicySfxButton extends Button

@export var hover_sounds: Array[AudioStream] = []
@export var hover_volume_db: float = 0.0

@export var hover_scale: Vector2 = Vector2(1.1, 0.9)
@export var hover_rotation_deg: float = 4.0
@export var hover_duration: float = 0.14
@export var button_text: String = "Button":
	set(value):
		button_text = value
		if is_node_ready():
			_sync_label()

@onready var _audio: AudioStreamPlayer = $AudioStreamPlayer
@onready var _visual: Control = $VisualPivot
@onready var _label: Label = $VisualPivot/Label

var _rest_scale: Vector2 = Vector2.ONE
var _rest_rotation: float = 0.0
var _hover_tween: Tween


func _ready() -> void:
	_audio.volume_db = hover_volume_db
	_sync_label()
	var target := _animation_target()
	_rest_scale = target.scale
	_rest_rotation = target.rotation
	_sync_pivot()
	resized.connect(_sync_pivot)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _animation_target() -> Control:
	if _visual != null:
		return _visual
	return self


func _sync_pivot() -> void:
	var target := _animation_target()
	target.pivot_offset = target.size * 0.5


func _sync_label() -> void:
	if _label != null:
		_label.text = button_text


func _on_mouse_entered() -> void:
	_play_random_from(hover_sounds)
	_set_hovered(true)


func _on_mouse_exited() -> void:
	_set_hovered(false)


func play_random_from(streams: Array[AudioStream]) -> void:
	_play_random_from(streams)


func _play_random_from(streams: Array[AudioStream]) -> void:
	if streams == null or streams.is_empty():
		return

	var candidates: Array[AudioStream] = []
	for stream in streams:
		if stream != null:
			candidates.append(stream)
	if candidates.is_empty():
		return

	var picked: AudioStream = candidates[randi() % candidates.size()]
	if picked == null:
		return

	_audio.stream = picked
	_audio.play()


func _set_hovered(hovered: bool) -> void:
	if _hover_tween != null and _hover_tween.is_valid():
		_hover_tween.kill()

	var target := _animation_target()
	_hover_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	if hovered:
		_hover_tween.parallel().tween_property(target, "scale", hover_scale, hover_duration)
		_hover_tween.parallel().tween_property(
			target, "rotation", deg_to_rad(hover_rotation_deg), hover_duration
		)
	else:
		_hover_tween.parallel().tween_property(target, "scale", _rest_scale, hover_duration)
		_hover_tween.parallel().tween_property(target, "rotation", _rest_rotation, hover_duration)
