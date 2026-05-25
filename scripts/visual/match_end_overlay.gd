class_name MatchEndOverlay extends Control

signal finished

@onready var _bg: ColorRect = $Background
@onready var _winner_label: RichTextLabel = %WinnerLabel
@onready var _player_score_label: Label = %PlayerScoreDisplay
@onready var _ai_score_label: Label = %AIScoreDisplay
@onready var _center: Control = $Center
@onready var _win_sfx: AudioStreamPlayer = $WinSfx
@onready var _count_up_sfx: AudioStreamPlayer = $CountUpSfx
@onready var _lose_sfx: AudioStreamPlayer = $LoseSfx
@onready var _confetti: WinConfetti = $WinConfetti
@onready var _next_btn: JuicySfxButton = %NextBtn

const _COUNT_DUR: float = 2.8
const _WINNER_FADE_DUR: float = 0.28
const _NEXT_FADE_DUR: float = 0.24

var _player_target: int = 0
var _ai_target: int = 0
var _elapsed: float = 0.0
var _running: bool = false
var _winner_shown: bool = false
var _winner_tween: Tween
var _next_tween: Tween
var _auto_continue_timer: SceneTreeTimer

const _AUTO_CONTINUE_DELAY := 3.0
const _SFX_WAIT_MAX := 1.5


func _ready() -> void:
	hide()
	_apply_cozy_ui()
	_next_btn.pressed.connect(_on_next_pressed)
	_hide_next_button()
	if get_parent() == get_tree().root:
		show_result.call_deferred(1200, 980)


func _apply_cozy_ui() -> void:
	_bg.color = Color(UITheme.CANVAS.r, UITheme.CANVAS.g, UITheme.CANVAS.b, 0.92)
	_winner_label.add_theme_color_override("default_color", UITheme.TEXT_ON_CANVAS)
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

	if _elapsed >= _COUNT_DUR and not _winner_shown:
		_handle_outcome_reveal()


func _set_winner_text(title: String, color: Color) -> void:
	_winner_label.add_theme_color_override("default_color", color)
	_winner_label.text = "[wave][center][font_size=32]%s[/font_size][/center][/wave]" % title


func _prepare_winner_label(player_score: int, ai_score: int) -> void:
	var title: String
	var color: Color
	if player_score > ai_score:
		title = "YOU WIN!"
		color = UITheme.VICTORY
	elif ai_score > player_score:
		title = "AI WINS"
		color = UITheme.DEFEAT
	else:
		title = "DRAW"
		color = UITheme.TEXT_ON_CANVAS
	_set_winner_text(title, color)
	_kill_winner_tween()
	_winner_label.modulate = Color(1.0, 1.0, 1.0, 0.0)


func _handle_outcome_reveal() -> void:
	_stop_count_up_sfx()
	_reveal_winner_label()
	if _player_target > _ai_target:
		_play_win_sfx()
		if not OS.has_feature("web"):
			await _wait_for_sfx(_win_sfx)
	else:
		_play_lose_sfx()
		if not OS.has_feature("web"):
			await _wait_for_sfx(_lose_sfx)
	if _running:
		_show_next_button()


func _wait_for_sfx(player: AudioStreamPlayer) -> void:
	if player == null or player.stream == null:
		return
	if not player.playing:
		return
	await get_tree().create_timer(_SFX_WAIT_MAX).timeout


func _reveal_winner_label() -> void:
	_winner_shown = true
	_kill_winner_tween()
	_winner_tween = create_tween()
	_winner_tween.tween_property(_winner_label, "modulate:a", 1.0, _WINNER_FADE_DUR) \
		.set_trans(Tween.TRANS_QUAD) \
		.set_ease(Tween.EASE_OUT)


func _kill_winner_tween() -> void:
	if _winner_tween != null and _winner_tween.is_valid():
		_winner_tween.kill()
	_winner_tween = null


func _hide_next_button() -> void:
	_kill_next_tween()
	_next_btn.disabled = true
	_next_btn.modulate = Color(1.0, 1.0, 1.0, 0.0)


func _show_next_button() -> void:
	_kill_next_tween()
	_next_btn.disabled = false
	_next_tween = create_tween().set_parallel(true)
	_next_tween.tween_property(_next_btn, "modulate:a", 1.0, _NEXT_FADE_DUR) \
		.set_trans(Tween.TRANS_QUAD) \
		.set_ease(Tween.EASE_OUT)
	_schedule_auto_continue()


func _schedule_auto_continue() -> void:
	_cancel_auto_continue()
	if not _running:
		return
	_auto_continue_timer = get_tree().create_timer(_AUTO_CONTINUE_DELAY)
	_auto_continue_timer.timeout.connect(_on_auto_continue, CONNECT_ONE_SHOT)


func _cancel_auto_continue() -> void:
	_auto_continue_timer = null


func _on_auto_continue() -> void:
	if not _running:
		return
	finished.emit()


func _kill_next_tween() -> void:
	if _next_tween != null and _next_tween.is_valid():
		_next_tween.kill()
	_next_tween = null


func _on_next_pressed() -> void:
	if not _running:
		return
	_cancel_auto_continue()
	_running = false
	finished.emit()


func _play_win_sfx() -> void:
	if _confetti != null:
		_confetti.play()
	if _win_sfx != null:
		_win_sfx.play()


func _play_lose_sfx() -> void:
	if _lose_sfx != null:
		_lose_sfx.play()


func _start_count_up_sfx() -> void:
	if _count_up_sfx == null or _count_up_sfx.stream == null:
		return
	_count_up_sfx.play()


func _stop_count_up_sfx() -> void:
	if _count_up_sfx == null:
		return
	if _count_up_sfx.playing:
		_count_up_sfx.stop()
	var wav := _count_up_sfx.stream as AudioStreamWAV
	if wav != null:
		wav.loop_mode = AudioStreamWAV.LOOP_DISABLED


func show_result(player_score: int, ai_score: int) -> void:
	_cancel_auto_continue()
	_stop_count_up_sfx()
	if _confetti != null:
		_confetti.stop()
	_player_target = player_score
	_ai_target = ai_score
	_elapsed = 0.0
	_running = true
	_winner_shown = false
	_prepare_winner_label(player_score, ai_score)
	_hide_next_button()
	_player_score_label.text = "0"
	_ai_score_label.text = "0"
	show()
	_start_count_up_sfx()
	await finished
	_stop_count_up_sfx()
