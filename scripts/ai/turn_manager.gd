class_name TurnManager extends RefCounted

signal player_turn_started(turns_remaining: int)
signal ai_turn_started(turns_remaining: int)
signal match_ended(reason: MatchEndReason)

enum MatchEndReason { TURNS_EXHAUSTED, BOARD_FULL }

const TURNS_PER_PLAYER: int = 40

var player_turns_remaining: int = TURNS_PER_PLAYER
var ai_turns_remaining: int = TURNS_PER_PLAYER
var current_turn: Piece.Owner = Piece.Owner.PLAYER

var _active: bool = false


# Emit the first player_turn_started signal to kick off the match.
func start() -> void:
	_active = true
	player_turn_started.emit(player_turns_remaining)


# Call after the current player's piece has landed and all cascades are resolved.
# Decrements the current player's turn counter, checks end conditions, then
# signals whose turn it is next.
func advance(board: BoardEngine) -> void:
	if not _active:
		return

	if current_turn == Piece.Owner.PLAYER:
		player_turns_remaining -= 1
	else:
		ai_turns_remaining -= 1

	if board.is_board_full():
		_active = false
		match_ended.emit(MatchEndReason.BOARD_FULL)
		return

	if player_turns_remaining <= 0 and ai_turns_remaining <= 0:
		_active = false
		match_ended.emit(MatchEndReason.TURNS_EXHAUSTED)
		return

	if current_turn == Piece.Owner.PLAYER:
		current_turn = Piece.Owner.AI
		ai_turn_started.emit(ai_turns_remaining)
	else:
		current_turn = Piece.Owner.PLAYER
		player_turn_started.emit(player_turns_remaining)


# Call when AIOpponent.choose_column() returns -1 (board full on AI's turn).
func on_ai_skipped() -> void:
	if not _active:
		return
	_active = false
	match_ended.emit(MatchEndReason.BOARD_FULL)
