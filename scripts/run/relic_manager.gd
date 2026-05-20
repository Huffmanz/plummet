class_name RelicManager extends RefCounted

const MAX_RELICS: int = 4

var _relics: Array[String] = []
var _cushion_used: bool = false
var _patron_used: bool = false
var _forge_used_this_shop: bool = false


func add_relic(relic_id: String) -> bool:
	if _relics.size() >= MAX_RELICS:
		return false
	_relics.append(relic_id)
	return true


func has_relic(relic_id: String) -> bool:
	return _relics.has(relic_id)


func get_active_relics() -> Array[String]:
	return _relics.duplicate()


func relic_count() -> int:
	return _relics.size()


func can_add_relic() -> bool:
	return _relics.size() < MAX_RELICS


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
