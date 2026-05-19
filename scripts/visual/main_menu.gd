extends Control

signal start_run_pressed

@export var letter_stagger: float = 0.1
@export var letter_drop_duration: float = 0.55

@onready var _title_row: HBoxContainer = %TitleRow
@onready var _btn_start: JuicySfxButton = %BtnStart
@onready var _btn_quit: JuicySfxButton = %BtnQuit

var _seen_once: bool = false


func _ready() -> void:
	_btn_quit.pressed.connect(_on_quit_pressed)
	visibility_changed.connect(_on_visibility_changed)
	call_deferred("_play_title_intro")


func _on_start_pressed() -> void:
	var run_controller := get_parent()
	if run_controller != null and run_controller.has_method("_on_start_run"):
		await run_controller._on_start_run()
		return
	push_warning("MainMenu: run the project from run_controller.tscn to start a run")
	start_run_pressed.emit()


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_visibility_changed() -> void:
	if not visible or not _seen_once:
		return
	call_deferred("_play_title_intro")


func _play_title_intro() -> void:
	_seen_once = true
	for i in _title_row.get_child_count():
		var slot := _title_row.get_child(i)
		if slot.get_child_count() == 0:
			continue
		var ball := slot.get_child(0) as TitleLetterBall
		if ball == null:
			continue
		ball.play_drop(float(i) * letter_stagger, letter_drop_duration)
