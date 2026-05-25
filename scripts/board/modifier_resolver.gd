class_name ModifierResolver extends RefCounted

var _last_col: int = -1
var _last_row: int = -1
var _last_piece: Piece = null

# Echo: pending copies to drop after current clear resolves
var _echo_pending: Array = []

# Chips earned this turn from landing modifiers (Deposit)
var _landing_chip_bonus: int = 0
# Chips earned from clear modifiers this cascade round (Surge)
var _clear_chip_bonus: int = 0
var _match_clear_chips: int = 0

# Bounty points earned from clear modifiers (current cascade round)
var _clear_point_bonus: int = 0
# Sum of clear modifier points for the active player drop (all cascade rounds)
var _match_clear_bonus: int = 0

# Callback: func(chips: int) - called when landing chips are earned
var on_chips_earned: Callable = Callable()


func set_landed(col: int, row: int, piece: Piece) -> void:
	_last_col = col
	_last_row = row
	_last_piece = piece
	_landing_chip_bonus = 0
	_clear_point_bonus = 0
	_match_clear_bonus = 0
	_clear_chip_bonus = 0
	_match_clear_chips = 0


# Returns chips earned from landing modifiers.
func on_land(board: BoardEngine) -> int:
	_landing_chip_bonus = 0
	if _last_piece == null or not _last_piece.has_modifier():
		return 0
	match _last_piece.modifier:
		"Magnet":
			if _apply_magnet(board):
				board.apply_gravity()
		"Deposit":
			_landing_chip_bonus = 5
		"Ripple":
			_apply_ripple(board)
	return _landing_chip_bonus


# Returns bonus points earned from clear modifiers.
# echo_copy_count controls how many copies Echo drops (1 normally, 2 with Echo Chamber relic).
func on_clear(board: BoardEngine, runs: Array[MatchedRun], echo_copy_count: int = 1) -> int:
	var round_bonus := 0
	var round_chips := 0
	for run in runs:
		for cell_pos: Vector2i in run.cells:
			var piece: Piece = board.get_cell(cell_pos.x, cell_pos.y)
			if piece == null or piece.owner != Piece.Owner.PLAYER or not piece.has_modifier():
				continue
			match piece.modifier:
				"Echo":
					for _i in echo_copy_count:
						_echo_pending.append(Piece.new(Piece.Owner.PLAYER, piece.type))
				"Bounty":
					round_bonus += _count_bounty(board, cell_pos.y)
	for run in runs:
		if run.owner == Piece.Owner.PLAYER:
			round_bonus += _ignite_overlength_bonus(board, run)
			round_chips += surge_chips_for_run(board, run)
	_clear_point_bonus = round_bonus
	_match_clear_bonus += round_bonus
	_clear_chip_bonus = round_chips
	_match_clear_chips += round_chips
	return round_bonus


func on_pre_gravity(_board: BoardEngine) -> void:
	pass


# Returns pending Echo pieces and clears the queue. Caller must call
# find_echo_target(board) fresh before placing each piece so column selection
# re-evaluates after every drop.
func pop_echo_pieces() -> Array[Piece]:
	var pieces: Array[Piece] = []
	for p: Piece in _echo_pending:
		pieces.append(p)
	_echo_pending.clear()
	return pieces


func find_echo_target(board: BoardEngine) -> int:
	return _find_echo_target(board)


func detonate_rows_from_runs(board: BoardEngine, runs: Array[MatchedRun]) -> Array[int]:
	var rows: Dictionary = {}
	for run in runs:
		for cell_pos: Vector2i in run.cells:
			var piece: Piece = board.get_cell(cell_pos.x, cell_pos.y)
			if piece != null and piece.owner == Piece.Owner.PLAYER and piece.modifier == "Detonate":
				rows[cell_pos.y] = true
	var row_list: Array[int] = []
	for row: int in rows:
		row_list.append(row)
	return row_list


func apply_detonate_from_runs(board: BoardEngine, runs: Array[MatchedRun]) -> void:
	for row: int in detonate_rows_from_runs(board, runs):
		_apply_detonate(board, row)


func get_accumulated_bonus_points() -> int:
	return _match_clear_bonus


func get_accumulated_clear_chips() -> int:
	return _match_clear_chips


# Chips earned when a Surge piece is part of this clear (= line length).
func surge_chips_for_run(board: BoardEngine, run: MatchedRun) -> int:
	if run.owner != Piece.Owner.PLAYER or not _run_has_modifier(board, run, "Surge"):
		return 0
	return run.cells.size()


func _run_has_modifier(board: BoardEngine, run: MatchedRun, modifier_id: String) -> bool:
	for cell_pos: Vector2i in run.cells:
		var piece: Piece = board.get_cell(cell_pos.x, cell_pos.y)
		if piece != null and piece.owner == Piece.Owner.PLAYER and piece.modifier == modifier_id:
			return true
	return false


