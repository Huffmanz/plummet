extends Control

signal column_selected(col: int)
signal match_complete(player_won: bool, player_score: int, ai_score: int, chips: int, win_streak: int, max_cascade: int, cross_color_count: int)

@onready var _board_canvas: BoardCanvas = $BoardCanvas
@onready var _ghost_canvas: GhostCanvas = $GhostCanvas
@onready var _queue_canvas: QueueCanvas = %QueueCanvas
@onready var _player_score_label: Label = %PlayerScore
@onready var _player_turns_label: Label = %PlayerTurns
@onready var _ai_score_label: Label = %AIScore
@onready var _ai_turns_label: Label = %AITurns
@onready var _chip_label: Label = %ChipCount
@onready var _enemy_name_label: Label = %EnemyName
@onready var _enemy_gimmick_label: Label = %EnemyGimmick
@onready var _turn_indicator_label: Label = %TurnIndicator
@onready var _match_info_label: Label = %MatchInfo
@onready var _rotate_prompt: Label = $RotatePrompt
@onready var _left_panel: Control = %LeftPanel
@onready var _right_panel: Control = %RightPanel
@onready var _bottom_strip: Control = %BottomStrip
@onready var _anim_layer: AnimLayer = $AnimLayer
@onready var _match_end_overlay: MatchEndOverlay = $MatchEndOverlay

# Visual
var _theme: ThemeBase
var _renderer: BoardRenderer
var _layout_mgr: LayoutManager
var _layout: LayoutManager.LayoutResult
var _state: RenderState

# Game logic
var _board: BoardEngine
var _score_calc: ScoreCalculator
var _score_tracker: ScoreTracker
var _turn_manager: TurnManager
var _cascade_loop: CascadeLoop
var _ai: AIOpponent
var _builder: RenderStateBuilder
var _player_bag: PieceBag
var _modifier_resolver: ModifierResolver
var _match_active: bool = false
var _animating: bool = false
var _prev_shake: Vector2 = Vector2.ZERO
var _chip_count: int = 0
var _win_streak: int = 0
var _shop_screen: ShopScreen

# Score tween
var _disp_player_score: float = 0.0
var _disp_ai_score: float = 0.0

# Idle breathe
var _idle_t: float = 0.0

# Score milestone tracking
var _score_milestone: int = 0

# Match metadata (injected by RunController in run mode)
var standalone: bool = true
var _match_act: int = 1
var _match_num: int = 1
var _match_enemy_name: String = "The Stoic"
var _match_enemy_gimmick: String = "No gimmick"
var _match_is_boss: bool = false
var _match_max_cascade: int = 0
var _match_cross_color_count: int = 0


func _ready() -> void:
	_theme = ThemeCozy.new()
	_renderer = BoardRenderer.new(_theme)
	_layout_mgr = LayoutManager.new()

	_board_canvas.renderer = _renderer
	_board_canvas.anim_layer = _anim_layer
	_ghost_canvas.renderer = _renderer
	_queue_canvas.renderer = _renderer
	_anim_layer.renderer = _renderer

	_shop_screen = preload("res://scenes/game/shop_screen.tscn").instantiate()
	add_child(_shop_screen)
	_shop_screen.shop_closed.connect(_on_shop_closed)

	get_viewport().size_changed.connect(_on_viewport_resized)
	_on_viewport_resized()

	if standalone:
		_init_game()
	column_selected.connect(_on_column_selected)


func _process(delta: float) -> void:
	if _anim_layer == null:
		return
	var off := _anim_layer.shake_offset
	if off != _prev_shake:
		_prev_shake = off
		_board_canvas.shake_offset = off
		_ghost_canvas.shake_offset = off
		_board_canvas.queue_redraw()
		_ghost_canvas.queue_redraw()

	# Score tween — tick displayed score toward actual over ~20 frames
	if _state != null:
		var max_step := maxf(1.0, absf(float(_state.player_score) - _disp_player_score) / 20.0 + delta * 30.0)
		_disp_player_score = move_toward(_disp_player_score, float(_state.player_score), max_step)
		var max_step_ai := maxf(1.0, absf(float(_state.ai_score) - _disp_ai_score) / 20.0 + delta * 30.0)
		_disp_ai_score = move_toward(_disp_ai_score, float(_state.ai_score), max_step_ai)

	# Board idle breathe
	if not _animating and _renderer != null:
		_idle_t += delta
		_renderer.idle_breathe_scale = 1.0 + sin(_idle_t * 1.8) * 0.001
	elif _renderer != null:
		_renderer.idle_breathe_scale = 1.0

	# Cascade heat cools after cascade ends
	if _renderer != null and _renderer.cascade_heat > 0.0:
		_renderer.cascade_heat = move_toward(_renderer.cascade_heat, 0.0, delta * 1.5)
		_board_canvas.queue_redraw()

	# Turn counter urgency — pulse red in last 10 turns
	if _state != null and _match_active:
		var p_turns := _state.player_turns_remaining
		if p_turns <= 10 and p_turns > 0:
			var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.009)
			_player_turns_label.modulate = Color(1.0, pulse * 0.4 + 0.6, pulse * 0.4 + 0.6)
		else:
			_player_turns_label.modulate = Color.WHITE

	# Keep score labels updating during tween
	if _state != null and (_disp_player_score != float(_state.player_score) or _disp_ai_score != float(_state.ai_score)):
		_update_labels()


