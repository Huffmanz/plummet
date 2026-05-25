extends Node
## Indexes piece types, modifiers, and relics. Uses explicit paths so loading works on web
## exports where DirAccess cannot list res:// folders.

const PIECE_TYPE_PATHS: PackedStringArray = [
	"res://resources/piece_types/normal.tres",
	"res://resources/piece_types/prism.tres",
	"res://resources/piece_types/coin.tres",
	"res://resources/piece_types/ember.tres",
	"res://resources/piece_types/shard.tres",
]

const MODIFIER_PATHS: PackedStringArray = [
	"res://resources/modifiers/bounty.tres",
	"res://resources/modifiers/deposit.tres",
	"res://resources/modifiers/detonate.tres",
	"res://resources/modifiers/echo.tres",
	"res://resources/modifiers/ignite.tres",
	"res://resources/modifiers/magnet.tres",
	"res://resources/modifiers/ripple.tres",
	"res://resources/modifiers/surge.tres",
]

const RELIC_PATHS: PackedStringArray = [
	"res://resources/relics/almanac.tres",
	"res://resources/relics/cartographer.tres",
	"res://resources/relics/compass.tres",
	"res://resources/relics/cushion.tres",
	"res://resources/relics/echo_chamber.tres",
	"res://resources/relics/forge.tres",
	"res://resources/relics/lens.tres",
	"res://resources/relics/momentum.tres",
	"res://resources/relics/patron.tres",
	"res://resources/relics/stockpile.tres",
]

var _piece_types: Dictionary = {}
var _modifiers: Dictionary = {}
var _relics: Dictionary = {}


func _ready() -> void:
	reload_all()


func reload_all() -> void:
	_piece_types.clear()
	_modifiers.clear()
	_relics.clear()
	var from_dir := 0
	from_dir += _load_dir("res://resources/piece_types/", _piece_types)
	from_dir += _load_dir("res://resources/modifiers/", _modifiers)
	from_dir += _load_dir("res://resources/relics/", _relics)
	_load_paths(PIECE_TYPE_PATHS, _piece_types)
	_load_paths(MODIFIER_PATHS, _modifiers)
	_load_paths(RELIC_PATHS, _relics)
	if _piece_types.is_empty() or _modifiers.is_empty() or _relics.is_empty():
		push_error(
			"DataRegistry: failed to load game data (types=%d mods=%d relics=%d, dir_hits=%d)"
			% [_piece_types.size(), _modifiers.size(), _relics.size(), from_dir]
		)


func ensure_loaded() -> void:
	if _piece_types.is_empty() or _modifiers.is_empty() or _relics.is_empty():
		reload_all()


func get_piece_type(id: String) -> PieceTypeData:
	ensure_loaded()
	return _piece_types.get(id, null) as PieceTypeData


func get_modifier(id: String) -> ModifierData:
	ensure_loaded()
	return _modifiers.get(id, null) as ModifierData


func get_relic(id: String) -> RelicData:
	ensure_loaded()
	return _relics.get(id, null) as RelicData


func get_all_piece_types() -> Array:
	ensure_loaded()
	return _piece_types.values()


func get_all_modifiers() -> Array:
	ensure_loaded()
	return _modifiers.values()


func get_all_relics() -> Array:
	ensure_loaded()
	return _relics.values()


func _load_paths(paths: PackedStringArray, table: Dictionary) -> void:
	for path in paths:
		_register(load(path) as Resource, table)


func _load_dir(path: String, table: Dictionary) -> int:
	var count := 0
	var dir := DirAccess.open(path)
	if dir == null:
		return count
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if fname.ends_with(".tres"):
			if _register(load(path + fname) as Resource, table):
				count += 1
		fname = dir.get_next()
	dir.list_dir_end()
	return count


func _register(res: Resource, table: Dictionary) -> bool:
	if res == null:
		return false
	var entry_id := ""
	if res is PieceTypeData:
		entry_id = (res as PieceTypeData).id
	elif res is ModifierData:
		entry_id = (res as ModifierData).id
	elif res is RelicData:
		entry_id = (res as RelicData).id
	elif "id" in res:
		entry_id = str(res.get("id"))
	if entry_id.is_empty():
		return false
	if table.has(entry_id):
		return false
	table[entry_id] = res
	return true
