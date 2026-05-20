class_name ModifierResolver extends RefCounted

var _last_col: int = -1
var _last_row: int = -1
var _last_piece: Piece = null

# Ignite: maps cell position -> bonus depth for next clear
var _ignite_bonuses: Dictionary = {}

# Echo: pending copies to drop after current clear resolves
var _echo_pending: Array = []

# Surge: if active, the next piece's base clear value is ×3 if it clears on landing
var _surge_active: bool = false

# Chips earned this turn from landing modifiers (Deposit)
var _landing_chip_bonus: int = 0

# Bounty points earned from clear modifiers
var _clear_point_bonus: int = 0

# Callback: func(chips: int) - called when landing chips are earned
var on_chips_earned: Callable = Callable()


func set_landed(col: int, row: int, piece: Piece) -> void:
	_last_col = col
	_last_row = row
	_last_piece = piece
	_landing_chip_bonus = 0
	_clear_point_bonus = 0


# Returns chips earned from landing modifiers.
func on_land(board: BoardEngine) -> int:
	_landing_chip_bonus = 0
	if _last_piece == null or not _last_piece.has_modifier():
		return 0
	match _last_piece.modifier:
		"Ignite":
			_apply_ignite(board)
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
	_clear_point_bonus = 0
	for run in runs:
		for cell_pos: Vector2i in run.cells:
			var piece: Piece = board.get_cell(cell_pos.x, cell_pos.y)
			if piece == null or piece.owner != Piece.Owner.PLAYER or not piece.has_modifier():
				continue
			match piece.modifier:
				"Echo":
					var echo_col := _find_echo_target(board)
					if echo_col >= 0:
						for _i in echo_copy_count:
							_echo_pending.append({col = echo_col, piece = Piece.new(Piece.Owner.PLAYER, piece.type)})
				"Detonate":
					_apply_detonate(board, cell_pos.y)
				"Bounty":
					_clear_point_bonus += _count_bounty(board, cell_pos.y)
				"Surge":
					_surge_active = true
	return _clear_point_bonus


func on_pre_gravity(_board: BoardEngine) -> void:
	pass


# Returns Array of {col, row} for each Echo piece dropped (for animation).
func on_gravity(board: BoardEngine) -> Array:
	var drops: Array = []
	for echo in _echo_pending:
		var target_col: int = echo.col
		if not board.is_column_full(target_col):
			var row: int = board.drop_piece(target_col, echo.piece)
			if row >= 0:
				drops.append({col = target_col, row = row})
	_echo_pending.clear()
	return drops


# Returns the Ignite bonus depth for a piece at (col, row). Consumes the bonus.
func consume_ignite_bonus(col: int, row: int) -> int:
	var key := Vector2i(col, row)
	var bonus: int = _ignite_bonuses.get(key, 0)
	if bonus > 0:
		_ignite_bonuses.erase(key)
	return bonus


func get_accumulated_bonus_points() -> int:
	return _clear_point_bonus


# Surge: check if the pending surge should apply, then clear it.
func consume_surge() -> bool:
	if _surge_active:
		_surge_active = false
		return true
	return false


func has_surge_pending() -> bool:
	return _surge_active


func _apply_ignite(board: BoardEngine) -> void:
	if _last_col < 0 or _last_row <= 0:
		return
	var below_row := _last_row - 1
	var target: Piece = board.get_cell(_last_col, below_row)
	if target == null:
		return
	var key := Vector2i(_last_col, below_row)
	_ignite_bonuses[key] = _ignite_bonuses.get(key, 0) + 1


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


# Pushes the two pieces below the landing position (the top of the existing stack)
# into adjacent columns — one left, one right.
func _apply_ripple(board: BoardEngine) -> void:
	if _last_col < 0 or _last_row <= 0:
		return
	var below1_row := _last_row - 1
	var below2_row := _last_row - 2
	var piece1: Piece = board.get_cell(_last_col, below1_row)
	var piece2: Piece = board.get_cell(_last_col, below2_row) if below2_row >= 0 else null
	if piece1 != null:
		var left_col := _last_col - 1
		if left_col >= 0 and not board.is_column_full(left_col):
			board.set_cell(_last_col, below1_row, null)
			board.drop_piece(left_col, piece1)
	if piece2 != null:
		var right_col := _last_col + 1
		if right_col < BoardEngine.COLS and not board.is_column_full(right_col):
			board.set_cell(_last_col, below2_row, null)
			board.drop_piece(right_col, piece2)
	board.apply_gravity()


# Removes all pieces in the specified row.
func _apply_detonate(board: BoardEngine, row: int) -> void:
	for c in BoardEngine.COLS:
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
