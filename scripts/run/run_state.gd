class_name RunState extends RefCounted

var act: int = 1
var match_in_act: int = 1
var regular_wins: int = 0
var bosses_defeated: int = 0
var fragments_earned: int = 0
var total_score: int = 0
var last_match_score: int = 0
var highest_cascade: int = 0
var cross_color_count: int = 0
var player_bag: PieceBag
var chip_count: int = 0
var win_streak: int = 0
var relic_manager: RelicManager


func _init() -> void:
	relic_manager = RelicManager.new()


func is_boss_match() -> bool:
	return match_in_act == 4


func is_run_complete() -> bool:
	return act > 3


func total_matches_played() -> int:
	return (act - 1) * 4 + match_in_act - 1
