class_name MatchEndOverlay extends Control

signal finished

@onready var _bg: ColorRect = $Background
@onready var _winner_label: Label = %WinnerLabel
@onready var _player_score_label: Label = %PlayerScoreDisplay
@onready var _ai_score_label: Label = %AIScoreDisplay
@onready var _center: Control = $Center

const _COUNT_DUR: float = 1.8
const _HOLD_DUR: float = 1.2

var _player_target: int = 0
var _ai_target: int = 0
var _elapsed: float = 0.0
var _running: bool = false


func _ready() -> void:
	hide()
	_apply_cozy_ui()
	if get_parent() == get_tree().root:
		show_result.call_deferred(1250, 980)


func _apply_cozy_ui() -> void:
	_bg.color = Color(UITheme.CANVAS.r, UITheme.CANVAS.g, UITheme.CANVAS.b, 0.92)
	_winner_label.add_theme_color_override("font_color", UITheme.TEXT_ON_CANVAS)
	var player_panel: PanelContainer = $Center/VBox/ScoreRow/PlayerPanel
	var ai_panel: PanelContainer = $Center/VBox/ScoreRow/AIPanel
	player_panel.add_theme_stylebox_override("panel", UITheme.make_surface_style())
	ai_panel.add_theme_stylebox_override("panel", UITheme.make_surface_style())
	for lbl: Label in [$Center/VBox/ScoreRow/PlayerPanel/PlayerBox/PlayerTitle, %PlayerScoreDisplay]:
		lbl.add_theme_color_override("font_color", UITheme.PLAYER if lbl != %PlayerScoreDisplay else UITheme.TEXT_ON_SURFACE)
		if lbl == %PlayerScoreDisplay:
			lbl.add_theme_font_size_override("font_size", 28)
	for lbl: Label in [$Center/VBox/ScoreRow/AIPanel/AIBox/AITitle, %AIScoreDisplay]:
		lbl.add_theme_color_override("font_color", UITheme.AI if lbl != %AIScoreDisplay else UITheme.TEXT_ON_SURFACE)
		if lbl == %AIScoreDisplay:
			lbl.add_theme_font_size_override("font_size", 28)


func _process(delta: float) -> void:
	if not _running:
		return
	_elapsed += delta
	var frac := clampf(_elapsed / _COUNT_DUR, 0.0, 1.0)
	_player_score_label.text = str(int(_player_target * frac))
	_ai_score_label.text = str(int(_ai_target * frac))

	if _elapsed >= _COUNT_DUR and _winner_label.text == "":
		if _player_target > _ai_target:
			_winner_label.text = "YOU WIN!"
		elif _ai_target > _player_target:
			_winner_label.text = "AI WINS"
		else:
			_winner_label.text = "DRAW"

	if _elapsed >= _COUNT_DUR + _HOLD_DUR:
		_running = false
		finished.emit()


func show_result(player_score: int, ai_score: int) -> void:
	_player_target = player_score
	_ai_target = ai_score
	_elapsed = 0.0
	_running = true
	_winner_label.text = ""
	_player_score_label.text = "0"
	_ai_score_label.text = "0"
	show()
	await finished
