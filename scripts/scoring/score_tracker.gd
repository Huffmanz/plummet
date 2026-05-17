class_name ScoreTracker extends RefCounted

signal score_changed(player_score: int, ai_score: int, player_delta: int, ai_delta: int)

var player_score: int = 0
var ai_score: int = 0
var player_delta: int = 0
var ai_delta: int = 0

var _rounds: Array[TurnScore] = []


func add_turn(turn: TurnScore) -> void:
	player_delta = turn.player_points
	ai_delta = turn.ai_points
	player_score += player_delta
	ai_score += ai_delta
	_rounds.append(turn)
	score_changed.emit(player_score, ai_score, player_delta, ai_delta)


func get_match_result() -> MatchResult:
	var result := MatchResult.new()
	result.player_score = player_score
	result.ai_score = ai_score
	result.rounds = _rounds.duplicate()
	if player_score > ai_score:
		result.winner = Piece.Owner.PLAYER
	elif ai_score > player_score:
		result.winner = Piece.Owner.AI
	else:
		result.is_tie = true
	return result
