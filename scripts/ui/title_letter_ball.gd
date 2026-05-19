class_name TitleLetterBall extends Control

@export var letter: String = "P"

@onready var _label: Label = $Label

var _rest_y: float = 0.0
var _drop_tween: Tween


func _ready() -> void:
	_label.text = letter


func play_drop(delay: float, duration: float) -> void:
	if _drop_tween != null and _drop_tween.is_valid():
		_drop_tween.kill()

	await get_tree().process_frame
	_rest_y = position.y
	var drop_offset := global_position.y + size.y + 32.0
	position.y = _rest_y - drop_offset

	_drop_tween = create_tween()
	if delay > 0.0:
		_drop_tween.tween_interval(delay)
	_drop_tween.tween_property(self, "position:y", _rest_y, duration) \
		.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
