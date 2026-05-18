class_name EnemyPortrait extends Node2D

enum Emotion { NEUTRAL, SMUG, STARTLED }

const _FACE_COLOR := Color(0.1, 0.70, 0.60)
const _FACE_RADIUS := 28.0
const _RETURN_DELAY := 2.5

var emotion: Emotion = Emotion.NEUTRAL
var _emotion_elapsed: float = 0.0


func react(e: Emotion) -> void:
	emotion = e
	_emotion_elapsed = 0.0


func _process(delta: float) -> void:
	_emotion_elapsed += delta
	if emotion != Emotion.NEUTRAL and _emotion_elapsed >= _RETURN_DELAY:
		emotion = Emotion.NEUTRAL
		_emotion_elapsed = 0.0
	queue_redraw()


func _draw() -> void:
	var r := _FACE_RADIUS

	# Head
	draw_circle(Vector2.ZERO, r, _FACE_COLOR)
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 32, Color(1.0, 1.0, 1.0, 0.18), 1.5)

	var eye_y := -r * 0.22
	var eye_x := r * 0.35
	var eye_r := r * 0.17

	match emotion:
		Emotion.NEUTRAL:
			_draw_eye(Vector2(-eye_x, eye_y), eye_r, false)
			_draw_eye(Vector2(eye_x, eye_y), eye_r, false)
			draw_line(Vector2(-r * 0.28, r * 0.42), Vector2(r * 0.28, r * 0.42), Color.WHITE, 2.0)

		Emotion.SMUG:
			_draw_eye(Vector2(-eye_x, eye_y), eye_r, true)
			_draw_eye(Vector2(eye_x, eye_y), eye_r, true)
			# Smirk — arc offset to one side
			draw_arc(Vector2(r * 0.08, r * 0.35), r * 0.24, PI * 0.08, PI * 0.88, 12, Color.WHITE, 2.0)

		Emotion.STARTLED:
			_draw_eye(Vector2(-eye_x, eye_y - 3.0), eye_r * 1.3, false)
			_draw_eye(Vector2(eye_x, eye_y - 3.0), eye_r * 1.3, false)
			# Open O mouth
			draw_circle(Vector2(0.0, r * 0.46), r * 0.18, Color(0.04, 0.08, 0.08))
			draw_arc(Vector2(0.0, r * 0.46), r * 0.18, 0.0, TAU, 16, Color.WHITE, 2.0)


func _draw_eye(pos: Vector2, r: float, half_lidded: bool) -> void:
	draw_circle(pos, r, Color.WHITE)
	draw_circle(pos + Vector2(0.0, r * 0.15), r * 0.52, Color(0.04, 0.08, 0.08))
	if half_lidded:
		# Filled rect over top half simulates a drooping lid
		draw_rect(Rect2(pos - Vector2(r + 1.0, r + 1.0), Vector2((r + 1.0) * 2.0, r + 1.0)), _FACE_COLOR)
