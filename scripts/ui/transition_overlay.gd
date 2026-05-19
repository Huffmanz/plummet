@tool
class_name TransitionOverlayRect extends ColorRect
## Full-screen wipe overlay. Scrub `preview_progress` in the inspector (0 = revealed, 1 = covered).

@export_range(0.0, 1.0, 0.001) var preview_progress: float = 0.0:
	set(value):
		preview_progress = value
		_apply_progress_to_shader()


func _ready() -> void:
	_apply_progress_to_shader()


func set_progress(value: float) -> void:
	preview_progress = value
	_apply_progress_to_shader()


func get_progress() -> float:
	return preview_progress


func _apply_progress_to_shader() -> void:
	var mat := material as ShaderMaterial
	if mat == null:
		return
	mat.set_shader_parameter("progress", preview_progress)
