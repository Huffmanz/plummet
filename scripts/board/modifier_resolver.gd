class_name ModifierResolver extends RefCounted

var _last_col: int = -1
var _last_row: int = -1
var _last_piece: Piece = null
var _catalyst_active: bool = false
var _echo_pending: Array = []
var _anchor_saves: Array = []


func set_landed(col: int, row: int, piece: Piece) -> void:
	_last_col = col
	_last_row = row
	_last_piece = piece


# Landing effects: Heavy, Magnet, Catalyst. Catalyst sets flag for next drop.
func on_land(board: BoardEngine) -> void:
	if _last_piece == null:
		return
	var was_catalyst := _catalyst_active
	_catalyst_active = false
	var fire_count := 2 if was_catalyst else 1
	for _i in fire_count:
		for mod: String in _last_piece.modifiers:
			match mod:
				"Heavy":
					_apply_heavy(board)
				"Magnet":
					_apply_magnet(board)
				"Catalyst":
					_catalyst_active = true


# Clear effects: Echo queues a copy; Volatile removes orthogonal neighbors.
func on_clear(board: BoardEngine, runs: Array[MatchedRun]) -> void:
	for run in runs:
		for cell_pos: Vector2i in run.cells:
			var piece: Piece = board.get_cell(cell_pos.x, cell_pos.y)
			if piece == null or piece.owner != Piece.Owner.PLAYER:
				continue
			for mod: String in piece.modifiers:
				match mod:
					"Echo":
						var echo_col := _find_echo_target(board)
						if echo_col >= 0:
							_echo_pending.append({col = echo_col, piece = Piece.new(Piece.Owner.PLAYER)})
					"Volatile":
						_apply_volatile(board, cell_pos)


# Save anchor pieces before gravity so they won't be compacted downward.
func on_pre_gravity(board: BoardEngine) -> void:
	_anchor_saves.clear()
	for c in BoardEngine.COLS:
		for r in BoardEngine.ROWS:
			var piece: Piece = board.get_cell(c, r)
			if piece != null and "Anchor" in piece.modifiers:
				_anchor_saves.append({col = c, row = r, piece = piece})
				board.set_cell(c, r, null)


# Restore anchors at their original rows; drop queued echo copies.
func on_gravity(board: BoardEngine) -> void:
	for save in _anchor_saves:
		_restore_anchor(board, save.col, save.row, save.piece)
	_anchor_saves.clear()
	for echo in _echo_pending:
		var target_col: int = echo.col
		if not board.is_column_full(target_col):
			board.drop_piece(target_col, echo.piece)
	_echo_pending.clear()


func _restore_anchor(board: BoardEngine, col: int, row: int, piece: Piece) -> void:
	if board.get_cell(col, row) == null:
		board.set_cell(col, row, piece)
		return
	# A falling piece landed in the anchor's cell — push pieces up to make room.
	var top := row
	while top < BoardEngine.ROWS and board.get_cell(col, top) != null:
		top += 1
	if top >= BoardEngine.ROWS:
		return  # column full, anchor is lost (extreme edge case)
	var r := top
	while r > row:
		board.set_cell(col, r, board.get_cell(col, r - 1))
		r -= 1
	board.set_cell(col, row, piece)


func _apply_heavy(board: BoardEngine) -> void:
	if _last_col < 0 or _last_row <= 0:
		return
	var below_row := _last_row - 1
	var target: Piece = board.get_cell(_last_col, below_row)
	if target == null:
		return
	var dest_row := below_row - 1
	if dest_row < 0:
		return
	if board.get_cell(_last_col, dest_row) != null:
		return
	board.set_cell(_last_col, dest_row, target)
	board.set_cell(_last_col, below_row, null)


# Scans left and right for the closest player piece at distance >= 2,
# then slides it one step toward the magnet's column.
func _apply_magnet(board: BoardEngine) -> void:
	if _last_col < 0 or _last_row < 0:
		return
	var row := _last_row
	var best_col := -1
	var best_dist := BoardEngine.COLS + 1
	for c in range(_last_col - 2, -1, -1):
		var p: Piece = board.get_cell(c, row)
		if p != null:
			if p.owner == Piece.Owner.PLAYER:
				var dist := _last_col - c
				if dist < best_dist:
					best_dist = dist
					best_col = c
			break
	for c in range(_last_col + 2, BoardEngine.COLS):
		var p: Piece = board.get_cell(c, row)
		if p != null:
			if p.owner == Piece.Owner.PLAYER:
				var dist := c - _last_col
				if dist < best_dist:
					best_dist = dist
					best_col = c
			break
	if best_col < 0:
		return
	var slide_dir: int = signi(_last_col - best_col)
	var new_col: int = best_col + slide_dir
	if board.get_cell(new_col, row) != null:
		return
	board.set_cell(new_col, row, board.get_cell(best_col, row))
	board.set_cell(best_col, row, null)


func _apply_volatile(board: BoardEngine, cell_pos: Vector2i) -> void:
	var dirs: Array[Vector2i] = [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]
	for dir in dirs:
		var nc := cell_pos + dir
		if nc.x < 0 or nc.x >= BoardEngine.COLS or nc.y < 0 or nc.y >= BoardEngine.ROWS:
			continue
		board.set_cell(nc.x, nc.y, null)


func _find_echo_target(board: BoardEngine) -> int:
	var max_count := 0
	var best_col := -1
	for c in BoardEngine.COLS:
		var count := 0
		for r in BoardEngine.ROWS:
			var p: Piece = board.get_cell(c, r)
			if p != null and p.owner == Piece.Owner.AI:
				count += 1
		if count > max_count:
			max_count = count
			best_col = c
	return best_col
