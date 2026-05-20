class_name BoardEngine extends RefCounted

signal piece_placed(col: int, row: int, piece: Piece)
signal pieces_cleared(runs: Array)
signal gravity_applied()

const COLS: int = 7
const ROWS: int = 12

# grid[col][row] = Piece or null
var _grid: Array = []

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


func detect_clears() -> Array[MatchedRun]:
	var runs: Array[MatchedRun] = []
	var cols: int = _grid.size()
	var rows: int = _grid[0].size()

	for dir in _DIRECTIONS:
		for c in cols:
			for r in rows:
				var cell: Piece = _grid[c][r]
				if cell == null:
					continue
				# Only process cells that are the start of a run in this direction.
				var prev_c: int = c - dir.x
				var prev_r: int = r - dir.y
				if _in_bounds(prev_c, prev_r) and _grid[prev_c][prev_r] != null \
						and _grid[prev_c][prev_r].owner == cell.owner:
					continue
				# Count run length.
				var run_cells: Array[Vector2i] = []
				var nc: int = c
				var nr: int = r
				while _in_bounds(nc, nr) and _grid[nc][nr] != null \
						and _grid[nc][nr].owner == cell.owner:
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
	return _lowest_empty_row(col) < 0


func is_board_full() -> bool:
	for c in _grid.size():
		if not is_column_full(c):
			return false
	return true


# Next open slot above the stack top (row 0 = floor). Ignores internal gaps from Anchor etc.
func _lowest_empty_row(col: int) -> int:
	var rows: int = _grid[col].size()
	var highest_occupied := -1
	for r in rows:
		if _grid[col][r] != null:
			highest_occupied = r
	var landing := highest_occupied + 1
	if landing >= rows:
		return -1
	return landing


func _settle_column(col: int) -> void:
	var rows: int = _grid[col].size()
	var pieces: Array = []
	for r in rows:
		if _grid[col][r] != null:
			pieces.append(_grid[col][r])
	for r in rows:
		_grid[col][r] = pieces[r] if r < pieces.size() else null


func _in_bounds(col: int, row: int) -> bool:
	return col >= 0 and col < _grid.size() and row >= 0 and row < _grid[0].size()