func setup_match(
	bag: PieceBag,
	chips: int,
	win_streak: int,
	act: int,
	match_num: int,
	enemy_name: String,
	enemy_gimmick: String,
	is_boss: bool = false
) -> void:
	_player_bag = bag
	_chip_count = chips
	_win_streak = win_streak
	_match_act = act
	_match_num = match_num
	_match_enemy_name = enemy_name
	_match_enemy_gimmick = enemy_gimmick
	_match_is_boss = is_boss
	_init_game()


func _init_game() -> void:
	_board = BoardEngine.new()
	_score_calc = ScoreCalculator.new()
	_score_tracker = ScoreTracker.new()
	_turn_manager = TurnManager.new()
	_cascade_loop = CascadeLoop.new()
	_ai = AIOpponent.new(0.1)
	_builder = RenderStateBuilder.new()
	if _player_bag == null:
		_player_bag = PieceBag.new(Piece.Owner.PLAYER)
	_modifier_resolver = ModifierResolver.new()
	_match_active = true
	_animating = false
	_disp_player_score = 0.0
	_disp_ai_score = 0.0
	_score_milestone = 0
	_match_max_cascade = 0
	_match_cross_color_count = 0
	if _renderer != null:
		_renderer.cascade_heat = 0.0

	_turn_manager.match_ended.connect(_on_match_ended)
	_turn_manager.start()

	_state = _build_state()
	_refresh_all()


# Called externally to hot-swap game state (e.g. from a parent game controller).
func update_state(rs: RenderState) -> void:
	_state = rs
	_refresh_all()


func _build_state() -> RenderState:
	return _builder.build(
		_board, _score_tracker, _turn_manager,
		_player_bag.get_queue_pieces(2), [], [], false,
		_match_act, _match_num, _match_enemy_name, _match_enemy_gimmick,
		_chip_count, _animating
	)


func _on_column_selected(col: int) -> void:
	if not _match_active or _animating:
		return

	_animating = true
	_renderer.hovered_col = -1
	_ghost_canvas.queue_redraw()

	# Player turn — drop and animate
	var p_piece: Piece = _player_bag.current()
	_player_bag.advance()
	var gf := _state.gravity_flipped if _state != null else false
	var landing_row: int
	if p_piece.type == Piece.Type.GHOST:
		landing_row = _board.drop_ghost_piece(col, p_piece)
	else:
		landing_row = _board.drop_piece(col, p_piece)
	if landing_row < 0:
		_animating = false
		_state = _build_state()
		_refresh_all()
		return
	_modifier_resolver.set_landed(col, landing_row, p_piece)
	await _anim_layer.play_drop(col, landing_row, CellState.Occupant.PLAYER, gf)
	_check_col_fill_flash(col)
	if _is_block_move(col, landing_row, Piece.Owner.PLAYER):
		_spawn_blocked_popup(col, landing_row, gf)
	_modifier_resolver.on_land(_board)
	_state = _build_state()
	_refresh_all()

	var p_result := await _run_cascade_animated(_board, Piece.Owner.PLAYER)
	_match_max_cascade = maxi(_match_max_cascade, p_result.max_depth)
	if p_result.cross_color:
		_match_cross_color_count += 1
	var chips_before := _chip_count
	_award_chips(p_result, Piece.Owner.PLAYER)
	_score_tracker.add_turn(_score_calc.calculate(p_result, 0))
	_check_score_milestone()
	_turn_manager.advance(_board)
	if _chip_count > chips_before:
		_spawn_chip_popups(_chip_count - chips_before)

	_state = _build_state()
	_refresh_all()

	if not _match_active:
		_animating = false
		return

	# AI turn
	if _turn_manager.current_turn == Piece.Owner.AI:
		await _run_ai_turn_animated()

	_animating = false
	_renderer.hovered_col = _renderer.col_from_position(get_local_mouse_position().x)
	_state = _build_state()
	_refresh_all()
	_pop_turn_indicator()


