class_name TaggedClear extends RefCounted

var run: MatchedRun
var depth: int
var has_prism: bool = false  # at least one Prism piece in this clear
var has_surge: bool = false  # the clearing piece has an active Surge bonus
var coin_chips: int = 0     # chips from Coin pieces in this clear (+3 each)


func _init(p_run: MatchedRun, p_depth: int) -> void:
	run = p_run
	depth = p_depth
