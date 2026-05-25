class_name JuicySfxButton extends Button

@export var hover_sounds: Array[AudioStream] = []:
	set(value):
		hover_sounds = value
		_sync_hover_sounds()
@export var hover_volume_db: float = 0.0
@export var click_sounds: Array[AudioStream] = []:
	set(value):
		click_sounds = value
		_sync_click_sounds()
@export var click_volume_db: float = 0.0

@export var hover_scale: Vector2 = Vector2(1.08, 1.08)
@export var normal_bg_color: Color = Color(0.482353, 0.682353, 0.498039, 1.0):
	set(value):
		normal_bg_color = value
		_apply_normal_bg_color()
@export var hover_bg_color: Color = Color(0.56, 0.76, 0.58, 1.0)
@export var hover_label_color: Color = Color(1.0, 1.0, 1.0, 1.0)
## High-contrast rim — stays independent of hover_bg_color so it reads on any fill.
@export var hover_border_color: Color = Color(0.98, 0.97, 0.95, 1.0)
@export var hover_border_width: int = 4
@export var hover_duration: float = 0.14
@export var hover_rotation_deg: float = 10.0
@export var hover_wiggle_period: float = 0.25
@export var button_text: String = "Button":
	set(value):
		button_text = value
		if is_node_ready():
			_sync_label()

@onready var _audio: RandomAudioPlayer = $RandomAudioPlayer
@onready var _click_audio: RandomAudioPlayer = $ClickAudioPlayer
@onready var _visual: Control = $VisualPivot
@onready var _panel: Panel = $VisualPivot/Panel
@onready var _label: Label = $VisualPivot/Label

var _panel_style: StyleBoxFlat
var _rest_scale: Vector2 = Vector2.ONE
var _rest_rotation: float = 0.0
var _rest_bg_color: Color
var _rest_label_color: Color
var _rest_border_color: Color
var _rest_border_width: int = 2
var _hover_tween: Tween
var _wiggle_tween: Tween
var _highlighted: bool = false


func _ready() -> void:
	# Release-mode clicks were lost when VisualPivot children intercepted input.
	action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	focus_mode = FOCUS_ALL
	_audio.volume_db = hover_volume_db
	_click_audio.volume_db = click_volume_db
	_sync_hover_sounds()
	_sync_click_sounds()
	_cache_rest_state()
	_sync_label()
	_sync_pivot()
	_make_visuals_click_through()
	resized.connect(_sync_pivot)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)
	pressed.connect(_on_pressed)
	button_up.connect(_on_button_up)


func _make_visuals_click_through() -> void:
	if _visual != null:
		_apply_mouse_ignore(_visual)


func _apply_mouse_ignore(node: Node) -> void:
	if node is Control:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_apply_mouse_ignore(child)


func _on_pressed() -> void:
	_play_random_from(click_sounds, _click_audio)
	_set_highlighted(false)


func _on_button_up() -> void:
	if not is_hovered() and not has_focus():
		_set_highlighted(false)


func _apply_normal_bg_color() -> void:
	_rest_bg_color = normal_bg_color
	if _panel_style != null:
		_panel_style.bg_color = normal_bg_color


## Re-apply panel/label visuals after layout (WebGL can skip child Panel draws until refreshed).
func refresh_web_visuals() -> void:
	if not is_node_ready():
		return
	_cache_rest_state()
	modulate = Color.WHITE
	if _visual != null:
		_visual.visible = true
		_visual.modulate = Color.WHITE
	if _panel != null:
		_panel.visible = true
		_panel.modulate = Color.WHITE
	if _label != null:
		_label.visible = true
		_label.modulate = Color.WHITE
		_label.add_theme_color_override("font_color", UITheme.TEXT_ON_SURFACE)


func _cache_rest_state() -> void:
	var panel_style := _panel.get_theme_stylebox("panel")
	if panel_style is StyleBoxFlat:
		_panel_style = panel_style.duplicate() as StyleBoxFlat
		_panel.add_theme_stylebox_override("panel", _panel_style)
		_rest_border_color = _panel_style.border_color
		_rest_border_width = _panel_style.border_width_left
	else:
		_panel_style = StyleBoxFlat.new()
		_rest_border_color = UITheme.SURFACE_BORDER
		_rest_border_width = 2

	_apply_normal_bg_color()
	_rest_label_color = _label.get_theme_color("font_color")
	var target := _animation_target()
	target.rotation = 0.0
	_rest_rotation = target.rotation
	_rest_scale = target.scale


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
	_set_highlighted(true)


func _on_mouse_exited() -> void:
	if not has_focus():
		_set_highlighted(false)


func _on_focus_entered() -> void:
	_set_highlighted(true)


func _on_focus_exited() -> void:
	if not is_hovered():
		_set_highlighted(false)


func _sync_hover_sounds() -> void:
	if _audio != null:
		_audio.streams = hover_sounds


func _sync_click_sounds() -> void:
	if _click_audio != null:
		_click_audio.streams = click_sounds


func play_random_from(streams: Array[AudioStream]) -> void:
	_play_random_from(streams, _audio)


func _play_random_from(streams: Array[AudioStream], player: RandomAudioPlayer = _audio) -> void:
	if player != null:
		player.play_random_from(streams)


func _set_highlighted(active: bool) -> void:
	if active == _highlighted:
		return
	_highlighted = active
	if active:
		_play_random_from(hover_sounds)
		_tween_highlight(1.0)
	else:
		_tween_highlight(0.0)


func _tween_highlight(to_hover: float) -> void:
	_kill_tweens()
	var target := _animation_target()
	var target_scale := _rest_scale.lerp(hover_scale, to_hover)
	var color_from := 1.0 - to_hover
	var color_to := to_hover

	_hover_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_hover_tween.tween_property(target, "scale", target_scale, hover_duration)
	_hover_tween.parallel().tween_method(_apply_color_blend, color_from, color_to, hover_duration)

	if to_hover >= 1.0:
		_play_wiggle()
	else:
		_hover_tween.parallel().tween_property(target, "rotation", _rest_rotation, hover_duration)


func _apply_color_blend(t: float) -> void:
	if _panel_style != null:
		_panel_style.bg_color = _rest_bg_color.lerp(hover_bg_color, t)
		_panel_style.border_color = _rest_border_color.lerp(hover_border_color, t)
		var width := int(lerpf(float(_rest_border_width), float(hover_border_width), t))
		_panel_style.set_border_width_all(width)
	if _label != null:
		_label.add_theme_color_override("font_color", _rest_label_color.lerp(hover_label_color, t))


func _play_wiggle() -> void:
	var target := _animation_target()
	var angle := deg_to_rad(hover_rotation_deg)
	var leg := hover_wiggle_period / 3.0

	_wiggle_tween = create_tween()
	_wiggle_tween.tween_property(target, "rotation", angle, leg) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_wiggle_tween.tween_property(target, "rotation", -angle, leg) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_wiggle_tween.tween_property(target, "rotation", _rest_rotation, leg) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _kill_tweens() -> void:
	if _hover_tween != null and _hover_tween.is_valid():
		_hover_tween.kill()
	if _wiggle_tween != null and _wiggle_tween.is_valid():
		_wiggle_tween.kill()
	_hover_tween = null
	_wiggle_tween = null