func _run_ai_turn_animated() -> void:
	await _run_ai_thinking_dots()

	var ai_col := _ai.choose_column(_board)
	if ai_col < 0:
		_turn_manager.on_ai_skipped()
		_state = _build_state()
		_refresh_all()
		return

	# AI drop preview: highlight column briefly before dropping
	_anim_layer.play_ai_preview(ai_col, 0.3)
	await get_tree().create_timer(0.3).timeout
	_anim_layer.stop_ai_preview()

	var gf := _state.gravity_flipped if _state != null else false
	var ai_landing_row := _board.get_landing_row(ai_col)
	_board.drop_piece(ai_col, _ai.current_piece)
	await _anim_layer.play_drop(ai_col, ai_landing_row, CellState.Occupant.AI, gf)
	_check_col_fill_flash(ai_col)
	if _is_block_move(ai_col, ai_landing_row, Piece.Owner.AI):
		_spawn_blocked_popup(ai_col, ai_landing_row, gf)
	_state = _build_state()
	_refresh_all()

	var ai_result := await _run_cascade_animated(_board, Piece.Owner.AI)
	_match_max_cascade = maxi(_match_max_cascade, ai_result.max_depth)
	_score_tracker.add_turn(_score_calc.calculate(ai_result, 0))
	_ai.advance_queue()
	_turn_manager.advance(_board)

	_state = _build_state()
	_refresh_all()


func _run_ai_thinking_dots() -> void:
	var dots := ["AI .", "AI ..", "AI ..."]
	for i in dots.size():
		_turn_indicator_label.text = dots[i]
		await get_tree().create_timer(0.12).timeout


func _run_cascade_animated(board: BoardEngine, attribution: Piece.Owner) -> CascadeResult:
	var result := CascadeResult.new(attribution)
	var depth := 0
	var player_clear_count := 0
	var ai_clear_count := 0
	var ai_cleared := false

	while true:
		var runs: Array[MatchedRun] = board.detect_clears()
		if runs.is_empty():
			break

		# Determine which owners cleared this round before doing anything else.
		var has_player := false
		var has_ai := false
		for run in runs:
			if run.owner == Piece.Owner.PLAYER:
				has_player = true
			else:
				has_ai = true

		# Tag each clear with its owner's personal cascade depth, not the global round.
		for run in runs:
			var owner_depth := player_clear_count if run.owner == Piece.Owner.PLAYER else ai_clear_count
			result.clears.append(TaggedClear.new(run, owner_depth))

		var was_cross_color := result.cross_color
		if attribution == Piece.Owner.PLAYER:
			if has_player and ai_cleared:
				result.cross_color = true
			if has_ai:
				ai_cleared = true

		# Cascade heat + badge — escalate with depth
		_renderer.cascade_heat = clampf(float(depth) / 3.0, 0.0, 1.0)
		if depth >= 1:
			_anim_layer.play_cascade_badge(depth + 1)

		# Combo text + shake trigger once per depth level, before individual clears
		if depth >= 1:
			_anim_layer.play_combo_text(depth + 1)
		if depth == 1:
			_anim_layer.play_shake(2.0, 4)
		elif depth >= 2:
			_anim_layer.play_shake(4.0, 6)

		var gf := _state.gravity_flipped if _state != null else false

		_modifier_resolver.on_clear(board, runs)

		# Animate each run individually — pop score then sweep clear before moving to next
		for run in runs:
			var run_owner := Piece.Owner.PLAYER if run.owner == Piece.Owner.PLAYER else Piece.Owner.AI
			var occ := CellState.Occupant.PLAYER if run.owner == Piece.Owner.PLAYER else CellState.Occupant.AI
			var owner_depth := player_clear_count if run.owner == Piece.Owner.PLAYER else ai_clear_count
			_anim_layer.spawn_score_particles(_cells_center(run.cells), occ, _score_label_pos(run_owner))
			_spawn_single_run_popup(run, owner_depth, attribution)
			await _anim_layer.play_clear(run.cells, gf)

		# Cross-color chain popup after all runs have resolved
		if result.cross_color and not was_cross_color:
			var chain_cells: Array[Vector2i] = []
			for run in runs:
				chain_cells.append_array(run.cells)
			_anim_layer.spawn_popup(_popup_pos(chain_cells) - Vector2(0.0, 28.0), "+150 CHAIN")

		# Remove all cleared pieces, then let pieces fall
		board.remove_clears(runs)
		_state = _build_state()
		_refresh_all()

		var pause_clear := 0.0 if _anim_layer.reduced_motion else _pause_after_clear(depth)
		if pause_clear > 0.0:
			await get_tree().create_timer(pause_clear).timeout

		var pre_grav_state := _state
		_modifier_resolver.on_pre_gravity(board)
		board.apply_gravity()
		_modifier_resolver.on_gravity(board)
		_state = _build_state()

		var grav_moves: Array = _compute_gravity_moves(pre_grav_state, _state)
		if not grav_moves.is_empty() and not _anim_layer.reduced_motion:
			# Hide moving pieces from pre-gravity board so AnimLayer owns them during flight
			_set_gravity_hidden(grav_moves)
			_board_canvas.refresh(pre_grav_state)
			_ghost_canvas.refresh(pre_grav_state)
			await _anim_layer.play_gravity(grav_moves, pre_grav_state.gravity_flipped)
			_renderer.gravity_hidden_cells.clear()

		_refresh_all()

		var pause_gravity := 0.0 if _anim_layer.reduced_motion else _pause_after_gravity(depth)
		if pause_gravity > 0.0:
			await get_tree().create_timer(pause_gravity).timeout

		if has_player:
			player_clear_count += 1
		if has_ai:
			ai_clear_count += 1
		depth += 1

	_anim_layer.stop_cascade_badge()
	result.max_depth = maxi(0, depth - 1)
	return result


