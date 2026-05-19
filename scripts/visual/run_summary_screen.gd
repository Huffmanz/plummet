extends Control

signal new_run_pressed
signal main_menu_pressed

const _BG := Color(0.06, 0.04, 0.10)
const _VICTORY_COLOR := Color(0.4, 1.0, 0.6)
const _DEFEAT_COLOR := Color(1.0, 0.35, 0.35)
const _LABEL_COLOR := Color(0.7, 0.65, 0.8)
const _VALUE_COLOR := Color(1.0, 0.95, 1.0)
const _BAG_COLOR := Color(0.55, 0.45, 0.7)
const _BTN_NORMAL := Color(0.35, 0.18, 0.55)
const _BTN_HOVER := Color(0.50, 0.28, 0.72)
const _BTN_TEXT := Color(1.0, 1.0, 1.0)

const _MODIFIER_NAMES: Dictionary = {
	"echo": "Echo", "magnet": "Magnet", "heavy": "Heavy",
	"anchor": "Anchor", "catalyst": "Catalyst", "double_drop": "Dbl Drop",
}
const _TYPE_NAMES: Dictionary = {
	0: "Normal", 1: "Weighted", 2: "Ghost", 3: "Volatile",
}


func show_summary(state: RunState, victory: bool) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui(state, victory)


func _build_ui(state: RunState, victory: bool) -> void:
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = _BG
	add_child(bg)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.offset_top = 0.0
	scroll.offset_bottom = 0.0
	add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(320.0, 0.0)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	vbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_theme_constant_override("separation", 10)
	scroll.add_child(vbox)

	# Result header
	var result_label := Label.new()
	result_label.text = "VICTORY" if victory else "DEFEAT"
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.add_theme_font_size_override("font_size", 40)
	result_label.add_theme_color_override("font_color", _VICTORY_COLOR if victory else _DEFEAT_COLOR)
	vbox.add_child(result_label)

	var acts_text: String
	if victory:
		acts_text = "Act 3 · Final Boss"
	elif state.is_boss_match():
		acts_text = "Act %d · Boss" % state.act
	else:
		acts_text = "Act %d · Match %d" % [state.act, state.match_in_act]
	_add_stat(vbox, "Reached", acts_text)

	_add_spacer(vbox, 6.0)

	_add_stat(vbox, "Final Match Score", str(state.last_match_score))
	_add_stat(vbox, "Total Run Score", str(state.total_score))
	_add_stat(vbox, "Fragments Earned", str(state.fragments_earned))
	_add_stat(vbox, "Highest Cascade", "×%d" % (state.highest_cascade + 1) if state.highest_cascade > 0 else "None")
	_add_stat(vbox, "Cross-Color Bonuses", str(state.cross_color_count))

	_add_spacer(vbox, 8.0)

	var bag_header := Label.new()
	bag_header.text = "YOUR BAG"
	bag_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bag_header.add_theme_font_size_override("font_size", 13)
	bag_header.add_theme_color_override("font_color", _LABEL_COLOR)
	vbox.add_child(bag_header)

	if state.player_bag != null:
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
			var row_label := Label.new()
			row_label.text = "  %d. %s%s" % [i + 1, type_name, mods_text]
			row_label.add_theme_font_size_override("font_size", 12)
			row_label.add_theme_color_override("font_color", _BAG_COLOR)
			vbox.add_child(row_label)

	_add_spacer(vbox, 12.0)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 12)
	vbox.add_child(btn_row)

	var new_run_btn := _make_button("NEW RUN")
	new_run_btn.pressed.connect(func() -> void: new_run_pressed.emit())
	btn_row.add_child(new_run_btn)

	var menu_btn := _make_button("MAIN MENU")
	menu_btn.pressed.connect(func() -> void: main_menu_pressed.emit())
	btn_row.add_child(menu_btn)


func _add_stat(parent: Control, label_text: String, value_text: String) -> void:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_FILL
	parent.add_child(row)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", _LABEL_COLOR)
	row.add_child(lbl)

	var val := Label.new()
	val.text = value_text
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	val.add_theme_font_size_override("font_size", 13)
	val.add_theme_color_override("font_color", _VALUE_COLOR)
	row.add_child(val)


func _add_spacer(parent: Control, height: float) -> void:
	var s := Control.new()
	s.custom_minimum_size = Vector2(0.0, height)
	parent.add_child(s)


func _make_button(label_text: String) -> Button:
	var btn := Button.new()
	btn.text = label_text
	btn.custom_minimum_size = Vector2(130.0, 40.0)
	btn.add_theme_font_size_override("font_size", 14)
	btn.add_theme_color_override("font_color", _BTN_TEXT)
	btn.add_theme_color_override("font_hover_color", _BTN_TEXT)
	btn.add_theme_color_override("font_pressed_color", _BTN_TEXT)
	var normal_sb := _make_stylebox(_BTN_NORMAL)
	var hover_sb := _make_stylebox(_BTN_HOVER)
	btn.add_theme_stylebox_override("normal", normal_sb)
	btn.add_theme_stylebox_override("hover", hover_sb)
	btn.add_theme_stylebox_override("pressed", hover_sb)
	btn.add_theme_stylebox_override("focus", normal_sb)
	return btn


func _make_stylebox(color: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.corner_radius_top_left = 6
	sb.corner_radius_top_right = 6
	sb.corner_radius_bottom_left = 6
	sb.corner_radius_bottom_right = 6
	sb.content_margin_left = 12.0
	sb.content_margin_right = 12.0
	sb.content_margin_top = 8.0
	sb.content_margin_bottom = 8.0
	return sb
