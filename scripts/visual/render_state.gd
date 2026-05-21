class_name RenderState extends RefCounted

const COLS: int = 7
const ROWS: int = BoardEngine.ROWS

var cells: Array[CellState] = []
var active_piece: QueueEntry = QueueEntry.new()
var player_queue: Array[QueueEntry] = []
var player_score: int = 0
var ai_score: int = 0
var score_delta: int = 0
var active_player: CellState.Occupant = CellState.Occupant.PLAYER
var player_turns_remaining: int = 40
var ai_turns_remaining: int = 40
var input_locked: bool = false
var frozen_columns: Array[FrozenColumn] = []
var locked_cells: Array[Vector2i] = []
var gravity_flipped: bool = false
var landing_rows: Array[int] = []
var act: int = 1
var match_number: int = 1
var enemy_name: String = ""
var enemy_gimmick: String = ""
var chip_count: int = 0


static func make_empty() -> RenderState:
	var rs := RenderState.new()
	rs.cells.resize(COLS * ROWS)
	for c in COLS:
		for r in ROWS:
			var cs := CellState.new()
			cs.col = c
			cs.row = r
			rs.cells[c * ROWS + r] = cs
	for _i in 2:
		rs.player_queue.append(QueueEntry.new())
	rs.landing_rows.resize(COLS)
	for c in COLS:
		rs.landing_rows[c] = 0
	return rs


func get_cell(col: int, row: int) -> CellState:
	return cells[col * ROWS + row]
