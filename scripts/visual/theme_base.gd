class_name ThemeBase extends RefCounted

var color_player: Color = Color(0.6, 0.2, 0.8)
var color_ai: Color = Color(0.1, 0.7, 0.6)
var color_empty: Color = Color(0.3, 0.3, 0.3, 0.5)
var color_bg: Color = Color(0.12, 0.12, 0.15)
var color_locked: Color = Color(0.4, 0.4, 0.4)
var color_frozen_overlay: Color = Color(0.2, 0.5, 0.9, 0.25)
var color_ui_bg: Color = Color(0.08, 0.08, 0.10)
var color_text_primary: Color = Color.WHITE
var color_text_secondary: Color = Color(0.65, 0.65, 0.70)
var modifier_colors: Dictionary = {}

var cell_size: float = 48.0
var cell_gap: float = 4.0


func draw_empty_cell(_canvas: CanvasItem, _rect: Rect2) -> void:
	pass


func draw_player_piece(_canvas: CanvasItem, _rect: Rect2, _piece_type: CellState.PieceType) -> void:
	pass


func draw_ai_piece(_canvas: CanvasItem, _rect: Rect2, _piece_type: CellState.PieceType) -> void:
	pass


func draw_ghost_piece(_canvas: CanvasItem, _rect: Rect2) -> void:
	pass


func draw_locked_cell(_canvas: CanvasItem, _rect: Rect2) -> void:
	pass


func draw_frozen_overlay(_canvas: CanvasItem, _rect: Rect2, _turns_remaining: int) -> void:
	pass


func draw_modifier_badge(_canvas: CanvasItem, _rect: Rect2, _modifier_name: String, _slot: int) -> void:
	pass


func draw_queue_entry(_canvas: CanvasItem, _rect: Rect2, _entry: QueueEntry) -> void:
	pass


func get_modifier_abbrev(_modifier_name: String) -> String:
	return ""


func get_modifier_color(_modifier_name: String) -> Color:
	return Color.WHITE


func get_piece_border_style(piece_type: CellState.PieceType) -> int:
	return piece_type
