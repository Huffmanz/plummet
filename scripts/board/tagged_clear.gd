class_name TaggedClear extends RefCounted

var run: MatchedRun
var depth: int


func _init(p_run: MatchedRun, p_depth: int) -> void:
	run = p_run
	depth = p_depth
