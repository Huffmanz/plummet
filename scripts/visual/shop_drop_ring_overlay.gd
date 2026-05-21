extends Control
## Rotating dashed drop ring — drawn above piece preview and modifier badge.

const ROT_SPEED := 0.55  # radians per second

var _active: bool = false
var _angle: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func set_active(on: bool) -> void:
	if _active == on:
		return
	_active = on
	visible = on
	set_process(on)
	if on:
		queue_redraw()


func _process(delta: float) -> void:
	if not _active:
		return
	_angle = fmod(_angle + delta * ROT_SPEED, TAU)
	queue_redraw()


func _draw() -> void:
	if not _active:
		return
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.45
	UITheme.draw_dashed_circle(self, center, radius, UITheme.ACCENT, 5.0, 12, 0.58, _angle)
