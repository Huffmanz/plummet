class_name Piece extends RefCounted

enum Owner { PLAYER, AI }
enum Type { NORMAL, PRISM, COIN, EMBER, SHARD, LOCKED }

var owner: Owner
var type: Type = Type.NORMAL
var modifier: String = ""  # empty string = no modifier


func _init(p_owner: Owner, p_type: Type = Type.NORMAL) -> void:
	owner = p_owner
	type = p_type


func has_modifier() -> bool:
	return modifier != ""


func copy_for_bag() -> Piece:
	var copy := Piece.new(owner, type)
	copy.modifier = modifier
	return copy
