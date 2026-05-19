extends Control

signal start_run_pressed

const _BG := Color(0.06, 0.04, 0.10)
const _TITLE_COLOR := Color(0.95, 0.85, 1.0)
const _SUBTITLE_COLOR := Color(0.6, 0.5, 0.7)
const _BTN_NORMAL := Color(0.35, 0.18, 0.55)
const _BTN_HOVER := Color(0.50, 0.28, 0.72)
const _BTN_TEXT := Color(1.0, 1.0, 1.0)

var _btn: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = _BG
	add_child(bg)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.custom_minimum_size = Vector2(300.0, 200.0)
	vbox.add_theme_constant_override("separation", 20)
	add_child(vbox)

	var title := Label.new()
	title.text = "PLUMMET"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", _TITLE_COLOR)
	vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Roguelike Puzzle"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", _SUBTITLE_COLOR)
	vbox.add_child(subtitle)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0.0, 16.0)
	vbox.add_child(spacer)

	_btn = _make_button("START RUN")
	_btn.pressed.connect(func() -> void: start_run_pressed.emit())
	vbox.add_child(_btn)


func _make_button(label_text: String) -> Button:
	var btn := Button.new()
	btn.text = label_text
	btn.custom_minimum_size = Vector2(200.0, 44.0)
	btn.add_theme_font_size_override("font_size", 16)
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
