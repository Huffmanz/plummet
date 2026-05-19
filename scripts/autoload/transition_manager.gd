extends Node
## Global transitions using the editor-built overlay in `scenes/ui/transition_overlay.tscn`.
## Autoload scene: `scenes/autoload/transition_manager.tscn`
##
##   await TransitionManager.transition_to("res://scenes/run/run_controller.tscn")
##   await TransitionManager.transition_screen(func(): do_something())
##
## Preview wipe shader: open `scenes/ui/transition_overlay_preview.tscn` and scrub
## `preview_progress` on WipeOverlay, or edit ShaderMaterial uniforms in the inspector.

signal transition_started
signal transition_midpoint
signal transition_finished

enum Style { FADE, DIAGONAL_WIPE }

@export var default_duration: float = 0.4
@export var default_style: Style = Style.DIAGONAL_WIPE
@export var default_fade_color: Color = UITheme.CANVAS

@onready var _overlay_layer: CanvasLayer = $TransitionOverlay
@onready var _overlay_rect: TransitionOverlayRect = $TransitionOverlay/WipeOverlay

var _wipe_material: ShaderMaterial
var _busy: bool = false


func _ready() -> void:
	_wipe_material = _overlay_rect.material as ShaderMaterial
	_reset_overlay()


func is_transitioning() -> bool:
	return _busy


func transition_to(
	scene_path: String,
	duration: float = -1.0,
	fade_color: Color = default_fade_color,
	style: Style = default_style
) -> void:
	var packed := load(scene_path) as PackedScene
	if packed == null:
		push_error("TransitionManager: failed to load scene: %s" % scene_path)
		return
	await transition_to_packed(packed, duration, fade_color, style)


func transition_to_packed(
	scene: PackedScene,
	duration: float = -1.0,
	fade_color: Color = default_fade_color,
	style: Style = default_style
) -> void:
	if scene == null:
		push_error("TransitionManager: null PackedScene")
		return
	if _busy:
		push_warning("TransitionManager: transition already in progress")
		return

	var transition_duration := default_duration if duration < 0.0 else duration
	_busy = true
	transition_started.emit()

	if transition_duration <= 0.0:
		get_tree().change_scene_to_packed(scene)
		_busy = false
		transition_finished.emit()
		return

	await _run_midpoint_transition(
		func() -> void: get_tree().change_scene_to_packed(scene),
		transition_duration,
		fade_color,
		style
	)

	_busy = false
	transition_finished.emit()


## Cover screen, run `action` while hidden, then reveal. Does not change scenes.
func transition_screen(
	action: Callable,
	duration: float = -1.0,
	fade_color: Color = default_fade_color,
	style: Style = default_style
) -> void:
	if _busy:
		push_warning("TransitionManager: transition already in progress")
		return
	if not action.is_valid():
		push_error("TransitionManager: invalid screen action")
		return

	var transition_duration := default_duration if duration < 0.0 else duration
	_busy = true
	transition_started.emit()

	if transition_duration <= 0.0:
		action.call()
		_busy = false
		transition_finished.emit()
		return

	await _run_midpoint_transition(action, transition_duration, fade_color, style)

	_busy = false
	transition_finished.emit()


func reload_current(
	duration: float = -1.0,
	fade_color: Color = default_fade_color,
	style: Style = default_style
) -> void:
	var tree := get_tree()
	var current := tree.current_scene
	if current == null:
		push_error("TransitionManager: no current scene to reload")
		return
	var path := current.scene_file_path
	if path.is_empty():
		push_error("TransitionManager: current scene has no file path")
		return
	await transition_to(path, duration, fade_color, style)


func _run_midpoint_transition(
	action: Callable,
	duration: float,
	cover_color: Color,
	style: Style
) -> void:
	## First half: shader progress 0 → 1 (fully cover). Midpoint: load / swap at progress 1.0.
	## Second half: shader progress 1 → 0 (reveal new scene).
	var half := duration * 0.5
	_overlay_rect.mouse_filter = Control.MOUSE_FILTER_STOP

	match style:
		Style.DIAGONAL_WIPE:
			await _run_wipe_cover_and_reveal(action, half, cover_color)
		Style.FADE:
			await _run_fade_cover_and_reveal(action, half, cover_color)
		_:
			await _run_wipe_cover_and_reveal(action, half, cover_color)

	_reset_overlay()


func _run_wipe_cover_and_reveal(action: Callable, half: float, cover_color: Color) -> void:
	_apply_wipe_shader(cover_color)
	_set_wipe_progress(0.0)
	await _tween_wipe_progress(0.0, 1.0, half)
	_set_wipe_progress(1.0)

	transition_midpoint.emit()
	action.call()
	await get_tree().process_frame

	await _tween_wipe_progress(1.0, 0.0, half)
	_set_wipe_progress(0.0)


func _run_fade_cover_and_reveal(action: Callable, half: float, cover_color: Color) -> void:
	_apply_fade_overlay(cover_color)
	_overlay_rect.modulate.a = 0.0
	await _tween_fade_alpha(0.0, 1.0, half)
	_overlay_rect.modulate.a = 1.0

	transition_midpoint.emit()
	action.call()
	await get_tree().process_frame

	await _tween_fade_alpha(1.0, 0.0, half)
	_overlay_rect.modulate.a = 0.0


func _apply_wipe_shader(cover_color: Color) -> void:
	if _wipe_material == null:
		push_error("TransitionManager: WipeOverlay has no ShaderMaterial")
		return
	_overlay_rect.material = _wipe_material
	_overlay_rect.color = Color.WHITE
	_overlay_rect.modulate = Color.WHITE
	_wipe_material.set_shader_parameter("wipe_color", cover_color)


func _apply_fade_overlay(cover_color: Color) -> void:
	_overlay_rect.material = null
	_overlay_rect.color = cover_color
	_overlay_rect.modulate = Color(1.0, 1.0, 1.0, 0.0)


func _reset_overlay() -> void:
	_overlay_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay_rect.material = _wipe_material
	_overlay_rect.color = Color.WHITE
	_overlay_rect.modulate = Color.WHITE
	_set_wipe_progress(0.0)


func _set_wipe_progress(value: float) -> void:
	_overlay_rect.set_progress(value)


func _tween_wipe_progress(from_progress: float, to_progress: float, time: float) -> void:
	_set_wipe_progress(from_progress)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(_set_wipe_progress, from_progress, to_progress, time)
	await tween.finished


func _tween_fade_alpha(from_a: float, to_a: float, time: float) -> void:
	_overlay_rect.modulate.a = from_a
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_overlay_rect, "modulate:a", to_a, time)
	await tween.finished
