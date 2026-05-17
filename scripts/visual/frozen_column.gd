class_name FrozenColumn extends RefCounted

var col: int = 0
var turns_remaining: int = 0


func _init(p_col: int = 0, p_turns: int = 0) -> void:
	col = p_col
	turns_remaining = p_turns
