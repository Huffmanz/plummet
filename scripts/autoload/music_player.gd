extends Node
## Global background music. Autoload scene: `scenes/autoload/music_player.tscn`

const _TRACK: AudioStream = preload("res://assets/sfx/Daytime2Loop.wav")

@export var volume_db: float = -8.0

@onready var _player: AudioStreamPlayer = $Player

var muted: bool = false


func _ready() -> void:
	_player.bus = &"music"
	_player.volume_db = volume_db
	_player.stream = _looping_stream()
	play()


func play() -> void:
	if muted or _player.stream == null:
		return
	if not _player.playing:
		_player.play()


func stop() -> void:
	_player.stop()


func set_muted(value: bool) -> void:
	muted = value
	if muted:
		_player.stop()
	else:
		play()


func _looping_stream() -> AudioStream:
	var wav := _TRACK.duplicate() as AudioStreamWAV
	if wav != null:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		return wav
	return _TRACK
