class_name CozyStripeBackground extends ColorRect
## Reusable full-screen linen-style diagonal stripes (UITheme cream palette).
## Instance `scenes/ui/cozy_stripe_background.tscn` or attach this script to a ColorRect.

const _SHADER := preload("res://shaders/scrolling_line_background.gdshader")

## Lighter stripe (defaults to canvas cream).
@export var color_one: Color = UITheme.CANVAS
## Slightly warmer/darker cream for contrast.
@export var color_two: Color = Color("#E8E0D4")
@export_range(-180.0, 180.0) var stripe_angle: float = 20.0
@export_range(4.0, 40.0) var line_count: float = 10.0
@export_range(0.0, 20.0) var scroll_speed: float = 1.5
## Stripe edge softness — 0 = hard edge, higher = softer blend.
@export_range(0.0, 0.5) var stripe_blur: float = 0.06


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
	color = UITheme.CANVAS
	_apply_shader()


func _apply_shader() -> void:
	if OS.has_feature("web"):
		material = null
		color = color_one
		return
	var mat := ShaderMaterial.new()
	mat.shader = _SHADER
	mat.set_shader_parameter("color_one", color_one)
	mat.set_shader_parameter("color_two", color_two)
	mat.set_shader_parameter("angle", stripe_angle)
	mat.set_shader_parameter("line_count", line_count)
	mat.set_shader_parameter("speed", scroll_speed)
	mat.set_shader_parameter("blur", stripe_blur)
	material = mat
