class_name RandomAudioPlayer extends AudioStreamPlayer
## Plays a random stream from an exported list with optional pitch variation.

@export var streams: Array[AudioStream] = []
@export var randomize_pitch: bool = true
@export var min_pitch: float = 0.9
@export var max_pitch: float = 1.1
@export var overlapping_volume_db: float = -10.0


func play_random() -> void:
	play_random_from(streams)


## Plays on a temporary child player so overlapping calls are all audible.
func play_random_overlapping(parent: Node) -> void:
	play_random_overlapping_from(parent, streams)


func play_random_overlapping_from(parent: Node, source: Array[AudioStream]) -> void:
	play_random_overlapping_static(
		parent, source, bus, volume_db, overlapping_volume_db, randomize_pitch, min_pitch, max_pitch
	)


static func play_random_overlapping_static(
	parent: Node,
	source: Array[AudioStream],
	bus_name: StringName = &"Master",
	base_volume_db: float = 0.0,
	overlapping_volume_db: float = -10.0,
	randomize_pitch: bool = true,
	min_pitch: float = 0.9,
	max_pitch: float = 1.1
) -> void:
	var picked := pick_random_stream(source)
	if picked == null:
		return
	var host: Node = parent
	if parent != null and parent.is_inside_tree():
		host = parent.get_tree().root
	elif parent == null:
		return
	var player := AudioStreamPlayer.new()
	player.stream = picked
	player.bus = bus_name
	player.volume_db = base_volume_db + overlapping_volume_db
	if randomize_pitch:
		player.pitch_scale = randf_range(min_pitch, max_pitch)
	host.add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


func play_random_from(source: Array[AudioStream]) -> void:
	var picked := _pick_random_stream(source)
	if picked == null:
		return
	stream = picked
	_apply_pitch()
	play()


static func pick_random_stream(source: Array[AudioStream]) -> AudioStream:
	if source == null or source.is_empty():
		return null
	var candidates: Array[AudioStream] = []
	for entry in source:
		if entry != null:
			candidates.append(entry)
	if candidates.is_empty():
		return null
	return candidates[randi() % candidates.size()]


func _pick_random_stream(source: Array[AudioStream]) -> AudioStream:
	return pick_random_stream(source)


func _apply_pitch() -> void:
	if randomize_pitch:
		pitch_scale = randf_range(min_pitch, max_pitch)
	else:
		pitch_scale = 1.0
