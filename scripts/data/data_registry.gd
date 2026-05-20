extends Node

var _piece_types: Dictionary = {}
var _modifiers: Dictionary = {}
var _relics: Dictionary = {}


func _ready() -> void:
	_load_dir("res://resources/piece_types/", _piece_types)
	_load_dir("res://resources/modifiers/", _modifiers)
	_load_dir("res://resources/relics/", _relics)


func get_piece_type(id: String) -> PieceTypeData:
	return _piece_types.get(id, null) as PieceTypeData


func get_modifier(id: String) -> ModifierData:
	return _modifiers.get(id, null) as ModifierData


func get_relic(id: String) -> RelicData:
	return _relics.get(id, null) as RelicData


func get_all_piece_types() -> Array:
	return _piece_types.values()


func get_all_modifiers() -> Array:
	return _modifiers.values()


func get_all_relics() -> Array:
	return _relics.values()


func _load_dir(path: String, table: Dictionary) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if fname.ends_with(".tres"):
			var res: Resource = load(path + fname)
			if res != null and "id" in res:
				table[res.get("id")] = res
		fname = dir.get_next()
