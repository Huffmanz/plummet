class_name Piece extends RefCounted

enum Owner { PLAYER, AI }
enum Type { NORMAL, WEIGHTED, GHOST, VOLATILE }

var owner: Owner
var type: Type = Type.NORMAL
var modifiers: Array = []


func _init(p_owner: Owner, p_type: Type = Type.NORMAL) -> void:
	owner = p_owner
	type = p_type
