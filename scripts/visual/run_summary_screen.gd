extends Control

signal new_run_pressed
signal main_menu_pressed

const _MODIFIER_NAMES: Dictionary = {
	"echo": "Echo", "magnet": "Magnet", "heavy": "Heavy",
	"anchor": "Anchor", "catalyst": "Catalyst", "double_drop": "Dbl Drop",
	"volatile": "Volatile",
}
const _TYPE_NAMES: Dictionary = {
	0: "Normal", 1: "Weighted", 2: "Ghost", 3: "Volatile",
}

@onready var _card: PanelContainer = %Card
@onready var _fly_in: StaggerFlyInContainer = %FlyInVBox
@onready var _result_label: Label = %ResultLabel
@onready var _reached_value: Label = %ReachedValue
@onready var _final_score_value: Label = %FinalScoreValue
@onready var _total_score_value: Label = %TotalScoreValue
@onready var _fragments_value: Label = %FragmentsValue
@onready var _cascade_value: Label = %CascadeValue
@onready var _cross_color_value: Label = %CrossColorValue
@onready var _bag_text: Label = %BagText
@onready var _new_run_btn: Button = %NewRunBtn
@onready var _menu_btn: Button = %MenuBtn

@export var preview_when_run_directly: bool = true


func _ready() -> void:
	_card.add_theme_stylebox_override("panel", UITheme.make_surface_style())
	_apply_surface_label_theme()
	UITheme.style_button(_new_run_btn)
	UITheme.style_button(_menu_btn)
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
	state.player_bag = PieceBag.new(Piece.Owner.PLAYER)
	state.player_bag.get_piece_at(0).modifiers = ["Magnet", "Echo"]
	state.player_bag.get_piece_at(2).type = Piece.Type.WEIGHTED
	return state


func show_summary(state: RunState, victory: bool) -> void:
	_result_label.text = "VICTORY" if victory else "DEFEAT"
	_result_label.add_theme_color_override(
		"font_color", UITheme.VICTORY if victory else UITheme.DEFEAT
	)

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
	_bag_text.text = _format_bag(state)
	_fly_in.reset_targets()
	_fly_in.play_fly_in()


func _apply_surface_label_theme() -> void:
	var muted_paths: Array[String] = [
		"Scroll/Margin/Card/FlyInVBox/ReachedRow/ReachedLabel",
		"Scroll/Margin/Card/FlyInVBox/FinalScoreRow/FinalScoreLabel",
		"Scroll/Margin/Card/FlyInVBox/TotalScoreRow/TotalScoreLabel",
		"Scroll/Margin/Card/FlyInVBox/FragmentsRow/FragmentsLabel",
		"Scroll/Margin/Card/FlyInVBox/CascadeRow/CascadeLabel",
		"Scroll/Margin/Card/FlyInVBox/CrossColorRow/CrossColorLabel",
		"Scroll/Margin/Card/FlyInVBox/BagHeader",
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
	_bag_text.add_theme_color_override("font_color", UITheme.TEXT_MUTED_ON_SURFACE)


func _format_bag(state: RunState) -> String:
	if state.player_bag == null:
		return "  (empty)"
	var lines: PackedStringArray = []
	for i in 7:
		var piece := state.player_bag.get_piece_at(i)
		if piece == null:
			continue
		var type_name: String = _TYPE_NAMES.get(piece.type, "Normal")
		var mods_text := ""
		if not piece.modifiers.is_empty():
			var mod_names: Array[String] = []
			for m in piece.modifiers:
				mod_names.append(_MODIFIER_NAMES.get(str(m), str(m)))
			mods_text = " [%s]" % ", ".join(mod_names)
		lines.append("  %d. %s%s" % [i + 1, type_name, mods_text])
	return "\n".join(lines) if not lines.is_empty() else "  (empty)"
