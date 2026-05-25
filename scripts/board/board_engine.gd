class_name BoardEngine extends RefCounted

signal piece_placed(col: int, row: int, piece: Piece)
signal pieces_cleared(runs: Array)
signal gravity_applied()

const COLS: int = 7
const ROWS: int = 12

# grid[col][row] = Piece or null
var _grid: Array = []

# Frozen columns cannot receive drops (enemy gimmick).
var frozen_columns: Dictionary = {}  # col -> turns_remaining

# When true, pieces fall toward row ROWS-1 (ceiling) instead of row 0.
var gravity_up: bool = false

# Direction vectors for clear detection: right, up, diagonal-up-right, diagonal-up-left
const _DIRECTIONS: Array[Vector2i] = [
	Vector2i(1, 0),
	Vector2i(0, 1),
	Vector2i(1, 1),
	Vector2i(1, -1),
]


func _init(cols: int = COLS, rows: int = ROWS) -> void:
	_init_grid(cols, rows)


func _init_grid(cols: int, rows: int) -> void:
	_grid = []
	for c in cols:
		var col: Array = []
		col.resize(rows)
		col.fill(null)
		_grid.append(col)


# Returns the row the piece landed on, or -1 if the column is full.
func drop_piece(col: int, piece: Piece) -> int:
	if is_column_frozen(col):
		return -1
	var landing_row: int = _lowest_empty_row(col)
	if landing_row < 0:
		return -1
	_grid[col][landing_row] = piece
	piece_placed.emit(col, landing_row, piece)
	return landing_row


func apply_gravity() -> void:
	var cols: int = _grid.size()
	for c in cols:
		_settle_column(c)
	gravity_applied.emit()


# Swap rows top↔bottom (Inverter board flip). Self-inverse — call again to undo.
func mirror_vertical() -> void:
	var rows: int = _grid[0].size()
	for c in _grid.size():
		for r in range(rows / 2):
			var mirror_r: int = rows - 1 - r
			var a: Piece = _grid[c][r]
			var b: Piece = _grid[c][mirror_r]
			_grid[c][r] = b
			_grid[c][mirror_r] = a


func freeze_column(col: int, turns: int) -> void:
	frozen_columns[col] = turns


func is_column_frozen(col: int) -> bool:
	return frozen_columns.has(col)


func tick_frozen_columns() -> void:
	var expired: Array[int] = []
	for col: int in frozen_columns:
		frozen_columns[col] -= 1
		if frozen_columns[col] <= 0:
			expired.append(col)
	for col in expired:
		frozen_columns.erase(col)


func detect_clears() -> Array[MatchedRun]:
	var runs: Array[MatchedRun] = []
	var cols: int = _grid.size()
	var rows: int = _grid[0].size()

	for dir in _DIRECTIONS:
		for c in cols:
			for r in rows:
				var cell: Piece = _grid[c][r]
				if not _is_matchable(cell):
					continue
				# Only process cells that are the start of a run in this direction.
				var prev_c: int = c - dir.x
				var prev_r: int = r - dir.y
				var prev: Piece = _grid[prev_c][prev_r] if _in_bounds(prev_c, prev_r) else null
				if _is_matchable(prev) and prev.owner == cell.owner:
					continue
				# Count run length.
				var run_cells: Array[Vector2i] = []
				var nc: int = c
				var nr: int = r
				while _in_bounds(nc, nr):
					var run_cell: Piece = _grid[nc][nr]
					if not _is_matchable(run_cell) or run_cell.owner != cell.owner:
						break
					run_cells.append(Vector2i(nc, nr))
					nc += dir.x
					nr += dir.y
				if run_cells.size() >= 4:
					runs.append(MatchedRun.new(cell.owner, run_cells))

	return runs


func remove_clears(runs: Array[MatchedRun]) -> void:
	var removed: Dictionary = {}
	for run in runs:
		for cell in run.cells:
			if not removed.has(cell):
				removed[cell] = true
				_grid[cell.x][cell.y] = null
	pieces_cleared.emit(runs)


func get_cell(col: int, row: int) -> Piece:
	return _grid[col][row]


func set_cell(col: int, row: int, piece: Piece) -> void:
	_grid[col][row] = piece


