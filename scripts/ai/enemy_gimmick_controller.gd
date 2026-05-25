class_name EnemyGimmickController extends RefCounted

const BLOCKER_FREEZE_INTERVAL := 5
const BLOCKER_FREEZE_PLAYER_TURNS := 2
const PAINTER_INTERVAL := 6
const SHIFTER_INTERVAL := 8
const INVERTER_FLIP_INTERVAL := 10
const INVERTER_FLIP_TURNS := 3
const INVERTER_ANIM_NONE := 0
const INVERTER_ANIM_FLIP_ON := 1
const INVERTER_ANIM_FLIP_OFF := -1

var enemy_name: String = "The Stoic"

var _board: BoardEngine
var _ai: AIOpponent
var _score_tracker: ScoreTracker

# Shared counters
var _total_drops: int = 0
var _drops_since_blocker_freeze: int = 0
var _drops_since_shifter: int = 0
var _drops_since_inverter_flip: int = 0
var _ai_turns_since_paint: int = 0

# Blocker
var _player_last_col: int = -1

# Mirror
var _copied_modifier: String = ""

# Inverter
var _inverted_turns_left: int = 0
var pending_inverter_anim: int = INVERTER_ANIM_NONE

# Paint flash cells (visual feedback)
var _paint_flash_cells: Array[Vector2i] = []


static func for_enemy(name: String) -> EnemyGimmickController:
	var ctrl := EnemyGimmickController.new()
	ctrl.enemy_name = name
	return ctrl


func get_noise() -> float:
	match enemy_name:
		"The Stoic":
			return 0.12
		"The Blocker", "The Gravedigger", "The Architect":
			return 0.08
		"The Mirror", "The Inverter", "The Hoarder", "The Taxman":
			return 0.03
		"The Painter", "The Shifter":
			return 0.05
	return 0.1


func setup(ai: AIOpponent, board: BoardEngine, score_tracker: ScoreTracker) -> void:
	_ai = ai
	_board = board
	_score_tracker = score_tracker
	match enemy_name:
		"The Blocker":
			_setup_blocker()
		"The Gravedigger":
			_setup_gravedigger()
		"The Architect":
			_setup_architect()
		"The Mirror":
			_setup_mirror()
		"The Painter":
			_setup_painter()
		"The Shifter":
			_setup_shifter()
		"The Inverter":
			_setup_inverter()
		"The Hoarder":
			_setup_hoarder()
		"The Taxman":
			pass  # placement chip tax handled in game_board


func is_gravity_flipped() -> bool:
	return _board != null and _board.gravity_up


func get_frozen_columns() -> Array:
	var result: Array = []
	if _board == null:
		return result
	for col: int in _board.frozen_columns:
		result.append(FrozenColumn.new(col, _board.frozen_columns[col]))
	return result


func get_locked_cells() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if _board == null:
		return result
	for c in BoardEngine.COLS:
		for r in BoardEngine.ROWS:
			var piece: Piece = _board.get_cell(c, r)
			if piece != null and piece.type == Piece.Type.LOCKED:
				result.append(Vector2i(c, r))
	return result


func take_paint_flash_cells() -> Array[Vector2i]:
	var cells := _paint_flash_cells
	_paint_flash_cells = []
	return cells


func on_drop() -> void:
	_total_drops += 1
	_drops_since_blocker_freeze += 1
	_drops_since_shifter += 1
	if enemy_name == "The Inverter":
		_drops_since_inverter_flip += 1


func filter_clears(runs: Array[MatchedRun]) -> Array[MatchedRun]:
	if enemy_name != "The Architect":
		return runs
	var filtered: Array[MatchedRun] = []
	for run in runs:
		if run.owner == Piece.Owner.AI and run.cells.size() < 5:
			continue
		filtered.append(run)
	return filtered


func on_turn_advanced() -> void:
	pass


func consume_pending_inverter_anim() -> int:
	var pending := pending_inverter_anim
	pending_inverter_anim = INVERTER_ANIM_NONE
	return pending


func adjust_ai_turn_score(turn: TurnScore, result: CascadeResult) -> TurnScore:
	if enemy_name == "The Architect":
		return _architect_turn_score(turn, result)
	if enemy_name == "The Hoarder":
		return _hoarder_turn_score(turn, result)
	return turn


# --- Blocker ---

func _setup_blocker() -> void:
	_ai.register_on_player_piece_landed(_on_blocker_player_landed)
	_ai.register_on_player_turn_start(_on_blocker_player_turn_start)


