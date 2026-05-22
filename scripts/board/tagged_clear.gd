class_name TaggedClear extends RefCounted

var run: MatchedRun
var depth: int  # cascade round index for exponential multiplier base
var ember_bonus: int = 0  # linear +1 per Ember in this clear and carry from earlier clears
var has_prism: bool = false  # at least one Prism piece in this clear
var coin_chips: int = 0     # chips from Coin pieces in this clear (+3 each)


func _init(p_run: MatchedRun, p_depth: int) -> void:
	run = p_run
	depth = p_depth