# AI cell positions for +10 Bounty popups (call before on_clear — Detonate may clear the row).
# Cells in this clear beyond the 4th (5th, 6th, …) when an Ignite piece is in the run.
func ignite_popup_cells_for_run(board: BoardEngine, run: MatchedRun) -> Array[Vector2i]:
	var targets: Array[Vector2i] = []
	if _ignite_overlength_bonus(board, run) <= 0:
		return targets
	for i in range(4, run.cells.size()):
		targets.append(run.cells[i])
	return targets


func bounty_popup_cells_for_run(board: BoardEngine, run: MatchedRun) -> Array[Vector2i]:
	var targets: Array[Vector2i] = []
	for cell_pos: Vector2i in run.cells:
		var piece: Piece = board.get_cell(cell_pos.x, cell_pos.y)
		if piece == null or piece.owner != Piece.Owner.PLAYER or piece.modifier != "Bounty":
			continue
		for c in BoardEngine.COLS:
			var opponent: Piece = board.get_cell(c, cell_pos.y)
			if opponent != null and opponent.owner == Piece.Owner.AI:
				targets.append(Vector2i(c, cell_pos.y))
	return targets


func _ignite_overlength_bonus(board: BoardEngine, run: MatchedRun) -> int:
	if run.owner != Piece.Owner.PLAYER or not _run_has_modifier(board, run, "Ignite"):
		return 0
	var excess := maxi(0, run.cells.size() - 4)
	return excess * 100


# Slides the nearest same-color piece in the same row one step toward this piece.
# Returns true if a slide occurred.
func _apply_magnet(board: BoardEngine) -> bool:
	if _last_col < 0 or _last_row < 0:
		return false
	var row := _last_row
	var best_col := -1
	var best_dist := BoardEngine.COLS + 1
	for c in range(_last_col - 1, -1, -1):
		var p: Piece = board.get_cell(c, row)
		if p != null:
			if p.owner == Piece.Owner.PLAYER:
				var dist := _last_col - c
				if dist < best_dist:
					best_dist = dist
					best_col = c
			break
	for c in range(_last_col + 1, BoardEngine.COLS):
		var p: Piece = board.get_cell(c, row)
		if p != null:
			if p.owner == Piece.Owner.PLAYER:
				var dist := c - _last_col
				if dist < best_dist:
					best_dist = dist
					best_col = c
			break
	if best_col < 0:
		return false
	var slide_dir: int = signi(_last_col - best_col)
	var new_col: int = best_col + slide_dir
	if new_col == _last_col:
		return false
	if board.get_cell(new_col, row) != null:
		return false
	board.set_cell(new_col, row, board.get_cell(best_col, row))
	board.set_cell(best_col, row, null)
	return true


# Pushes each orthogonal neighbor one cell away from the landing position if that cell is empty.
func _apply_ripple(board: BoardEngine) -> void:
	if _last_col < 0 or _last_row < 0:
		return
	var dirs: Array[Vector2i] = [
		Vector2i(-1, 0),
		Vector2i(1, 0),
		Vector2i(0, -1),
		Vector2i(0, 1),
	]
	for dir: Vector2i in dirs:
		var adj_col: int = _last_col + dir.x
		var adj_row: int = _last_row + dir.y
		if not _cell_in_bounds(adj_col, adj_row):
			continue
		var piece: Piece = board.get_cell(adj_col, adj_row)
		if piece == null:
			continue
		var dest_col: int = adj_col + dir.x
		var dest_row: int = adj_row + dir.y
		if not _cell_in_bounds(dest_col, dest_row):
			continue
		if board.get_cell(dest_col, dest_row) != null:
			continue
		board.set_cell(dest_col, dest_row, piece)
		board.set_cell(adj_col, adj_row, null)
	board.apply_gravity()


func _cell_in_bounds(col: int, row: int) -> bool:
	return col >= 0 and col < BoardEngine.COLS and row >= 0 and row < BoardEngine.ROWS


# Removes all pieces in the specified row.
func _apply_detonate(board: BoardEngine, row: int) -> void:
	for c in BoardEngine.COLS:
		var p: Piece = board.get_cell(c, row)
		if p != null and p.type != Piece.Type.LOCKED:
			board.set_cell(c, row, null)


# Counts opponent pieces in the given row for Bounty scoring.
func _count_bounty(board: BoardEngine, row: int) -> int:
	var count := 0
	for c in BoardEngine.COLS:
		var p: Piece = board.get_cell(c, row)
		if p != null and p.owner == Piece.Owner.AI:
			count += 1
	return count * 10


# Finds the column with fewest total pieces for Echo targeting.
func _find_echo_target(board: BoardEngine) -> int:
	var min_count := BoardEngine.ROWS + 1
	var best_col := -1
	for c in BoardEngine.COLS:
		if board.is_column_full(c):
			continue
		var count := 0
		for r in BoardEngine.ROWS:
			if board.get_cell(c, r) != null:
				count += 1
		if count < min_count:
			min_count = count
			best_col = c
	return best_col