func _on_blocker_player_landed(_board_ref: BoardEngine, col: int, _row: int) -> void:
	_player_last_col = col
	if _drops_since_blocker_freeze >= BLOCKER_FREEZE_INTERVAL and _player_last_col >= 0:
		_board.freeze_column(_player_last_col, BLOCKER_FREEZE_PLAYER_TURNS)
		_drops_since_blocker_freeze = 0


func _on_blocker_player_turn_start(_board_ref: BoardEngine) -> void:
	_board.tick_frozen_columns()


# --- Gravedigger ---

func _setup_gravedigger() -> void:
	_ai.register_on_cascade_complete(_on_gravedigger_cascade)


func _on_gravedigger_cascade(board: BoardEngine, result: CascadeResult) -> void:
	var cols_seen: Dictionary = {}
	for tc: TaggedClear in result.clears:
		for cell: Vector2i in tc.run.cells:
			if cols_seen.has(cell.x):
				continue
			cols_seen[cell.x] = true
			board.place_locked_at_bottom(cell.x)


# --- Architect ---

func _setup_architect() -> void:
	_ai.custom_score_column = Callable(self, "_architect_score_column")


func _architect_score_column(board: BoardEngine, col: int) -> float:
	var landing_row: int = board.get_landing_row(col)
	if landing_row < 0:
		return -INF
	var score: float = 0.0
	var half: int = BoardEngine.ROWS / 2
	if landing_row > half:
		score -= float(landing_row - half) * 10.0
	var ai_piece: Piece = Piece.new(Piece.Owner.AI)
	board.set_cell(col, landing_row, ai_piece)
	for run in board.detect_clears():
		if run.owner == Piece.Owner.AI:
			if run.cells.size() >= 5:
				score += 3000.0
			# Ignore 4-in-a-row entirely
	board.set_cell(col, landing_row, null)
	return score


func _architect_turn_score(turn: TurnScore, result: CascadeResult) -> TurnScore:
	var adjusted := TurnScore.new()
	for tc: TaggedClear in result.clears:
		if tc.run.owner != Piece.Owner.AI:
			continue
		if tc.run.cells.size() < 5:
			continue
		var base: int = 500 if tc.run.cells.size() >= 6 else 250
		var mult: int = 1 << tc.depth
		adjusted.ai_points += base * mult * 2
	if result.cross_color and result.attribution == Piece.Owner.AI:
		adjusted.ai_points += 150
	return adjusted


# --- Mirror ---

func _setup_mirror() -> void:
	_ai.register_on_player_piece_landed(_on_mirror_player_landed)
	_ai.register_on_turn_start(_on_mirror_turn_start)


func _on_mirror_player_landed(board: BoardEngine, col: int, row: int) -> void:
	var piece: Piece = board.get_cell(col, row)
	if piece == null or piece.modifier.is_empty():
		_copied_modifier = ""
	else:
		_copied_modifier = piece.modifier


func _on_mirror_turn_start(_board_ref: BoardEngine) -> void:
	if _copied_modifier.is_empty():
		return
	_ai.current_piece.modifier = _copied_modifier


# --- Painter ---

func _setup_painter() -> void:
	_ai.register_on_turn_start(_on_painter_turn_start)


func _on_painter_turn_start(_board_ref: BoardEngine) -> void:
	_ai_turns_since_paint += 1
	if _ai_turns_since_paint < PAINTER_INTERVAL:
		return
	_ai_turns_since_paint = 0
	var area := _best_paint_area()
	if area.is_empty():
		return
	for cell: Vector2i in area:
		var piece: Piece = _board.get_cell(cell.x, cell.y)
		if piece == null or piece.type == Piece.Type.LOCKED:
			continue
		piece.owner = Piece.Owner.AI
		_paint_flash_cells.append(cell)


func _best_paint_area() -> Array[Vector2i]:
	var best_score := -1
	var best_area: Array[Vector2i] = []
	for c in range(BoardEngine.COLS - 1):
		for r in range(BoardEngine.ROWS - 1):
			var cells: Array[Vector2i] = [
				Vector2i(c, r), Vector2i(c + 1, r),
				Vector2i(c, r + 1), Vector2i(c + 1, r + 1),
			]
			var score := _paint_area_score(cells)
			if score > best_score:
				best_score = score
				best_area = cells
	return best_area


