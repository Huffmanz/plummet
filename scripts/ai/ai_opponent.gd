class_name AIOpponent extends RefCounted

# 8 directions for adjacent-piece counting (all 4 run axes, both ways).
const _ADJACENT_DIRS: Array[Vector2i] = [
	Vector2i(1, 0),  Vector2i(-1, 0),
	Vector2i(0, 1),  Vector2i(0, -1),
	Vector2i(1, 1),  Vector2i(-1, -1),
	Vector2i(1, -1), Vector2i(-1, 1),
]

# Probability [0.0, 1.0] of replacing the top-scored column with a random valid column.
var noise: float = 0.0

# AI piece queue — current and next piece, hidden from the player.
var current_piece: Piece
var next_piece: Piece

# Gimmick hooks — registered by enemy scripts (feature 08).
var _on_turn_start_hooks: Array[Callable] = []
var _on_column_selected_hooks: Array[Callable] = []
var _on_piece_landed_hooks: Array[Callable] = []
var _on_cascade_complete_hooks: Array[Callable] = []
var _on_player_turn_start_hooks: Array[Callable] = []
var _on_player_piece_landed_hooks: Array[Callable] = []


func _init(p_noise: float = 0.0) -> void:
	noise = p_noise
	current_piece = Piece.new(Piece.Owner.AI)
	next_piece = Piece.new(Piece.Owner.AI)


# --- Hook registration ---

func register_on_turn_start(hook: Callable) -> void:
	_on_turn_start_hooks.append(hook)

func register_on_column_selected(hook: Callable) -> void:
	_on_column_selected_hooks.append(hook)

func register_on_piece_landed(hook: Callable) -> void:
	_on_piece_landed_hooks.append(hook)

func register_on_cascade_complete(hook: Callable) -> void:
	_on_cascade_complete_hooks.append(hook)

func register_on_player_turn_start(hook: Callable) -> void:
	_on_player_turn_start_hooks.append(hook)

func register_on_player_piece_landed(hook: Callable) -> void:
	_on_player_piece_landed_hooks.append(hook)


# --- Hook firing (called externally for player-side hooks) ---

func fire_on_piece_landed(board: BoardEngine, col: int, row: int) -> void:
	_fire_hooks(_on_piece_landed_hooks, [board, col, row])

func fire_on_cascade_complete(board: BoardEngine, result: CascadeResult) -> void:
	_fire_hooks(_on_cascade_complete_hooks, [board, result])

func fire_on_player_turn_start(board: BoardEngine) -> void:
	_fire_hooks(_on_player_turn_start_hooks, [board])

func fire_on_player_piece_landed(board: BoardEngine, col: int, row: int) -> void:
	_fire_hooks(_on_player_piece_landed_hooks, [board, col, row])


# --- Column selection ---

# Returns the column to drop into, or -1 if all columns are full (match ends).
# Fires on_turn_start and on_column_selected hooks internally.
func choose_column(board: BoardEngine) -> int:
	_fire_hooks(_on_turn_start_hooks, [board])

	var valid_cols: Array[int] = []
	for c in BoardEngine.COLS:
		if not board.is_column_full(c):
			valid_cols.append(c)

	if valid_cols.is_empty():
		return -1

	var chosen: int
	if noise > 0.0 and randf() < noise:
		chosen = valid_cols[randi() % valid_cols.size()]
	else:
		chosen = _pick_best_column(board, valid_cols)

	chosen = _fire_column_selected_hooks(board, chosen)
	return chosen


# Advance the piece queue — call after dropping current_piece.
func advance_queue() -> void:
	current_piece = next_piece
	next_piece = Piece.new(Piece.Owner.AI)


# --- Internals ---

func _pick_best_column(board: BoardEngine, valid_cols: Array[int]) -> int:
	var scores: Array[float] = []
	for c in valid_cols:
		scores.append(_score_column(board, c))

	var max_score: float = scores[0]
	for s in scores:
		if s > max_score:
			max_score = s

	var best: Array[int] = []
	for i in valid_cols.size():
		if scores[i] == max_score:
			best.append(valid_cols[i])

	return best[randi() % best.size()]


# One-ply heuristic: simulate drop and score the resulting board state.
func _score_column(board: BoardEngine, col: int) -> float:
	var landing_row: int = board.get_landing_row(col)
	if landing_row == -1:
		return -INF

	var score: float = 0.0

	# Column height penalty: -10 per row above the halfway mark.
	var half: int = BoardEngine.ROWS / 2
	if landing_row > half:
		score -= float(landing_row - half) * 10.0

	# Extend AI line: reward adjacent same-color pieces that form a longer run.
	score += float(_count_adjacent_owner(board, col, landing_row, Piece.Owner.AI)) * 100.0

	# Block player clear: would a player piece here create a player run?
	var player_piece: Piece = Piece.new(Piece.Owner.PLAYER)
	board.set_cell(col, landing_row, player_piece)
	for run in board.detect_clears():
		if run.owner == Piece.Owner.PLAYER:
			score += 1200.0 if run.cells.size() >= 5 else 800.0
	board.set_cell(col, landing_row, null)

	# AI clear: does placing our piece create an AI run?
	var ai_piece: Piece = Piece.new(Piece.Owner.AI)
	board.set_cell(col, landing_row, ai_piece)
	for run in board.detect_clears():
		if run.owner == Piece.Owner.AI:
			score += 1500.0 if run.cells.size() >= 5 else 1000.0

	# Give player a clear: with our piece placed, can the player immediately clear any column?
	var gives_player_clear: bool = false
	for c in BoardEngine.COLS:
		if gives_player_clear:
			break
		if board.is_column_full(c):
			continue
		var pr: int = board.get_landing_row(c)
		if pr == -1:
			continue
		var pp: Piece = Piece.new(Piece.Owner.PLAYER)
		board.set_cell(c, pr, pp)
		for run in board.detect_clears():
			if run.owner == Piece.Owner.PLAYER:
				gives_player_clear = true
				break
		board.set_cell(c, pr, null)

	board.set_cell(col, landing_row, null)  # Undo AI piece.

	if gives_player_clear:
		score -= 500.0

	return score


func _count_adjacent_owner(board: BoardEngine, col: int, row: int, owner: Piece.Owner) -> int:
	var count: int = 0
	for dir in _ADJACENT_DIRS:
		var nc: int = col + dir.x
		var nr: int = row + dir.y
		if nc < 0 or nc >= BoardEngine.COLS or nr < 0 or nr >= BoardEngine.ROWS:
			continue
		var cell: Piece = board.get_cell(nc, nr)
		if cell != null and cell.owner == owner:
			count += 1
	return count


func _fire_hooks(hooks: Array[Callable], args: Array) -> void:
	for hook in hooks:
		hook.callv(args)


# on_column_selected hooks return a new column int to override; any other return is ignored.
func _fire_column_selected_hooks(board: BoardEngine, col: int) -> int:
	var result: int = col
	for hook in _on_column_selected_hooks:
		var ret = hook.call(board, result)
		if ret is int and ret >= 0 and ret < BoardEngine.COLS and not board.is_column_full(ret):
			result = ret
	return result