func _pause_after_clear(depth: int) -> float:
	return (8.0 / 60.0) * pow(0.9, depth)


func _pause_after_gravity(depth: int) -> float:
	return (4.0 / 60.0) * pow(0.9, depth)


func _spawn_single_run_popup(run: MatchedRun, depth: int, attribution: Piece.Owner) -> void:
	if attribution != Piece.Owner.PLAYER or run.owner != Piece.Owner.PLAYER:
		return
	if _renderer == null or _renderer.layout == null:
		return
	var multiplier := 1 << depth
	var n := run.cells.size()
	var base_val: int = 500 if n >= 6 else (250 if n == 5 else 100)
	var popup_color: Color
	if depth == 0:
		popup_color = Color(1.0, 0.95, 0.3)
	elif depth == 1:
		popup_color = Color(1.0, 0.6, 0.1)
	else:
		popup_color = Color(1.0, 0.2, 0.2)
	var label := "%d" % (base_val * multiplier) if multiplier == 1 else "%d ×%d" % [base_val, multiplier]
	_anim_layer.spawn_popup(_popup_pos(run.cells), label, popup_color)


func _cells_center(cells: Array[Vector2i]) -> Vector2:
	if cells.is_empty() or _renderer == null or _renderer.layout == null:
		return Vector2.ZERO
	var sum := Vector2.ZERO
	var gf := _state.gravity_flipped if _state != null else false
	for cell in cells:
		sum += _renderer.cell_rect(cell.x, cell.y, gf).get_center()
	return sum / cells.size()


func _score_label_pos(owner: Piece.Owner) -> Vector2:
	var label: Label = _player_score_label if owner == Piece.Owner.PLAYER else _ai_score_label
	return label.global_position - global_position + label.size * 0.5


func _popup_pos(cells: Array[Vector2i]) -> Vector2:
	if cells.is_empty() or _renderer == null or _renderer.layout == null:
		return Vector2.ZERO
	var sum := Vector2.ZERO
	var gf := _state.gravity_flipped if _state != null else false
	for cell in cells:
		sum += _renderer.cell_rect(cell.x, cell.y, gf).get_center()
	return sum / cells.size() - Vector2(0.0, _renderer.layout.cell_size * 0.8)


