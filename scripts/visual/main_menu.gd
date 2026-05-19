extends Control

signal start_run_pressed

var _btn: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.set_script(load("res://scripts/visual/cozy_screen_background.gd"))
	bg.color = UITheme.CANVAS
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
	title.add_theme_color_override("font_color", UITheme.TEXT_ON_CANVAS)
	vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Roguelike Puzzle"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 14)
	UITheme.style_label_muted(subtitle)
	vbox.add_child(subtitle)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0.0, 16.0)
	vbox.add_child(spacer)

	_btn = Button.new()
	_btn.text = "START RUN"
	_btn.custom_minimum_size = Vector2(200.0, 44.0)
	_btn.add_theme_font_size_override("font_size", 16)
	UITheme.style_button(_btn)
	_btn.pressed.connect(func() -> void: start_run_pressed.emit())
	vbox.add_child(_btn)
