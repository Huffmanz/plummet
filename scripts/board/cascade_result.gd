class_name CascadeResult extends RefCounted

var clears: Array[TaggedClear] = []
var attribution: Piece.Owner
var cross_color: bool = false
var max_depth: int = 0


func _init(p_attribution: Piece.Owner) -> void:
	attribution = p_attribution
