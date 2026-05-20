extends Control

signal new_run_pressed
signal main_menu_pressed

@onready var _card: PanelContainer = %Card
@onready var _fly_in: StaggerFlyInContainer = %FlyInVBox
@onready var _result_label: RichTextLabel = %ResultLabel
@onready var _reached_value: Label = %ReachedValue
@onready var _final_score_value: Label = %FinalScoreValue
@onready var _total_score_value: Label = %TotalScoreValue
@onready var _fragments_value: Label = %FragmentsValue
@onready var _cascade_value: Label = %CascadeValue
@onready var _cross_color_value: Label = %CrossColorValue
@onready var _new_run_btn: JuicySfxButton = %NewRunBtn
@onready var _menu_btn: JuicySfxButton = %MenuBtn

@export var preview_when_run_directly: bool = true


func _ready() -> void:
	_card.add_theme_stylebox_override("panel", UITheme.make_surface_style())
	_apply_surface_label_theme()
	_new_run_btn.pressed.connect(func() -> void: new_run_pressed.emit())
	_menu_btn.pressed.connect(func() -> void: main_menu_pressed.emit())
	if preview_when_run_directly and get_parent() == get_tree().root:
		show_summary(_make_preview_state(), true)


func _make_preview_state() -> RunState:
	var state := RunState.new()
	state.act = 2
	state.match_in_act = 3
	state.last_match_score = 1840
	state.total_score = 5620
	state.fragments_earned = 18
	state.highest_cascade = 3
	state.cross_color_count = 2
	return state


func show_summary(state: RunState, victory: bool) -> void:
	var title := "VICTORY" if victory else "DEFEAT"
	var color: Color = UITheme.VICTORY if victory else UITheme.DEFEAT
	_result_label.add_theme_color_override("default_color", color)
	_result_label.text = _format_result_bbcode(title)

	if victory:
		_reached_value.text = "Act 3 · Final Boss"
	elif state.is_boss_match():
		_reached_value.text = "Act %d · Boss" % state.act
	else:
		_reached_value.text = "Act %d · Match %d" % [state.act, state.match_in_act]

	_final_score_value.text = str(state.last_match_score)
	_total_score_value.text = str(state.total_score)
	_fragments_value.text = str(state.fragments_earned)
	_cascade_value.text = (
		"×%d" % (state.highest_cascade + 1) if state.highest_cascade > 0 else "None"
	)
	_cross_color_value.text = str(state.cross_color_count)
	_fly_in.reset_targets()
	_fly_in.play_fly_in()


func _format_result_bbcode(title: String) -> String:
	return "[wave][center][font_size=40]%s[/font_size][/center][/wave]" % title


func _apply_surface_label_theme() -> void:
	var muted_paths: Array[String] = [
		"Scroll/Margin/Card/MarginContainer/FlyInVBox/ReachedRow/ReachedLabel",
		"Scroll/Margin/Card/MarginContainer/FlyInVBox/FinalScoreRow/FinalScoreLabel",
		"Scroll/Margin/Card/MarginContainer/FlyInVBox/TotalScoreRow/TotalScoreLabel",
		"Scroll/Margin/Card/MarginContainer/FlyInVBox/FragmentsRow/FragmentsLabel",
		"Scroll/Margin/Card/MarginContainer/FlyInVBox/CascadeRow/CascadeLabel",
		"Scroll/Margin/Card/MarginContainer/FlyInVBox/CrossColorRow/CrossColorLabel",
	]
	for path in muted_paths:
		var lbl := get_node_or_null(path) as Label
		if lbl != null:
			lbl.add_theme_color_override("font_color", UITheme.TEXT_MUTED_ON_SURFACE)
	for val: Label in [
		_reached_value, _final_score_value, _total_score_value,
		_fragments_value, _cascade_value, _cross_color_value,
	]:
		val.add_theme_color_override("font_color", UITheme.TEXT_ON_SURFACE)
