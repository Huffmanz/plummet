class_name RenderStateBuilder extends RefCounted


func build(
	board: BoardEngine,
	score_tracker: ScoreTracker,
	turn_manager: TurnManager,
	player_queue_pieces: Array,
	frozen_columns_data: Array,
	locked_cells: Array[Vector2i],
	gravity_flipped: bool,
	act: int,
	match_num: int,
	enemy_name: String,
	enemy_gimmick: String,
	chip_count: int,
	input_locked: bool
) -> RenderState:
	var rs := RenderState.new()

	rs.cells.resize(RenderState.COLS * RenderState.ROWS)
	for c in RenderState.COLS:
		for r in RenderState.ROWS:
			var piece: Piece = board.get_cell(c, r)
			var cs := CellState.new()
			cs.col = c
			cs.row = r
			if piece != null:
				cs.occupant = CellState.Occupant.PLAYER if piece.owner == Piece.Owner.PLAYER \
					else CellState.Occupant.AI
				cs.piece_type = _map_piece_type(piece.type)
				cs.modifier = piece.modifier
			rs.cells[c * RenderState.ROWS + r] = cs

	for locked_cell in locked_cells:
		rs.get_cell(locked_cell.x, locked_cell.y).locked = true

	for fc in frozen_columns_data:
		var fc_col: int = fc.col
		var fc_turns: int = fc.turns_remaining
		for r in RenderState.ROWS:
			rs.get_cell(fc_col, r).frozen = true
		rs.frozen_columns.append(FrozenColumn.new(fc_col, fc_turns))

	for piece in player_queue_pieces:
		var qe := QueueEntry.new()
		if piece != null:
			qe.piece_type = _map_piece_type(piece.type)
			qe.modifier = piece.modifier
		rs.player_queue.append(qe)

	rs.player_score = score_tracker.player_score
	rs.ai_score = score_tracker.ai_score
	rs.score_delta = score_tracker.player_delta

	rs.active_player = CellState.Occupant.PLAYER \
		if turn_manager.current_turn == Piece.Owner.PLAYER \
		else CellState.Occupant.AI
	rs.player_turns_remaining = turn_manager.player_turns_remaining
	rs.ai_turns_remaining = turn_manager.ai_turns_remaining
	rs.input_locked = input_locked

	rs.landing_rows.resize(RenderState.COLS)
	for c in RenderState.COLS:
		rs.landing_rows[c] = board.get_landing_row(c)

	rs.gravity_flipped = gravity_flipped
	rs.locked_cells = locked_cells
	rs.act = act
	rs.match_number = match_num
	rs.enemy_name = enemy_name
	rs.enemy_gimmick = enemy_gimmick
	rs.chip_count = chip_count

	return rs


func _map_piece_type(type: Piece.Type) -> CellState.PieceType:
	match type:
		Piece.Type.NORMAL:
			return CellState.PieceType.NORMAL
		Piece.Type.PRISM:
			return CellState.PieceType.PRISM
		Piece.Type.COIN:
			return CellState.PieceType.COIN
		Piece.Type.EMBER:
			return CellState.PieceType.EMBER
		Piece.Type.SHARD:
			return CellState.PieceType.SHARD
	return CellState.PieceType.NORMAL
