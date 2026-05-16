class_name MatchedRun extends RefCounted

var owner: Piece.Owner
var cells: Array[Vector2i]


func _init(p_owner: Piece.Owner, p_cells: Array[Vector2i]) -> void:
	owner = p_owner
	cells = p_cells
