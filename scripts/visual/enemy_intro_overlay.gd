class_name EnemyIntroOverlay extends Control

signal finished

@onready var _spotlight: ColorRect = %Spotlight
@onready var _center: CenterContainer = $Center
@onready var _card: PanelContainer = %CardPanel
@onready var _name_label: RichTextLabel = %NameLabel
@onready var _gimmick_label: Label = %GimmickLabel
@onready var _boss_tag: Label = %BossTag

const _SPOTLIGHT_IN_SEC := 0.22
const _SPOTLIGHT_OUT_SEC := 0.35
const _HOLD_SEC := 1.35
const _POP_START_SCALE := 0.48
const _POP_SEC := 0.48
const _POP_ALPHA_SEC := 0.18
const _BANNER_FADE_SEC := 0.32

var _running: bool = false
var _pop_tween: Tween
var _banner_fade_tween: Tween

@export var reduced_motion: bool = false


func _ready() -> void:
	hide()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_theme()
	_reset_spotlight()
	_prep_banner_hidden()


func _apply_theme() -> void:
	_card.add_theme_stylebox_override("panel", UITheme.make_surface_style(12, UITheme.SURFACE))
	_name_label.add_theme_color_override("default_color", UITheme.AI)
	UITheme.style_label_muted(_gimmick_label, true)
	_gimmick_label.add_theme_font_size_override("font_size", 10)
	_boss_tag.add_theme_color_override("font_color", UITheme.ACCENT_POP)
	_boss_tag.add_theme_font_size_override("font_size", 11)


func play(enemy_name: String, gimmick: String, is_boss: bool, skip_motion: bool = false) -> void:
	if skip_motion or reduced_motion:
		hide()
		finished.emit()
		return

	_setup_card(enemy_name, gimmick, is_boss)
	if _card.get_parent() != _center:
		_center.add_child(_card)
	_prep_banner_hidden()

	show()
	mouse_filter = Control.MOUSE_FILTER_STOP
	_running = true

	await get_tree().process_frame
	await get_tree().process_frame
	if not _running:
		return

	await _fade_spotlight_in()
	if not _running:
		return

	await _play_pop_in()
	if not _running:
		return

	await get_tree().create_timer(_HOLD_SEC).timeout
	if not _running:
		return

	await _fade_out_banner()
	if not _running:
		return

	await _fade_spotlight_out()
	_finish()
	finished.emit()


func _setup_card(enemy_name: String, gimmick: String, is_boss: bool) -> void:
	_name_label.text = "[wave][center][font_size=28]%s[/font_size][/center][/wave]" % enemy_name.to_upper()
	var show_gimmick := not gimmick.is_empty() and gimmick != "No gimmick"
	_gimmick_label.text = gimmick.to_upper() if show_gimmick else ""
	_gimmick_label.visible = show_gimmick
	_boss_tag.visible = is_boss


func _fade_spotlight_in() -> void:
	_reset_spotlight()
	var tween := create_tween()
	tween.tween_property(_spotlight, "color:a", 0.52, _SPOTLIGHT_IN_SEC) \
		.set_trans(Tween.TRANS_QUAD) \
		.set_ease(Tween.EASE_OUT)
	await tween.finished


func _fade_spotlight_out() -> void:
	var tween := create_tween()
	tween.tween_property(_spotlight, "color:a", 0.0, _SPOTLIGHT_OUT_SEC) \
		.set_trans(Tween.TRANS_QUAD) \
		.set_ease(Tween.EASE_IN)
	await tween.finished


func _reset_spotlight() -> void:
	_spotlight.color = Color(UITheme.CANVAS.r, UITheme.CANVAS.g, UITheme.CANVAS.b, 0.0)


func _prep_banner_hidden() -> void:
	_center.visible = true
	_card.pivot_offset = Vector2.ZERO
	_card.scale = Vector2(_POP_START_SCALE, _POP_START_SCALE)
	_card.modulate = Color(1.0, 1.0, 1.0, 0.0)


func _play_pop_in() -> void:
	await get_tree().process_frame
	_card.pivot_offset = _card.size * 0.5
	_card.scale = Vector2(_POP_START_SCALE, _POP_START_SCALE)
	_card.modulate.a = 0.0

	_kill_pop_tween()
	_pop_tween = create_tween()
	_pop_tween.set_parallel(true)
	_pop_tween.tween_property(_card, "modulate:a", 1.0, _POP_ALPHA_SEC) \
		.set_trans(Tween.TRANS_QUAD) \
		.set_ease(Tween.EASE_OUT)
	_pop_tween.tween_property(_card, "scale", Vector2.ONE, _POP_SEC) \
		.set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_OUT)
	await _pop_tween.finished


func _fade_out_banner() -> void:
	_kill_banner_fade_tween()
	_banner_fade_tween = create_tween()
	_banner_fade_tween.tween_property(_card, "modulate:a", 0.0, _BANNER_FADE_SEC) \
		.set_trans(Tween.TRANS_QUAD) \
		.set_ease(Tween.EASE_IN)
	await _banner_fade_tween.finished
	_center.visible = false


func _reset_card_transform() -> void:
	_card.scale = Vector2.ONE
	_card.modulate = Color.WHITE
	_card.pivot_offset = Vector2.ZERO
	_gimmick_label.modulate = Color.WHITE


func _finish() -> void:
	_running = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	hide()
	_reset_card_transform()
	_reset_spotlight()
	_center.visible = true
	if _card.get_parent() != _center:
		_center.add_child(_card)
	_kill_pop_tween()
	_kill_banner_fade_tween()


func _kill_pop_tween() -> void:
	if _pop_tween != null and _pop_tween.is_valid():
		_pop_tween.kill()
	_pop_tween = null


func _kill_banner_fade_tween() -> void:
	if _banner_fade_tween != null and _banner_fade_tween.is_valid():
		_banner_fade_tween.kill()
	_banner_fade_tween = null