func _on_match_ended(_reason: TurnManager.MatchEndReason) -> void:
	_match_active = false
	_anim_layer.play_shake(2.0, 4)
	await get_tree().create_timer(0.6).timeout
	await _match_end_overlay.show_result(_score_tracker.player_score, _score_tracker.ai_score)
	_match_end_overlay.hide()

	var player_won: bool = _score_tracker.player_score > _score_tracker.ai_score
	if player_won:
		_win_streak += 1
		_chip_count += 15
		if _win_streak >= 2:
			_chip_count += (_win_streak - 1) * 5
		if not _match_is_boss and not standalone:
			_shop_screen.open(_player_bag, _chip_count)
		elif standalone:
			_shop_screen.open(_player_bag, _chip_count)
		else:
			match_complete.emit(true, _score_tracker.player_score, _score_tracker.ai_score, _chip_count, _win_streak, _match_max_cascade, _match_cross_color_count)
	else:
		_win_streak = 0
		if standalone:
			_init_game()
		else:
			match_complete.emit(false, _score_tracker.player_score, _score_tracker.ai_score, _chip_count, _win_streak, _match_max_cascade, _match_cross_color_count)


func _on_shop_closed(chips_remaining: int) -> void:
	_chip_count = chips_remaining
	if standalone:
		_init_game()
	else:
		match_complete.emit(true, _score_tracker.player_score, _score_tracker.ai_score, _chip_count, _win_streak, _match_max_cascade, _match_cross_color_count)


func _refresh_all() -> void:
	_board_canvas.refresh(_state)
	_ghost_canvas.refresh(_state)
	_queue_canvas.refresh(_state)
	_update_labels()


func _update_labels() -> void:
	_player_score_label.text = "Score: %d" % int(_disp_player_score)
	_player_turns_label.text = "Turns: %d" % _state.player_turns_remaining
	_ai_score_label.text = "Score: %d" % int(_disp_ai_score)
	_ai_turns_label.text = "Turns: %d" % _state.ai_turns_remaining
	_chip_label.text = "Chips: %d" % _state.chip_count
	_enemy_name_label.text = _state.enemy_name
	_enemy_gimmick_label.text = _state.enemy_gimmick
	_match_info_label.text = "Act %d · Match %d" % [_state.act, _state.match_number]
	if _state.active_player == CellState.Occupant.PLAYER and not _animating:
		_turn_indicator_label.text = "YOUR TURN"
	elif _state.active_player != CellState.Occupant.PLAYER and not _animating:
		_turn_indicator_label.text = "AI TURN"


func _compute_gravity_moves(pre: RenderState, post: RenderState) -> Array:
	var moves := []
	for col in RenderState.COLS:
		var pre_pieces: Array = []
		var post_pieces: Array = []
		for row in RenderState.ROWS:
			var pre_cs := pre.get_cell(col, row)
			var post_cs := post.get_cell(col, row)
			if pre_cs.occupant != CellState.Occupant.EMPTY and not pre_cs.locked:
				pre_pieces.append({col = col, row = row, occupant = pre_cs.occupant, piece_type = pre_cs.piece_type})
			if post_cs.occupant != CellState.Occupant.EMPTY and not post_cs.locked:
				post_pieces.append({col = col, row = row, occupant = post_cs.occupant, piece_type = post_cs.piece_type})
		var n := mini(pre_pieces.size(), post_pieces.size())
		for i in n:
			var pp: Dictionary = pre_pieces[i]
			var np: Dictionary = post_pieces[i]
			if pp.row != np.row:
				moves.append({col = col, from_row = pp.row, to_row = np.row, occupant = pp.occupant, piece_type = pp.piece_type})
	return moves


func _set_gravity_hidden(moves: Array) -> void:
	_renderer.gravity_hidden_cells.clear()
	for m: Dictionary in moves:
		_renderer.gravity_hidden_cells.append(Vector2i(m.col, m.from_row))


func _check_col_fill_flash(col: int) -> void:
	if _board.get_landing_row(col) < 0:
		_anim_layer.play_col_flash(col)


func _award_chips(result: CascadeResult, owner: Piece.Owner) -> void:
	if owner != Piece.Owner.PLAYER:
		return
	for tc: TaggedClear in result.clears:
		if tc.run.owner == Piece.Owner.PLAYER:
			_chip_count += 1


func _spawn_chip_popups(count: int) -> void:
	if _renderer == null or _renderer.layout == null:
		return
	var chip_pos := _chip_label.global_position - global_position + Vector2(30.0, 10.0)
	for i in count:
		_anim_layer.spawn_chip_popup(chip_pos + Vector2(0.0, float(i) * -18.0))


func _pop_turn_indicator() -> void:
	if _turn_indicator_label == null:
		return
	_turn_indicator_label.pivot_offset = _turn_indicator_label.size * 0.5
	var tw := create_tween()
	tw.tween_property(_turn_indicator_label, "scale", Vector2(1.25, 1.25), 0.07)
	tw.tween_property(_turn_indicator_label, "scale", Vector2(1.0, 1.0), 0.14).set_trans(Tween.TRANS_BACK)