func _paint_area_score(cells: Array[Vector2i]) -> int:
	var score := 0
	for cell: Vector2i in cells:
		var piece: Piece = _board.get_cell(cell.x, cell.y)
		if piece == null or piece.type == Piece.Type.LOCKED:
			continue
		if piece.owner == Piece.Owner.PLAYER:
			score += 2
		elif piece.owner == Piece.Owner.AI:
			score += 1
	return score


# --- Shifter ---

func _setup_shifter() -> void:
	_ai.register_on_cascade_complete(_on_shifter_cascade)


func _on_shifter_cascade(_board_ref: BoardEngine, _result: CascadeResult) -> void:
	if _drops_since_shifter < SHIFTER_INTERVAL:
		return
	_drops_since_shifter = 0
	var direction := _best_slide_direction()
	_board.slide_contents(direction)


func _best_slide_direction() -> int:
	var left_disruption := _slide_disruption(-1)
	var right_disruption := _slide_disruption(1)
	return -1 if left_disruption >= right_disruption else 1


func _slide_disruption(direction: int) -> int:
	var disruption := 0
	for c in BoardEngine.COLS:
		for r in BoardEngine.ROWS:
			var piece: Piece = _board.get_cell(c, r)
			if piece == null or piece.type == Piece.Type.LOCKED or piece.owner != Piece.Owner.PLAYER:
				continue
			var dest_c: int = c + direction
			if dest_c < 0 or dest_c >= BoardEngine.COLS:
				disruption += 1
				continue
			if _would_break_player_line(c, r, dest_c, r):
				disruption += 3
	return disruption


func _would_break_player_line(from_c: int, from_r: int, to_c: int, to_r: int) -> bool:
	var dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, -1)]
	for dir: Vector2i in dirs:
		var count := 1
		var c: int = from_c + dir.x
		var r: int = from_r + dir.y
		while c >= 0 and c < BoardEngine.COLS and r >= 0 and r < BoardEngine.ROWS:
			var cell := _board.get_cell(c, r)
			if cell != null and cell.owner == Piece.Owner.PLAYER:
				count += 1
				c += dir.x
				r += dir.y
			else:
				break
		c = from_c - dir.x
		r = from_r - dir.y
		while c >= 0 and c < BoardEngine.COLS and r >= 0 and r < BoardEngine.ROWS:
			var cell := _board.get_cell(c, r)
			if cell != null and cell.owner == Piece.Owner.PLAYER:
				count += 1
				c -= dir.x
				r -= dir.y
			else:
				break
		if count >= 4:
			return true
	return false


# --- Inverter ---

func _setup_inverter() -> void:
	_ai.register_on_turn_start(_on_inverter_turn_start)
	_ai.register_on_player_turn_start(_on_inverter_player_turn_start)


func _on_inverter_turn_start(_board_ref: BoardEngine) -> void:
	_inverter_on_turn_start()


func _on_inverter_player_turn_start(_board_ref: BoardEngine) -> void:
	_inverter_on_turn_start()


func _inverter_on_turn_start() -> void:
	if _inverted_turns_left > 0:
		_tick_inverter_turn()
		return
	_try_inverter_flip()


func _try_inverter_flip() -> void:
	if _drops_since_inverter_flip < INVERTER_FLIP_INTERVAL:
		return
	_drops_since_inverter_flip = 0
	_inverted_turns_left = INVERTER_FLIP_TURNS
	pending_inverter_anim = INVERTER_ANIM_FLIP_ON


func _tick_inverter_turn() -> void:
	_inverted_turns_left -= 1
	if _inverted_turns_left <= 0:
		pending_inverter_anim = INVERTER_ANIM_FLIP_OFF


# --- Taxman ---

func is_taxman() -> bool:
	return enemy_name == "The Taxman"


func chip_tax_per_placement() -> int:
	return 1 if is_taxman() else 0


# --- Hoarder ---

func _setup_hoarder() -> void:
	pass


func _hoarder_turn_score(_turn: TurnScore, result: CascadeResult) -> TurnScore:
	var adjusted := TurnScore.new()
	for tc: TaggedClear in result.clears:
		if tc.run.owner != Piece.Owner.AI:
			continue
		if not tc.ai_pure:
			continue
		var base: int = 500 if tc.run.cells.size() >= 6 else (250 if tc.run.cells.size() == 5 else 100)
		var mult: int = 1 << tc.depth
		adjusted.ai_points += base * mult * 2
	if result.cross_color and result.attribution == Piece.Owner.AI:
		adjusted.ai_points += 150
	return adjusted
