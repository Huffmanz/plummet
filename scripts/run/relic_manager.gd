class_name RelicManager extends RefCounted

const MAX_RELICS: int = 4

var _relics: Array[String] = ["", "", "", ""]
var _cushion_used: bool = false
var _patron_used: bool = false
var _forge_used_this_shop: bool = false


func add_relic(relic_id: String, slot_idx: int = -1) -> bool:
	if slot_idx >= 0 and slot_idx < MAX_RELICS:
		if not _relics[slot_idx].is_empty():
			return false
		_relics[slot_idx] = relic_id
		return true
	for i in MAX_RELICS:
		if _relics[i].is_empty():
			_relics[i] = relic_id
			return true
	return false


func has_relic(relic_id: String) -> bool:
	return _relics.has(relic_id)


func get_active_relics() -> Array[String]:
	return _relics.duplicate()


func relic_count() -> int:
	var n := 0
	for r in _relics:
		if not r.is_empty():
			n += 1
	return n


func can_add_relic() -> bool:
	for r in _relics:
		if r.is_empty():
			return true
	return false


# Cushion: absorb one loss. Returns true if it activated.
func try_cushion() -> bool:
	if not has_relic("Cushion") or _cushion_used:
		return false
	_cushion_used = true
	return true


func is_cushion_spent() -> bool:
	return _cushion_used


# Patron: one free relic purchase per run.
func try_patron() -> bool:
	if not has_relic("Patron") or _patron_used:
		return false
	_patron_used = true
	return true


func is_patron_spent() -> bool:
	return _patron_used


# Forge: one free upgrade per shop visit — reset each visit.
func begin_shop_visit() -> void:
	_forge_used_this_shop = false


func try_forge() -> bool:
	if not has_relic("Forge") or _forge_used_this_shop:
		return false
	_forge_used_this_shop = true
	return true


func is_forge_spent_this_visit() -> bool:
	return _forge_used_this_shop


# Almanac: shop shows 4 offers instead of 3.
func offer_count() -> int:
	return 4 if has_relic("Almanac") else 3


# Stockpile: doubles per-clear chip earnings.
func chips_per_clear() -> int:
	return 2 if has_relic("Stockpile") else 1


# Echo Chamber: Echo drops 2 copies.
func echo_copy_count() -> int:
	return 2 if has_relic("EchoChamber") else 1


# Momentum: tracks consecutive wins for starting score bonus.
func momentum_bonus(win_streak: int) -> int:
	if not has_relic("Momentum") or win_streak <= 0:
		return 0
	return win_streak * 50


# Cartographer: bonus points when a placement does not clear.
func cartographer_placement_bonus() -> int:
	return 5 if has_relic("Cartographer") else 0


# Compass: bonus points when a placement blocks an opponent line.
func compass_block_bonus() -> int:
	return 30 if has_relic("Compass") else 0


# Lens: chips earned when the opponent blocks your line.
func lens_blocked_chips() -> int:
	return 2 if has_relic("Lens") else 0
