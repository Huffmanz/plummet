class_name MatchResult extends RefCounted

# winner is only meaningful when is_tie == false
var winner: Piece.Owner = Piece.Owner.PLAYER
var player_score: int = 0
var ai_score: int = 0
var is_tie: bool = false
var rounds: Array[TurnScore] = []
