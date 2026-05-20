class_name WinConfetti extends Node2D
## Victory confetti: two diagonal bursts from center, then rain from above.

const _BURST_ANGLE_A_DEG: float = -135.0
const _BURST_ANGLE_B_DEG: float = -45.0

@export var burst_amount: int = 72
@export var burst_spread_deg: float = 22.0
@export var burst_speed_min: float = 260.0
@export var burst_speed_max: float = 420.0
@export var gravity: Vector2 = Vector2(0.0, 520.0)
@export var rain_delay: float = 0.35
@export var rain_duration: float = 2.4
@export var rain_amount_per_sec: int = 28

var _bursts: Array[CPUParticles2D] = []
var _rain: CPUParticles2D
var _rain_stop_timer: SceneTreeTimer


func _ready() -> void:
	for angle_deg: float in [_BURST_ANGLE_A_DEG, _BURST_ANGLE_B_DEG]:
		var burst := _make_burst_emitter(angle_deg)
		add_child(burst)
		_bursts.append(burst)
	_rain = _make_rain_emitter()
	add_child(_rain)
	_stop_all()


func stop() -> void:
	if _rain_stop_timer != null and is_inside_tree():
		if _rain_stop_timer.timeout.is_connected(_stop_rain):
			_rain_stop_timer.timeout.disconnect(_stop_rain)
	_rain_stop_timer = null
	_stop_all()


func play() -> void:
	stop()
	var center := _screen_center()
	position = center
	for burst: CPUParticles2D in _bursts:
		burst.position = Vector2.ZERO
		burst.restart()
		burst.emitting = true
	_schedule_rain(center)


func _schedule_rain(center: Vector2) -> void:
	if _rain_stop_timer != null and _rain_stop_timer.time_left > 0.0:
		_rain_stop_timer.timeout.disconnect(_stop_rain)
	_rain.position = Vector2(0.0, -center.y - 16.0)
	_rain.emission_rect_extents = Vector2(
		maxf(120.0, center.x * 1.05), 4.0
	)
	get_tree().create_timer(rain_delay).timeout.connect(_start_rain, CONNECT_ONE_SHOT)
	_rain_stop_timer = get_tree().create_timer(rain_delay + rain_duration)
	_rain_stop_timer.timeout.connect(_stop_rain, CONNECT_ONE_SHOT)


func _start_rain() -> void:
	if _rain == null:
		return
	_rain.emitting = true


func _stop_rain() -> void:
	if _rain != null:
		_rain.emitting = false


func _stop_all() -> void:
	for burst: CPUParticles2D in _bursts:
		burst.emitting = false
	_stop_rain()


func _screen_center() -> Vector2:
	var parent_ctrl := get_parent() as Control
	if parent_ctrl != null and parent_ctrl.size.x > 0.0:
		return parent_ctrl.size * 0.5
	return get_viewport_rect().size * 0.5


func _make_burst_emitter(angle_deg: float) -> CPUParticles2D:
	var particles := CPUParticles2D.new()
	particles.emitting = false
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = burst_amount
	particles.lifetime = 3.2
	particles.preprocess = 0.0
	particles.speed_scale = 1.0
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_POINT
	particles.direction = Vector2.from_angle(deg_to_rad(angle_deg))
	particles.spread = burst_spread_deg
	particles.initial_velocity_min = burst_speed_min
	particles.initial_velocity_max = burst_speed_max
	particles.gravity = gravity
	particles.scale_amount_min = 3.0
	particles.scale_amount_max = 7.0
	particles.angular_velocity_min = -360.0
	particles.angular_velocity_max = 360.0
	particles.hue_variation_min = -0.05
	particles.hue_variation_max = 0.08
	particles.color = _confetti_colors()[0]
	particles.color_ramp = _make_color_ramp()
	return particles


func _make_rain_emitter() -> CPUParticles2D:
	var particles := CPUParticles2D.new()
	particles.emitting = false
	particles.one_shot = false
	particles.lifetime = 2.8
	particles.amount = maxi(32, int(rain_amount_per_sec * particles.lifetime))
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = Vector2(200.0, 4.0)
	particles.direction = Vector2.DOWN
	particles.spread = 38.0
	particles.initial_velocity_min = 80.0
	particles.initial_velocity_max = 160.0
	particles.gravity = gravity * 0.85
	particles.scale_amount_min = 2.5
	particles.scale_amount_max = 6.0
	particles.angular_velocity_min = -240.0
	particles.angular_velocity_max = 240.0
	particles.hue_variation_min = -0.06
	particles.hue_variation_max = 0.1
	particles.color = _confetti_colors()[0]
	particles.color_ramp = _make_color_ramp()
	return particles


func _confetti_colors() -> Array[Color]:
	return [
		UITheme.ACCENT_POP,
		UITheme.ACCENT,
		UITheme.PLAYER,
		UITheme.AI,
		UITheme.DANGER,
		UITheme.SURFACE_BORDER,
		UITheme.VICTORY,
	]


func _make_color_ramp() -> Gradient:
	var colors := _confetti_colors()
	var ramp := Gradient.new()
	var n := colors.size()
	for i in n:
		var t := float(i) / float(n - 1) if n > 1 else 0.0
		ramp.add_point(t, colors[i])
	return ramp