func get_landing_row(col: int) -> int:
	return _lowest_empty_row(col)


func is_column_near_full(col: int) -> bool:
	var landing := get_landing_row(col)
	if landing < 0:
		return true
	if gravity_up:
		return landing <= 1
	return landing >= ROWS - 2


# Returns the row a Ghost piece would land on: passes through the topmost occupied
# cell, then settles at the first available slot below it.
# Returns -1 if no valid landing exists (packed stack or top piece at floor).
func get_ghost_landing_row(col: int) -> int:
	var rows: int = _grid[col].size()
	var top_occupied := -1
	for r in range(rows - 1, -1, -1):
		if _grid[col][r] != null:
			top_occupied = r
			break
	if top_occupied < 0:
		return _lowest_empty_row(col)
	var next_occupied := -1
	for r in range(top_occupied - 1, -1, -1):
		if _grid[col][r] != null:
			next_occupied = r
			break
	var ghost_land: int = next_occupied + 1 if next_occupied >= 0 else 0
	if ghost_land >= top_occupied or _grid[col][ghost_land] != null:
		return -1
	return ghost_land


func drop_ghost_piece(col: int, piece: Piece) -> int:
	var ghost_row := get_ghost_landing_row(col)
	if ghost_row < 0:
		return -1
	_grid[col][ghost_row] = piece
	piece_placed.emit(col, ghost_row, piece)
	return ghost_row


func is_column_full(col: int) -> bool:
	return is_column_frozen(col) or _lowest_empty_row(col) < 0


func is_board_full() -> bool:
	for c in _grid.size():
		if not is_column_full(c):
			return false
	return true


# Next open slot in the current gravity direction.
func _lowest_empty_row(col: int) -> int:
	var rows: int = _grid[col].size()
	if gravity_up:
		# Stack hangs from the ceiling (row ROWS-1). Land in the topmost open cell.
		for r in range(rows - 1, -1, -1):
			if _grid[col][r] == null:
				return r
		return -1
	var highest_occupied := -1
	for r in rows:
		if _grid[col][r] != null:
			highest_occupied = r
	var landing_down := highest_occupied + 1
	if landing_down >= rows:
		return -1
	return landing_down


func _settle_column(col: int) -> void:
	var rows: int = _grid[col].size()
	var locked: Dictionary = {}
	var pieces: Array = []
	for r in rows:
		var cell: Piece = _grid[col][r]
		if cell != null and cell.type == Piece.Type.LOCKED:
			locked[r] = cell
		elif cell != null:
			pieces.append(cell)
	var slots: Array[int] = []
	if gravity_up:
		for r in range(rows - 1, -1, -1):
			if not locked.has(r):
				slots.append(r)
	else:
		for r in rows:
			if not locked.has(r):
				slots.append(r)
	for r in rows:
		_grid[col][r] = null
	for r in locked:
		_grid[col][r] = locked[r]
	for i in mini(pieces.size(), slots.size()):
		_grid[col][slots[i]] = pieces[i]


# Place a locked obstacle at the column floor (row 0), pushing pieces upward.
func place_locked_at_bottom(col: int) -> bool:
	var rows: int = _grid[col].size()
	if _grid[col][rows - 1] != null:
		return false
	for r in range(rows - 1, 0, -1):
		_grid[col][r] = _grid[col][r - 1]
	var locked := Piece.new(Piece.Owner.AI, Piece.Type.LOCKED)
	_grid[col][0] = locked
	return true


# Slide all columns one step; pieces off the edge are discarded.
func slide_contents(direction: int) -> void:
	var cols: int = _grid.size()
	var rows: int = _grid[0].size()
	var new_grid: Array = []
	for _c in cols:
		var col: Array = []
		col.resize(rows)
		col.fill(null)
		new_grid.append(col)
	for c in cols:
		var dest_c: int = c + direction
		if dest_c < 0 or dest_c >= cols:
			continue
		for r in rows:
			new_grid[dest_c][r] = _grid[c][r]
	_grid = new_grid


func _is_matchable(cell: Piece) -> bool:
	return cell != null and cell.type != Piece.Type.LOCKED


func _in_bounds(col: int, row: int) -> bool:
	return col >= 0 and col < _grid.size() and row >= 0 and row < _grid[0].size()
