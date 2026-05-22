class_name ScoreAccumulatorOverlay extends Control

@onready var _panel: PanelContainer = %AccumPanel
@onready var _player_row: HBoxContainer = %PlayerRow
@onready var _player_base_label: Label = %PlayerBaseLabel
@onready var _player_mult_label: Label = %PlayerMultLabel
@onready var _ai_row: HBoxContainer = %AIRow
@onready var _ai_base_label: Label = %AIBaseLabel
@onready var _ai_mult_label: Label = %AIMultLabel
@onready var _divider: HSeparator = %Divider

const _COUNTUP_DUR: float = 0.28

var _player_base: int = 0
var _ai_base: int = 0
var _player_disp: float = 0.0
var _ai_disp: float = 0.0
var _player_max_depth: int = 0
var _ai_max_depth: int = 0
var _player_tween: Tween
var _ai_tween: Tween


func _ready() -> void:
	hide()
	_apply_theme()


func reset_and_show() -> void:
	_player_base = 0
	_ai_base = 0
	_player_disp = 0.0
	_ai_disp = 0.0
	_player_max_depth = 0
	_ai_max_depth = 0
	_kill_tweens()
	_player_base_label.text = "0"
	_ai_base_label.text = "0"
	_player_mult_label.text = "×1"
	_ai_mult_label.text = "×1"
	_player_row.hide()
	_ai_row.hide()
	_divider.hide()
	modulate.a = 1.0
	_panel.modulate = Color.WHITE
	show()


func add_clear(owner: Piece.Owner, base_pts: int, multiplier: int) -> void:
	if owner == Piece.Owner.PLAYER:
		_player_base += base_pts
		_player_max_depth = maxi(_player_max_depth, multiplier)
		_player_mult_label.text = "×%d" % _player_max_depth
		_player_row.show()
		_count_up_player()
	else:
		_ai_base += base_pts
		_ai_max_depth = maxi(_ai_max_depth, multiplier)
		_ai_mult_label.text = "×%d" % _ai_max_depth
		_ai_row.show()
		_count_up_ai()
	_divider.visible = _player_row.visible and _ai_row.visible


func add_bonus(owner: Piece.Owner, bonus_pts: int) -> void:
	if bonus_pts <= 0:
		return
	if owner == Piece.Owner.PLAYER:
		_player_base += bonus_pts
		_player_row.show()
		_count_up_player()
	else:
		_ai_base += bonus_pts
		_ai_row.show()
		_count_up_ai()
	_divider.visible = _player_row.visible and _ai_row.visible


func flash_and_dismiss() -> void:
	if not visible:
		return
	_kill_tweens()
	_player_base_label.text = str(_player_base)
	_ai_base_label.text = str(_ai_base)
	var tween := create_tween()
	tween.tween_property(_panel, "modulate", Color(2.0, 2.0, 2.0, 1.0), 0.08)
	tween.tween_property(_panel, "modulate", Color.WHITE, 0.1)
	tween.tween_interval(0.12)
	tween.tween_property(self, "modulate:a", 0.0, 0.28)
	await tween.finished
	modulate.a = 1.0
	_panel.modulate = Color.WHITE
	hide()


func _count_up_player() -> void:
	if _player_tween != null and _player_tween.is_valid():
		_player_tween.kill()
	var from := _player_disp
	var to := float(_player_base)
	_player_tween = create_tween()
	_player_tween.tween_method(
		func(v: float) -> void:
			_player_disp = v
			_player_base_label.text = str(int(v)),
		from, to, _COUNTUP_DUR
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _count_up_ai() -> void:
	if _ai_tween != null and _ai_tween.is_valid():
		_ai_tween.kill()
	var from := _ai_disp
	var to := float(_ai_base)
	_ai_tween = create_tween()
	_ai_tween.tween_method(
		func(v: float) -> void:
			_ai_disp = v
			_ai_base_label.text = str(int(v)),
		from, to, _COUNTUP_DUR
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _kill_tweens() -> void:
	if _player_tween != null and _player_tween.is_valid():
		_player_tween.kill()
	if _ai_tween != null and _ai_tween.is_valid():
		_ai_tween.kill()


func _apply_theme() -> void:
	_panel.add_theme_stylebox_override("panel", UITheme.make_surface_style())
	var player_lbl: Label = %PlayerOwner
	var ai_lbl: Label = %AIOwner
	player_lbl.add_theme_color_override("font_color", UITheme.PLAYER)
	ai_lbl.add_theme_color_override("font_color", UITheme.AI)
	_player_base_label.add_theme_color_override("font_color", UITheme.TEXT_ON_SURFACE)
	_player_mult_label.add_theme_color_override("font_color", UITheme.ACCENT_POP)
	_ai_base_label.add_theme_color_override("font_color", UITheme.TEXT_ON_SURFACE)
	_ai_mult_label.add_theme_color_override("font_color", UITheme.ACCENT_POP)
	var sep: StyleBoxLine = StyleBoxLine.new()
	sep.color = UITheme.SURFACE_BORDER_MUTED
	_divider.add_theme_stylebox_override("separator", sep)