func _check_score_milestone() -> void:
	for m: int in [500, 1000, 2000, 4000]:
		if _score_tracker.player_score >= m and _score_milestone < m:
			_score_milestone = m
			_anim_layer.play_milestone(m)


func _on_viewport_resized() -> void:
	_layout = _layout_mgr.compute(get_viewport().get_visible_rect().size)
	_renderer.layout = _layout
	_rotate_prompt.visible = _layout.mode == LayoutManager.LayoutMode.TOO_SMALL

	var vp := _layout.viewport_size
	var pw: float = _layout.panel_width
	var bh: float = _layout.bottom_height
	var board_area_h: float = vp.y - bh

	_left_panel.visible = true
	_right_panel.visible = true
	_left_panel.position = Vector2(0.0, 0.0)
	_left_panel.size = Vector2(pw, board_area_h)
	_right_panel.position = Vector2(vp.x - pw, 0.0)
	_right_panel.size = Vector2(pw, board_area_h)

	_bottom_strip.position = Vector2(0.0, vp.y - bh)
	_bottom_strip.size = Vector2(vp.x, bh)

	var cs: float = _layout.cell_size
	var gap: float = LayoutManager.CELL_GAP
	_queue_canvas.custom_minimum_size = Vector2(cs, cs * 2.0 + gap)

	if _state != null:
		_refresh_all()


func _is_block_move(col: int, row: int, my_owner: Piece.Owner) -> bool:
	var opponent := Piece.Owner.AI if my_owner == Piece.Owner.PLAYER else Piece.Owner.PLAYER
	var axes: Array[Vector2i] = [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, -1)]
	for axis: Vector2i in axes:
		var count: int = 0
		var c: int = col + axis.x
		var r: int = row + axis.y
		while c >= 0 and c < BoardEngine.COLS and r >= 0 and r < BoardEngine.ROWS:
			var cell := _board.get_cell(c, r)
			if cell != null and cell.owner == opponent:
				count += 1
				c += axis.x
				r += axis.y
			else:
				break
		c = col - axis.x
		r = row - axis.y
		while c >= 0 and c < BoardEngine.COLS and r >= 0 and r < BoardEngine.ROWS:
			var cell := _board.get_cell(c, r)
			if cell != null and cell.owner == opponent:
				count += 1
				c -= axis.x
				r -= axis.y
			else:
				break
		if count >= 3:
			return true
	return false


func _spawn_blocked_popup(col: int, row: int, gf: bool) -> void:
	if _renderer == null or _renderer.layout == null:
		return
	var cell_center := _renderer.cell_rect(col, row, gf).get_center()
	var pos := cell_center - Vector2(0.0, _renderer.layout.cell_size)
	_anim_layer.spawn_popup(pos, "BLOCKED!", Color(1.0, 0.55, 0.1))
	_anim_layer.play_block_sfx()


func _input(event: InputEvent) -> void:
	# Accessibility toggles work at any time
	if event is InputEventKey:
		var key := event as InputEventKey
		if key.pressed and key.keycode == KEY_R:
			_anim_layer.reduced_motion = not _anim_layer.reduced_motion
			_anim_layer.shake_enabled = not _anim_layer.reduced_motion
		elif key.pressed and key.keycode == KEY_M:
			_anim_layer.muted = not _anim_layer.muted

	if _state == null or _state.input_locked or _animating:
		return
	if _state.active_player != CellState.Occupant.PLAYER:
		return

	if event is InputEventMouseMotion:
		var local_pos := get_local_mouse_position()
		var new_col := _renderer.col_from_position(local_pos.x)
		if new_col != _renderer.hovered_col:
			_renderer.hovered_col = new_col
			_ghost_canvas.queue_redraw()

	elif event is InputEventMouseButton:
		var btn := event as InputEventMouseButton
		if btn.button_index == MOUSE_BUTTON_LEFT and btn.pressed:
			var local_pos := get_local_mouse_position()
			var col := _renderer.col_from_position(local_pos.x)
			if _renderer.is_col_valid(_state, col):
				var cur_piece := _player_bag.current()
				if cur_piece.type == Piece.Type.GHOST and _board.get_ghost_landing_row(col) < 0:
					_anim_layer.play_col_reject(col)
				else:
					column_selected.emit(col)
			elif col >= 0 and not _animating and not _state.input_locked and \
				_state.active_player == CellState.Occupant.PLAYER:
				_anim_layer.play_col_reject(col)
