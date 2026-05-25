class_name GameBoard
extends Control

signal column_selected(col: int)
signal match_complete(player_won: bool, player_score: int, ai_score: int, chips: int, win_streak: int, max_cascade: int, cross_color_count: int)
signal run_shop_finished(chips_remaining: int)
signal gimmick_test_match_finished(player_won: bool)

@onready var _board_canvas: BoardCanvas = $BoardCanvas
@onready var _ghost_canvas: GhostCanvas = $GhostCanvas
@onready var _pieces_panel: MatchPiecesPanel = %PiecesPanel
@onready var _player_score_label: Label = %PlayerScore
@onready var _score_delta_label: Label = %ScoreDelta
@onready var _player_turns_label: Label = %PlayerTurns
@onready var _sidebar_vbox: VBoxContainer = $LeftPanel/SidebarVBox
@onready var _ai_sidebar_vbox: VBoxContainer = $RightPanel/AISidebarVBox
@onready var _turn_pill: PanelContainer = $LeftPanel/SidebarVBox/ScorePanel/Margin/VBox/TurnPill
@onready var _ai_score_label: Label = %AIScore
@onready var _ai_turns_label: Label = %AITurns
@onready var _chip_label: Label = %ChipCount
@onready var _relic_display: MatchRelicDisplay = %RelicDisplay
@onready var _enemy_header: RichTextLabel = %EnemyHeader
@onready var _boss_tag: Label = %BossTag
@onready var _enemy_gimmick_label: Label = %EnemyGimmick
@onready var _turn_indicator_label: Label = %TurnIndicator
@onready var _match_info_label: Label = %MatchInfo
@onready var _rotate_prompt: Label = $RotatePrompt
@onready var _left_panel: Control = %LeftPanel
@onready var _right_panel: Control = %RightPanel
@onready var _match_progress_panel: PanelContainer = %MatchProgressPanel
@onready var _anim_layer: AnimLayer = $AnimLayer
@onready var _match_end_overlay: MatchEndOverlay = $MatchEndOverlay
@onready var _score_accum: ScoreAccumulatorOverlay = $ScoreAccumulatorOverlay

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
var _gimmick: EnemyGimmickController
var _builder: RenderStateBuilder
var _player_bag: PieceBag
var _modifier_resolver: ModifierResolver
var _relic_manager: RelicManager
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

const _SCORE_DELTA_RESERVE_TEXT := "+999 last turn"

# Match metadata (injected by RunController in run mode)
@export var standalone: bool = true
@export var sandbox_mode: bool = false
## When true, match end restarts in place (no shop / run signals). Used by boss gimmick test scene.
@export var gimmick_test_mode: bool = false
## When set, sandbox clicks call this first. Args: local_pos (Vector2), button (int).
## Return true to consume the click (skip normal drop).
var sandbox_placement_handler: Callable
var _match_act: int = 1
var _match_num: int = 1
var _match_enemy_name: String = "The Stoic"
var _match_enemy_gimmick: String = "No gimmick"
var _match_is_boss: bool = false
var _match_max_cascade: int = 0
var _match_cross_color_count: int = 0
var _was_gravity_flipped: bool = false


func _ready() -> void:
	_theme = ThemeCozy.new()
	_renderer = BoardRenderer.new(_theme)
	_layout_mgr = LayoutManager.new()

	_board_canvas.renderer = _renderer
	_board_canvas.anim_layer = _anim_layer
	_ghost_canvas.renderer = _renderer
	_pieces_panel.renderer = _renderer
	_anim_layer.renderer = _renderer

	_shop_screen = preload("res://scenes/game/shop_screen.tscn").instantiate()
	add_child(_shop_screen)
	_shop_screen.shop_closed.connect(_on_shop_closed)

	get_viewport().size_changed.connect(_on_viewport_resized)
	_apply_hud_sidebar_theme()
	_apply_viewport_layout_sync()
	call_deferred("_rewarm_piece_textures")

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
		var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.009)
		var urgent := Color(1.0, pulse * 0.4 + 0.6, pulse * 0.4 + 0.6)
		var p_turns := _state.player_turns_remaining
		if p_turns <= 10 and p_turns > 0:
			_player_turns_label.modulate = urgent
		else:
			_player_turns_label.modulate = Color.WHITE
		var ai_turns := _state.ai_turns_remaining
		if ai_turns <= 10 and ai_turns > 0:
			_ai_turns_label.modulate = urgent
		else:
			_ai_turns_label.modulate = Color.WHITE

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
	is_boss: bool = false,
	relic_mgr: RelicManager = null
) -> void:
	_player_bag = bag
	_chip_count = chips
	_sync_chip_display()
	_win_streak = win_streak
	_match_act = act
	_match_num = match_num
	_match_enemy_name = enemy_name
	_match_enemy_gimmick = enemy_gimmick
	_match_is_boss = is_boss
	_relic_manager = relic_mgr
	_init_game()


func _init_game() -> void:
	_set_match_play_ui_hidden(false)
	_board = BoardEngine.new()
	_score_calc = ScoreCalculator.new()
	_score_tracker = ScoreTracker.new()
	_turn_manager = TurnManager.new()
	_cascade_loop = CascadeLoop.new()
	_gimmick = EnemyGimmickController.for_enemy(_match_enemy_name)
	_ai = AIOpponent.new(_gimmick.get_noise())
	_gimmick.setup(_ai, _board, _score_tracker)
	_builder = RenderStateBuilder.new()
	if _player_bag == null:
		_player_bag = PieceBag.new(Piece.Owner.PLAYER)
	if _relic_manager == null:
		_relic_manager = RelicManager.new()
	_modifier_resolver = ModifierResolver.new()
	_match_active = true
	_animating = false
	_disp_player_score = 0.0
	_disp_ai_score = 0.0
	_score_milestone = 0
	_match_max_cascade = 0
	_match_cross_color_count = 0
	_was_gravity_flipped = false
	if _renderer != null:
		_renderer.cascade_heat = 0.0

	_turn_manager.match_ended.connect(_on_match_ended)
	if not _turn_manager.player_turn_started.is_connected(_on_player_turn_started):
		_turn_manager.player_turn_started.connect(_on_player_turn_started)
	_turn_manager.start()

	_state = _build_state()
	_refresh_all()
	if _layout != null:
		_apply_viewport_layout_sync()


# Called externally to hot-swap game state (e.g. from a parent game controller).
func update_state(rs: RenderState) -> void:
	_state = rs
	_refresh_all()


func get_cell_at_local_pos(local_pos: Vector2) -> Vector2i:
	if _renderer == null or _renderer.layout == null:
		return Vector2i(-1, -1)
	return _renderer.cell_from_position(local_pos, _gravity_flipped())


func sandbox_place_cell(col: int, row: int, owner: Piece.Owner, piece_type: Piece.Type, modifier: String = "") -> void:
	if _board == null:
		return
	var piece := Piece.new(owner)
	piece.type = piece_type
	piece.modifier = modifier
	_board.set_cell(col, row, piece)
	_state = _build_state()
	_refresh_all()


## Secret test cheat: Ctrl+Shift+W — +100 chips, winning score, 0 turns left, normal match end.
func _secret_autowin() -> void:
	if not _match_active or _animating:
		return
	if _shop_screen != null and _shop_screen.visible:
		return
	if _turn_manager == null or _score_tracker == null:
		return
	_chip_count += 100
	_sync_chip_display()
	var need := _score_tracker.ai_score + 1 - _score_tracker.player_score
	if need > 0:
		gimmick_test_add_score(Piece.Owner.PLAYER, need)
	_turn_manager.player_turns_remaining = 0
	_turn_manager.ai_turns_remaining = 0
	_state = _build_state()
	_refresh_all()
	_turn_manager.force_end()


func gimmick_test_add_score(owner: Piece.Owner, points: int) -> void:
	if _score_tracker == null:
		return
	var bonus := TurnScore.new()
	if owner == Piece.Owner.PLAYER:
		bonus.player_points = points
	else:
		bonus.ai_points = points
	_score_tracker.add_turn(bonus)
	_state = _build_state()
	_refresh_all()


func sandbox_clear_cell(col: int, row: int) -> void:
	if _board == null:
		return
	_board.set_cell(col, row, null)
	_state = _build_state()
	_refresh_all()


func _gravity_flipped() -> bool:
	return _board != null and _board.gravity_up


func _is_taxman_match() -> bool:
	return _match_enemy_name == "The Taxman"


func _make_render_state(gravity_flipped_display: bool) -> RenderState:
	var frozen: Array = _gimmick.get_frozen_columns() if _gimmick != null else []
	var locked: Array[Vector2i] = _gimmick.get_locked_cells() if _gimmick != null else []
	return _builder.build(
		_board, _score_tracker, _turn_manager,
		_player_bag.current(), _player_bag.get_queue_pieces(2), frozen, locked, gravity_flipped_display,
		_match_act, _match_num, _match_enemy_name, _match_enemy_gimmick,
		_chip_count, _animating
	)


func _build_state() -> RenderState:
	var gf: bool = _gravity_flipped()
	if gf != _was_gravity_flipped and _match_active and _anim_layer != null:
		_was_gravity_flipped = gf
		if not _anim_layer.reduced_motion:
			_anim_layer.play_shake(8.0 if gf else 4.0, 12 if gf else 6)
	else:
		_was_gravity_flipped = gf
	return _make_render_state(gf)


func _on_player_turn_started(_remaining: int) -> void:
	if _ai != null and _board != null:
		_ai.fire_on_player_turn_start(_board)
	await _run_pending_inverter_animation()
	_state = _build_state()
	_refresh_all()


func _on_column_selected(col: int) -> void:
	if not _match_active or _animating:
		return

	_animating = true
	_renderer.hovered_col = -1
	_ghost_canvas.queue_redraw()

	await _run_pending_inverter_animation()

	# Player turn — drop and animate
	var p_piece: Piece = _player_bag.current()
	_player_bag.advance()
	_state = _build_state()
	var gf := _gravity_flipped()
	var landing_row: int = _board.drop_piece(col, p_piece)
	if landing_row < 0:
		_animating = false
		_state = _build_state()
		_refresh_all()
		return
	_modifier_resolver.set_landed(col, landing_row, p_piece)
	_apply_placement_chip_tax()
	if _gimmick != null:
		_gimmick.on_drop()
	_ai.fire_on_player_piece_landed(_board, col, landing_row)
	await _anim_layer.play_drop(
		col, landing_row, CellState.Occupant.PLAYER, gf,
		PieceVisualUtil.cell_piece_type(p_piece.type), p_piece.modifier
	)
	_check_col_fill_flash(col)
	var blocked_opponent := _is_block_move(col, landing_row, Piece.Owner.PLAYER)
	if blocked_opponent:
		_spawn_blocked_popup(col, landing_row, gf)
	var landing_chips := _modifier_resolver.on_land(_board)
	if landing_chips > 0:
		_chip_count += landing_chips
		_sync_chip_display()
		_spawn_chip_popups(landing_chips)
	if p_piece.has_modifier():
		var _md := DataRegistry.get_modifier(p_piece.modifier)
		if _md != null:
			_anim_layer.play_modifier_flash(col, landing_row, gf, _md.badge_color)
	_state = _build_state()
	_refresh_all()

	var p_result := await _run_cascade_animated(_board, Piece.Owner.PLAYER)
	_ai.fire_on_cascade_complete(_board, p_result)
	_match_max_cascade = maxi(_match_max_cascade, p_result.max_depth)
	if p_result.cross_color:
		_match_cross_color_count += 1
	var chips_before := _chip_count
	_award_chips(p_result, Piece.Owner.PLAYER)
	var bounty_pts := _modifier_resolver.get_accumulated_bonus_points()
	_score_tracker.add_turn(_score_calc.calculate(p_result, bounty_pts))
	if _relic_manager != null:
		if p_result.clears.is_empty():
			var placement_bonus := _relic_manager.cartographer_placement_bonus()
			if placement_bonus > 0:
				_award_relic_points(col, landing_row, gf, placement_bonus, _CARTOGRAPHER_POPUP_COLOR)
		if blocked_opponent:
			var block_bonus := _relic_manager.compass_block_bonus()
			if block_bonus > 0:
				_award_relic_points(col, landing_row, gf, block_bonus, _COMPASS_POPUP_COLOR)
	_check_score_milestone()
	if sandbox_mode:
		# Replenish player turns so the match never ends
		_turn_manager.player_turns_remaining = TurnManager.TURNS_PER_PLAYER
	_turn_manager.advance(_board)
	if _gimmick != null:
		_gimmick.on_turn_advanced()
	if _chip_count > chips_before:
		_spawn_chip_popups(_chip_count - chips_before)

	_state = _build_state()
	_refresh_all()

	if not _match_active:
		_animating = false
		return

	# AI turn — skipped in sandbox mode
	if not sandbox_mode and _turn_manager.current_turn == Piece.Owner.AI:
		await _run_ai_turn_animated()
	elif sandbox_mode and _turn_manager.current_turn == Piece.Owner.AI:
		_turn_manager.current_turn = Piece.Owner.PLAYER

	_animating = false
	_renderer.hovered_col = _renderer.col_from_position(get_local_mouse_position().x)
	_state = _build_state()
	_refresh_all()
	_pop_turn_indicator()


func _run_ai_turn_animated() -> void:
	await _run_ai_thinking_dots()
	await _run_pending_inverter_animation()

	var ai_col := _ai.choose_column(_board)
	_state = _build_state()
	_refresh_all()
	if ai_col < 0:
		_turn_manager.on_ai_skipped()
		_state = _build_state()
		_refresh_all()
		return

	# AI drop preview: highlight column briefly before dropping
	_anim_layer.play_ai_preview(ai_col, 0.3)
	await get_tree().create_timer(0.3).timeout
	_anim_layer.stop_ai_preview()

	var gf := _gravity_flipped()
	var ai_landing_row := _board.get_landing_row(ai_col)
	_board.drop_piece(ai_col, _ai.current_piece)
	var ai_piece := _ai.current_piece
	if _gimmick != null:
		_gimmick.on_drop()
	_ai.fire_on_piece_landed(_board, ai_col, ai_landing_row)
	await _anim_layer.play_drop(
		ai_col, ai_landing_row, CellState.Occupant.AI, gf,
		PieceVisualUtil.cell_piece_type(ai_piece.type), ai_piece.modifier
	)
	_check_col_fill_flash(ai_col)
	var blocked_player := _is_block_move(ai_col, ai_landing_row, Piece.Owner.AI)
	if blocked_player:
		_spawn_blocked_popup(ai_col, ai_landing_row, gf)
		if _relic_manager != null:
			var lens_chips := _relic_manager.lens_blocked_chips()
			if lens_chips > 0:
				_chip_count += lens_chips
				_spawn_chip_popups(lens_chips)
	_state = _build_state()
	_refresh_all()

	var ai_result := await _run_cascade_animated(_board, Piece.Owner.AI)
	_ai.fire_on_cascade_complete(_board, ai_result)
	_match_max_cascade = maxi(_match_max_cascade, ai_result.max_depth)
	var ai_turn := _score_calc.calculate(ai_result, 0)
	if _gimmick != null:
		ai_turn = _gimmick.adjust_ai_turn_score(ai_turn, ai_result)
	_score_tracker.add_turn(ai_turn)
	_spawn_paint_flash_if_needed()
	_ai.advance_queue()
	_turn_manager.advance(_board)
	if _gimmick != null:
		_gimmick.on_turn_advanced()

	_state = _build_state()
	_refresh_all()


func _spawn_paint_flash_if_needed() -> void:
	if _gimmick == null or _renderer == null or _renderer.layout == null:
		return
	var cells := _gimmick.take_paint_flash_cells()
	if cells.is_empty():
		return
	var gf := _state.gravity_flipped if _state != null else false
	for cell: Vector2i in cells:
		var pos := _renderer.cell_rect(cell.x, cell.y, gf).get_center()
		_anim_layer.spawn_popup(pos, "PAINT", Color(0.6, 0.3, 0.9))


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
	var ember_bonus := 0
	var accum_shown := false

	while true:
		var runs: Array[MatchedRun] = board.detect_clears()
		if _gimmick != null:
			runs = _gimmick.filter_clears(runs)
		if runs.is_empty():
			break

		if not accum_shown:
			_score_accum.reset_and_show()
			accum_shown = true

		var has_player := false
		var has_ai := false
		for run in runs:
			if run.owner == Piece.Owner.PLAYER:
				has_player = true
			else:
				has_ai = true

		# Tag clears: cascade depth (exponential) + linear ember bonus (+ ignite on cells)
		for run in runs:
			var owner_depth := player_clear_count if run.owner == Piece.Owner.PLAYER else ai_clear_count
			var cascade_depth := _cascade_depth_for_run(board, run, owner_depth)
			var tc := TaggedClear.new(run, cascade_depth)
			tc.ember_bonus = ember_bonus + _count_ember_in_run(board, run)
			if run.owner == Piece.Owner.AI:
				for cell_pos: Vector2i in run.cells:
					var check_piece: Piece = board.get_cell(cell_pos.x, cell_pos.y)
					if check_piece != null and check_piece.owner == Piece.Owner.PLAYER:
						tc.ai_pure = false
						break
			for cell_pos: Vector2i in run.cells:
				var piece: Piece = board.get_cell(cell_pos.x, cell_pos.y)
				if piece == null:
					continue
				if piece.type == Piece.Type.PRISM:
					tc.has_prism = true
				if piece.type == Piece.Type.COIN and run.owner == Piece.Owner.PLAYER:
					tc.coin_chips += 3
			result.clears.append(tc)

		var was_cross_color := result.cross_color
		if attribution == Piece.Owner.PLAYER:
			if has_player and ai_cleared:
				result.cross_color = true
			if has_ai:
				ai_cleared = true

		_renderer.cascade_heat = clampf(float(depth) / 3.0, 0.0, 1.0)
		if depth >= 1:
			_anim_layer.play_cascade_badge(depth + 1)

		if depth >= 1:
			_anim_layer.play_combo_text(depth + 1)
		if depth == 1:
			_anim_layer.play_shake(2.0, 4)
		elif depth >= 2:
			_anim_layer.play_shake(4.0, 6)

		var gf := _state.gravity_flipped if _state != null else false

		# Snapshot modifier popup targets before on_clear (Detonate can wipe the row).
		var bounty_cells_by_run: Array = []
		var ignite_cells_by_run: Array = []
		var surge_chips_by_run: Array = []
		for run in runs:
			if run.owner == Piece.Owner.PLAYER:
				bounty_cells_by_run.append(_modifier_resolver.bounty_popup_cells_for_run(board, run))
				ignite_cells_by_run.append(_modifier_resolver.ignite_popup_cells_for_run(board, run))
				surge_chips_by_run.append(_modifier_resolver.surge_chips_for_run(board, run))
			else:
				bounty_cells_by_run.append([])
				ignite_cells_by_run.append([])
				surge_chips_by_run.append(0)

		# Snapshot dissolves before board mutation.
		var dissolve_entries: Array = _collect_detonate_dissolve_entries(board, runs)
		dissolve_entries.append_array(_collect_shard_dissolve_entries(board, runs))
		_apply_shard_effects(board, runs)

		# Clear modifiers that read the board (Bounty row, Echo, etc.) before Detonate wipes the row.
		var echo_copies := _relic_manager.echo_copy_count() if _relic_manager != null else 1
		_modifier_resolver.on_clear(board, runs, echo_copies)
		_modifier_resolver.apply_detonate_from_runs(board, runs)

		if not dissolve_entries.is_empty():
			_set_dissolve_hidden(dissolve_entries)
			_state = _build_state()
			_refresh_all()
			await _anim_layer.play_dissolve(dissolve_entries, gf)
			_renderer.dissolve_hidden_cells.clear()

		# Count Ember pieces in this round and add to bonus for subsequent rounds
		var embers_this_round := _count_ember_in_runs(board, runs)
		ember_bonus += embers_this_round

		# Animate each run, updating the accumulator as each one clears
		for run_idx in runs.size():
			var run: MatchedRun = runs[run_idx]
			var run_owner := Piece.Owner.PLAYER if run.owner == Piece.Owner.PLAYER else Piece.Owner.AI
			var occ := CellState.Occupant.PLAYER if run.owner == Piece.Owner.PLAYER else CellState.Occupant.AI
			var owner_depth := player_clear_count if run.owner == Piece.Owner.PLAYER else ai_clear_count
			var run_cascade := _cascade_depth_for_run(board, run, owner_depth)
			var run_ember := ember_bonus - embers_this_round + _count_ember_in_run(board, run)
			var run_mult := _score_calc.clear_multiplier(run_cascade, run_ember)
			var run_n := run.cells.size()
			var run_base: int = 500 if run_n >= 6 else (250 if run_n == 5 else 100)
			for cell_pos: Vector2i in run.cells:
				var cp: Piece = board.get_cell(cell_pos.x, cell_pos.y)
				if cp != null and cp.type == Piece.Type.PRISM:
					run_base *= 2
					break
			_score_accum.add_clear(run.owner, run_base, run_mult)
			_anim_layer.spawn_score_particles(_cells_center(run.cells), occ, _score_label_pos(run_owner))
			_spawn_single_run_popup(run, run_base, run_mult, attribution)
			if attribution == Piece.Owner.PLAYER and run.owner == Piece.Owner.PLAYER:
				await _spawn_bounty_popups(bounty_cells_by_run[run_idx], gf)
				await _spawn_ignite_popups(ignite_cells_by_run[run_idx], gf)
				_award_surge_chips(surge_chips_by_run[run_idx], run.cells, gf)
			await _anim_layer.play_clear(run.cells, gf)

		if result.cross_color and not was_cross_color:
			var chain_cells: Array[Vector2i] = []
			for run in runs:
				chain_cells.append_array(run.cells)
			_anim_layer.spawn_popup(_popup_pos(chain_cells) - Vector2(0.0, 28.0), "+150 CHAIN")

		board.remove_clears(runs)
		_state = _build_state()
		_refresh_all()

		var pause_clear := 0.0 if _anim_layer.reduced_motion else _pause_after_clear(depth)
		if pause_clear > 0.0:
			await get_tree().create_timer(pause_clear).timeout

		var pre_grav_state := _state
		_modifier_resolver.on_pre_gravity(board)
		board.apply_gravity()
		_state = _build_state()  # post-gravity, pre-echo

		var grav_moves: Array = _compute_gravity_moves(pre_grav_state, _state)
		if not grav_moves.is_empty() and not _anim_layer.reduced_motion:
			_set_gravity_hidden(grav_moves)
			_board_canvas.refresh(pre_grav_state)
			_ghost_canvas.refresh(pre_grav_state)
			await _anim_layer.play_gravity(grav_moves, pre_grav_state.gravity_flipped)
			_renderer.gravity_hidden_cells.clear()

		_refresh_all()

		var pause_gravity := 0.0 if _anim_layer.reduced_motion else _pause_after_gravity(depth)
		if pause_gravity > 0.0:
			await get_tree().create_timer(pause_gravity).timeout

		# Echo pieces drop one at a time; target column re-evaluated after each placement
		var echo_pieces := _modifier_resolver.pop_echo_pieces()
		if not echo_pieces.is_empty():
			var gf2 := _state.gravity_flipped if _state != null else false
			for echo_piece: Piece in echo_pieces:
				var echo_col := _modifier_resolver.find_echo_target(board)
				if echo_col < 0:
					continue
				var echo_row: int = board.drop_piece(echo_col, echo_piece)
				if echo_row < 0:
					continue
				await _anim_layer.play_drop(
					echo_col, echo_row, CellState.Occupant.PLAYER, gf2,
					PieceVisualUtil.cell_piece_type(echo_piece.type), echo_piece.modifier
				)
				_state = _build_state()
				_refresh_all()


		if has_player:
			player_clear_count += 1
		if has_ai:
			ai_clear_count += 1
		depth += 1

	_anim_layer.stop_cascade_badge()
	if accum_shown:
		await _score_accum.flash_and_dismiss()
	result.max_depth = maxi(0, depth - 1)
	return result


func _pause_after_clear(depth: int) -> float:
	return (8.0 / 60.0) * pow(0.9, depth)


func _pause_after_gravity(depth: int) -> float:
	return (4.0 / 60.0) * pow(0.9, depth)


func _spawn_single_run_popup(run: MatchedRun, base_val: int, multiplier: int, attribution: Piece.Owner) -> void:
	if attribution != Piece.Owner.PLAYER or run.owner != Piece.Owner.PLAYER:
		return
	if _renderer == null or _renderer.layout == null:
		return
	var popup_color: Color
	if multiplier <= 1:
		popup_color = Color(1.0, 0.95, 0.3)
	elif multiplier <= 2:
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


const _BOUNTY_POPUP_COLOR := Color("#52B85A")
const _IGNITE_POPUP_COLOR := Color("#D93824")
const _CARTOGRAPHER_POPUP_COLOR := Color("#C9A227")
const _COMPASS_POPUP_COLOR := Color("#4A9FD4")
const _MODIFIER_POPUP_STAGGER := 0.045


func _spawn_bounty_popups(ai_cells: Array[Vector2i], gravity_flipped: bool) -> void:
	if ai_cells.is_empty() or _renderer == null or _renderer.layout == null:
		return
	for i in ai_cells.size():
		var cell: Vector2i = ai_cells[i]
		var pos := _renderer.cell_rect(cell.x, cell.y, gravity_flipped).get_center()
		pos.y -= float(i) * 18.0
		_anim_layer.spawn_popup(pos, "+10", _BOUNTY_POPUP_COLOR)
		_score_accum.add_bonus(Piece.Owner.PLAYER, 10)
		if i < ai_cells.size() - 1 and not _anim_layer.reduced_motion:
			await get_tree().create_timer(_MODIFIER_POPUP_STAGGER).timeout


func _spawn_ignite_popups(extra_cells: Array[Vector2i], gravity_flipped: bool) -> void:
	if extra_cells.is_empty() or _renderer == null or _renderer.layout == null:
		return
	for i in extra_cells.size():
		var cell: Vector2i = extra_cells[i]
		var pos := _renderer.cell_rect(cell.x, cell.y, gravity_flipped).get_center()
		pos.y -= float(i) * 18.0
		_anim_layer.spawn_popup(pos, "+100", _IGNITE_POPUP_COLOR)
		_score_accum.add_bonus(Piece.Owner.PLAYER, 100)
		if i < extra_cells.size() - 1 and not _anim_layer.reduced_motion:
			await get_tree().create_timer(_MODIFIER_POPUP_STAGGER).timeout


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
	if gimmick_test_mode:
		gimmick_test_match_finished.emit(player_won)
		call_deferred("_init_game")
		return
	if player_won:
		_win_streak += 1
		_chip_count += 15
		if _win_streak >= 2:
			_chip_count += (_win_streak - 1) * 5
		var opens_shop := not _match_is_boss
		if opens_shop:
			if not standalone:
				_emit_match_complete(true)
			await _open_shop_after_win()
			if standalone:
				pass  # shop close restarts via _on_shop_closed
		else:
			_clear_match_visuals()
			_emit_match_complete(true)
	else:
		_win_streak = 0
		_clear_match_visuals()
		if standalone:
			_init_game()
		else:
			_emit_match_complete(false)


func _open_shop_after_win() -> void:
	_shop_screen.reduced_motion = _anim_layer.reduced_motion or OS.has_feature("web")
	_set_match_play_ui_hidden(true)
	_shop_screen.open(_player_bag, _chip_count, _relic_manager, _anim_layer.muted)


func _set_match_play_ui_hidden(hidden: bool) -> void:
	_board_canvas.visible = not hidden
	_ghost_canvas.visible = not hidden
	_anim_layer.visible = not hidden
	if hidden:
		_left_panel.visible = false
		_right_panel.visible = false
		_match_progress_panel.visible = false
		_match_end_overlay.hide()
	elif _layout != null:
		_apply_viewport_layout_sync()
	else:
		_left_panel.visible = true
		_right_panel.visible = true
		_match_progress_panel.visible = true


func _on_shop_closed(chips_remaining: int) -> void:
	_chip_count = chips_remaining
	_set_match_play_ui_hidden(false)
	if standalone:
		call_deferred("_init_game")
	else:
		call_deferred("_notify_run_shop_finished")


func _notify_run_shop_finished() -> void:
	if not is_inside_tree():
		return
	run_shop_finished.emit(_chip_count)


func _clear_match_visuals() -> void:
	var cleared := RenderState.make_empty()
	cleared.act = _match_act
	cleared.match_number = _match_num
	cleared.enemy_name = _match_enemy_name
	cleared.enemy_gimmick = _match_enemy_gimmick
	cleared.chip_count = _chip_count
	cleared.player_score = int(_disp_player_score)
	cleared.ai_score = int(_disp_ai_score)
	cleared.player_turns_remaining = _turn_manager.player_turns_remaining if _turn_manager != null else 0
	cleared.ai_turns_remaining = _turn_manager.ai_turns_remaining if _turn_manager != null else 0
	_state = cleared
	_board_canvas.refresh(_state)
	_ghost_canvas.refresh(_state)
	_pieces_panel.refresh(_state)
	_renderer.hovered_col = -1
	_board_canvas.queue_redraw()
	_ghost_canvas.queue_redraw()


func _emit_match_complete(player_won: bool) -> void:
	match_complete.emit(
		player_won,
		_score_tracker.player_score,
		_score_tracker.ai_score,
		_chip_count,
		_win_streak,
		_match_max_cascade,
		_match_cross_color_count,
	)


func _refresh_all() -> void:
	_board_canvas.refresh(_state)
	_ghost_canvas.refresh(_state)
	_pieces_panel.refresh(_state)
	_update_labels()


func _update_labels() -> void:
	_player_score_label.text = str(int(_disp_player_score))
	var delta := _state.score_delta if _state != null else 0
	_score_delta_label.visible = true
	if delta > 0:
		_score_delta_label.text = "+%d last turn" % delta
	else:
		_score_delta_label.text = ""
	_player_turns_label.text = str(_state.player_turns_remaining)
	_ai_score_label.text = str(int(_disp_ai_score))
	_ai_turns_label.text = str(_state.ai_turns_remaining)
	_chip_label.text = str(_chip_count)
	if _relic_display != null:
		_relic_display.refresh(_relic_manager)
	_enemy_header.text = "[wave]%s[/wave]" % _state.enemy_name
	_boss_tag.visible = _match_is_boss
	_enemy_gimmick_label.text = _state.enemy_gimmick
	_match_info_label.text = "Act %d · Match %d" % [_state.act, _state.match_number]
	if _state.active_player == CellState.Occupant.PLAYER and not _animating:
		_turn_indicator_label.text = "Your turn"
		_style_turn_pill(true)
	elif _state.active_player != CellState.Occupant.PLAYER and not _animating:
		_turn_indicator_label.text = "AI turn"
		_style_turn_pill(false)


func _apply_hud_sidebar_theme() -> void:
	var panel_style := _make_hud_panel_style()
	_apply_panel_style(_sidebar_vbox, ["ScorePanel", "ChipsPanel", "PiecesPanelWrap", "RelicsPanel"], panel_style)
	_apply_panel_style(_ai_sidebar_vbox, ["EnemyPanel", "ScorePanel"], panel_style)
	if _match_progress_panel != null:
		_match_progress_panel.add_theme_stylebox_override("panel", panel_style)
	_style_player_sidebar_labels()
	_style_ai_sidebar_labels()
	_style_turn_pill(_state != null and _state.active_player == CellState.Occupant.PLAYER)


func _make_hud_panel_style() -> StyleBoxFlat:
	var panel_style := UITheme.make_surface_style(10, UITheme.SURFACE)
	panel_style.content_margin_left = 0.0
	panel_style.content_margin_right = 0.0
	panel_style.content_margin_top = 0.0
	panel_style.content_margin_bottom = 0.0
	panel_style.shadow_size = 2
	return panel_style


func _apply_panel_style(vbox: VBoxContainer, panel_names: Array[String], panel_style: StyleBoxFlat) -> void:
	for panel_name in panel_names:
		var panel := vbox.get_node_or_null(panel_name) as PanelContainer
		if panel != null:
			panel.add_theme_stylebox_override("panel", panel_style)


func _reserve_score_delta_label_size() -> void:
	_score_delta_label.text = _SCORE_DELTA_RESERVE_TEXT
	_score_delta_label.custom_minimum_size = _score_delta_label.get_minimum_size()
	_score_delta_label.text = ""
	_score_delta_label.visible = true


func _style_player_sidebar_labels() -> void:
	for header_path in [
		"ChipsPanel/Margin/VBox/HBoxContainer/Header",
		"ChipsPanel/Margin/VBox/HBoxContainer/TurnHeader",
	]:
		var lbl := _sidebar_vbox.get_node_or_null(header_path) as Label
		if lbl != null:
			lbl.add_theme_color_override("font_color", UITheme.TEXT_ON_SURFACE)
	_player_score_label.add_theme_color_override("font_color", UITheme.TEXT_ON_SURFACE)
	_score_delta_label.add_theme_color_override("font_color", UITheme.TEXT_MUTED_ON_SURFACE)
	_reserve_score_delta_label_size()
	_player_turns_label.add_theme_color_override("font_color", UITheme.TEXT_ON_SURFACE)
	_player_turns_label.add_theme_font_size_override("font_size", 18)
	_chip_label.add_theme_color_override("font_color", UITheme.TEXT_ON_SURFACE)
	_match_info_label.add_theme_color_override("font_color", UITheme.TEXT_MUTED_ON_SURFACE)
	_match_info_label.add_theme_font_size_override("font_size", 8)


func _style_ai_sidebar_labels() -> void:
	_enemy_header.add_theme_color_override("default_color", UITheme.AI)
	_enemy_gimmick_label.add_theme_color_override("font_color", UITheme.TEXT_MUTED_ON_SURFACE)
	_boss_tag.add_theme_color_override("font_color", UITheme.ACCENT_POP)
	_boss_tag.add_theme_font_size_override("font_size", 7)
	for header_path in [
		"ScorePanel/Margin/VBox/HeaderRow/ScoreHeader",
		"ScorePanel/Margin/VBox/HeaderRow/TurnHeader",
	]:
		var lbl := _ai_sidebar_vbox.get_node_or_null(header_path) as Label
		if lbl != null:
			lbl.add_theme_color_override("font_color", UITheme.TEXT_ON_SURFACE)
	_ai_score_label.add_theme_color_override("font_color", UITheme.TEXT_ON_SURFACE)
	_ai_turns_label.add_theme_color_override("font_color", UITheme.TEXT_ON_SURFACE)
	_ai_turns_label.add_theme_font_size_override("font_size", 18)


func _style_turn_pill(player_turn: bool) -> void:
	if _turn_pill == null or _turn_indicator_label == null:
		return
	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 6.0
	sb.content_margin_right = 6.0
	sb.content_margin_top = 2.0
	sb.content_margin_bottom = 2.0
	if player_turn:
		sb.bg_color = UITheme.ACCENT
		sb.border_color = UITheme.ACCENT_HOVER
		_turn_indicator_label.add_theme_color_override("font_color", UITheme.TEXT_ON_SURFACE)
	else:
		sb.bg_color = UITheme.SURFACE_LIGHT
		sb.border_color = UITheme.CELL_BORDER
		_turn_indicator_label.add_theme_color_override("font_color", UITheme.TEXT_MUTED_ON_SURFACE)
	sb.set_border_width_all(2)
	_turn_pill.add_theme_stylebox_override("panel", sb)


func _run_pending_inverter_animation() -> void:
	if _gimmick == null or _board == null:
		return
	var pending: int = _gimmick.consume_pending_inverter_anim()
	match pending:
		EnemyGimmickController.INVERTER_ANIM_FLIP_ON:
			await _play_inverter_flip_on()
		EnemyGimmickController.INVERTER_ANIM_FLIP_OFF:
			await _play_inverter_flip_off()


func _play_inverter_flip_on() -> void:
	if _anim_layer != null and not _anim_layer.reduced_motion:
		_anim_layer.play_shake(8.0, 12)
	# Mirror first so the floor stack maps to ceiling rows; then one settle in flipped coords.
	_board.mirror_vertical()
	_board.gravity_up = true
	_was_gravity_flipped = true
	await _animate_board_apply_gravity(true)
	_state = _make_render_state(true)
	_refresh_all()


func _play_inverter_flip_off() -> void:
	if _anim_layer != null and not _anim_layer.reduced_motion:
		_anim_layer.play_shake(4.0, 6)
	_board.mirror_vertical()
	_board.gravity_up = false
	_was_gravity_flipped = false
	await _animate_board_apply_gravity(false)
	while true:
		var runs: Array[MatchedRun] = _board.detect_clears()
		if _gimmick != null:
			runs = _gimmick.filter_clears(runs)
		if runs.is_empty():
			break
		_board.remove_clears(runs)
		await _animate_board_apply_gravity(false)
	_state = _build_state()
	_refresh_all()


func _animate_board_apply_gravity(display_flipped: bool) -> void:
	if _board == null:
		return
	if _anim_layer == null or _anim_layer.reduced_motion:
		_board.apply_gravity()
		_state = _make_render_state(display_flipped)
		_refresh_all()
		return
	var pre := _make_render_state(display_flipped)
	_board.apply_gravity()
	var post := _make_render_state(display_flipped)
	var moves: Array = _compute_gravity_moves(pre, post)
	if moves.is_empty():
		_state = post
		_refresh_all()
		return
	_set_gravity_hidden(moves)
	_board_canvas.refresh(pre)
	_ghost_canvas.refresh(pre)
	await _anim_layer.play_gravity(moves, display_flipped)
	_renderer.gravity_hidden_cells.clear()
	_state = post
	_refresh_all()


func _compute_gravity_moves(pre: RenderState, post: RenderState) -> Array:
	var moves := []
	for col in RenderState.COLS:
		var pre_pieces: Array = []
		var post_pieces: Array = []
		for row in RenderState.ROWS:
			var pre_cs := pre.get_cell(col, row)
			var post_cs := post.get_cell(col, row)
			if pre_cs.occupant != CellState.Occupant.EMPTY and not pre_cs.locked:
				pre_pieces.append({
					col = col, row = row, occupant = pre_cs.occupant,
					piece_type = pre_cs.piece_type, modifier = pre_cs.modifier,
				})
			if post_cs.occupant != CellState.Occupant.EMPTY and not post_cs.locked:
				post_pieces.append({
					col = col, row = row, occupant = post_cs.occupant,
					piece_type = post_cs.piece_type, modifier = post_cs.modifier,
				})
		var n := mini(pre_pieces.size(), post_pieces.size())
		for i in n:
			var pp: Dictionary = pre_pieces[i]
			var np: Dictionary = post_pieces[i]
			if pp.row != np.row:
				moves.append({
					col = col, from_row = pp.row, to_row = np.row,
					occupant = pp.occupant, piece_type = pp.piece_type, modifier = pp.modifier,
				})
	return moves


func _set_gravity_hidden(moves: Array) -> void:
	_renderer.gravity_hidden_cells.clear()
	for m: Dictionary in moves:
		_renderer.gravity_hidden_cells.append(Vector2i(m.col, m.from_row))


func _dissolve_entry(col: int, row: int, piece: Piece) -> Dictionary:
	var occ := CellState.Occupant.PLAYER if piece.owner == Piece.Owner.PLAYER else CellState.Occupant.AI
	return {
		"col": col,
		"row": row,
		"occupant": occ,
		"piece_type": PieceVisualUtil.cell_piece_type(piece.type),
		"modifier": piece.modifier,
	}


func _cells_in_current_runs(runs: Array[MatchedRun]) -> Dictionary:
	var cells: Dictionary = {}
	for run in runs:
		for cell_pos: Vector2i in run.cells:
			cells[cell_pos] = true
	return cells


func _collect_detonate_dissolve_entries(board: BoardEngine, runs: Array[MatchedRun]) -> Array:
	var entries: Array = []
	for row: int in _modifier_resolver.detonate_rows_from_runs(board, runs):
		for c in BoardEngine.COLS:
			var p: Piece = board.get_cell(c, row)
			if p != null:
				entries.append(_dissolve_entry(c, row, p))
	return entries


func _collect_shard_dissolve_entries(board: BoardEngine, runs: Array[MatchedRun]) -> Array:
	var entries: Array = []
	for shard_pos: Vector2i in _shard_cells_in_runs(board, runs):
		for offset: int in [1, 2]:
			var above_row: int = shard_pos.y + offset
			if above_row >= BoardEngine.ROWS:
				continue
			var above: Piece = board.get_cell(shard_pos.x, above_row)
			if above != null:
				entries.append(_dissolve_entry(shard_pos.x, above_row, above))
	return entries


func _shard_cells_in_runs(board: BoardEngine, runs: Array[MatchedRun]) -> Array[Vector2i]:
	var shard_cells: Array[Vector2i] = []
	for run in runs:
		for cell_pos: Vector2i in run.cells:
			var piece: Piece = board.get_cell(cell_pos.x, cell_pos.y)
			if piece != null and piece.type == Piece.Type.SHARD:
				shard_cells.append(cell_pos)
	return shard_cells


func _set_dissolve_hidden(entries: Array) -> void:
	_renderer.dissolve_hidden_cells.clear()
	for entry: Dictionary in entries:
		_renderer.dissolve_hidden_cells.append(Vector2i(entry["col"], entry["row"]))


func _check_col_fill_flash(col: int) -> void:
	if _board.get_landing_row(col) < 0:
		_anim_layer.play_col_flash(col)


func _sync_chip_display() -> void:
	if _state != null:
		_state.chip_count = _chip_count
	if _chip_label != null:
		_chip_label.text = str(_chip_count)


func _apply_placement_chip_tax() -> void:
	var tax := _gimmick.chip_tax_per_placement() if _gimmick != null else 0
	_apply_chip_tax_amount(tax)


func _apply_chip_tax_amount(amount: int) -> void:
	if amount <= 0 or not _is_taxman_match():
		return
	_chip_count = maxi(0, _chip_count - amount)
	_sync_chip_display()
	if _anim_layer == null:
		return
	var chip_pos := Vector2(30.0, 10.0)
	if _chip_label != null:
		chip_pos = _chip_label.global_position - global_position + Vector2(30.0, 10.0)
	var label := "-%d chip" % amount if amount == 1 else "-%d chips" % amount
	_anim_layer.spawn_popup(chip_pos, label, Color(1.0, 0.3, 0.3))


func _award_chips(result: CascadeResult, owner: Piece.Owner) -> void:
	if owner != Piece.Owner.PLAYER:
		return
	var chips_per_clear := _relic_manager.chips_per_clear() if _relic_manager != null else 1
	for tc: TaggedClear in result.clears:
		if tc.run.owner == Piece.Owner.PLAYER:
			_chip_count += chips_per_clear
			_chip_count += tc.coin_chips
	_sync_chip_display()


# Removes the two pieces above each Shard piece that cleared (before Detonate row wipe).
func _apply_shard_effects(board: BoardEngine, runs: Array[MatchedRun]) -> void:
	for shard_pos: Vector2i in _shard_cells_in_runs(board, runs):
		for offset: int in [1, 2]:
			var above_row: int = shard_pos.y + offset
			if above_row < BoardEngine.ROWS:
				board.set_cell(shard_pos.x, above_row, null)


func _cascade_depth_for_run(_board: BoardEngine, _run: MatchedRun, owner_clear_index: int) -> int:
	return owner_clear_index


func _count_ember_in_run(board: BoardEngine, run: MatchedRun) -> int:
	var count := 0
	for cell_pos: Vector2i in run.cells:
		var piece: Piece = board.get_cell(cell_pos.x, cell_pos.y)
		if piece != null and piece.type == Piece.Type.EMBER:
			count += 1
	return count


# Counts Ember pieces in the given set of runs (from the board state before removal).
func _count_ember_in_runs(board: BoardEngine, runs: Array[MatchedRun]) -> int:
	var count := 0
	for run in runs:
		count += _count_ember_in_run(board, run)
	return count


func _spawn_chip_popups(count: int) -> void:
	if _renderer == null or _renderer.layout == null:
		return
	var chip_pos := _chip_label.global_position - global_position + Vector2(30.0, 10.0)
	for i in count:
		_anim_layer.spawn_chip_popup(chip_pos + Vector2(0.0, float(i) * -18.0))


func _award_surge_chips(chip_count: int, run_cells: Array[Vector2i], gravity_flipped: bool) -> void:
	if chip_count <= 0:
		return
	_chip_count += chip_count
	if _renderer == null or _renderer.layout == null:
		return
	var chip_pos := _popup_pos(run_cells)
	for i in chip_count:
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


func _rewarm_piece_shader_cache() -> void:
	if _layout == null or _theme == null:
		return
	var pixel_size := PieceShaderTextureCache.layout_pixel_size(_layout.cell_size)
	await PieceShaderTextureCache.warm_for_layout_async(pixel_size, _theme.color_player, _theme.color_ai)


func _on_viewport_resized() -> void:
	_apply_viewport_layout_sync()
	_rewarm_piece_textures()


func _apply_viewport_layout_sync() -> void:
	if not is_inside_tree():
		return
	_layout = _layout_mgr.compute(get_viewport().get_visible_rect().size)
	_renderer.layout = _layout
	_rotate_prompt.visible = _layout.mode == LayoutManager.LayoutMode.TOO_SMALL

	var vp := _layout.viewport_size
	var pw: float = _layout.panel_width
	const hud_margin := 5.0
	const match_progress_h := 26.0
	var show_side_panels := pw > 0.0
	_left_panel.visible = show_side_panels
	_right_panel.visible = show_side_panels
	_match_progress_panel.visible = show_side_panels
	if show_side_panels:
		_left_panel.position = Vector2(hud_margin, hud_margin)
		_left_panel.size = Vector2(pw, vp.y - hud_margin * 2.0 - match_progress_h)
		_match_progress_panel.size = Vector2(pw, match_progress_h)
		_right_panel.position = Vector2(vp.x - pw - hud_margin, hud_margin)
		_right_panel.size = Vector2(pw, vp.y - hud_margin * 2.0 - match_progress_h)

	if _state != null:
		_refresh_all()


func _rewarm_piece_textures() -> void:
	await _rewarm_piece_shader_cache()
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
			if cell != null and cell.type != Piece.Type.LOCKED and cell.owner == opponent:
				count += 1
				c += axis.x
				r += axis.y
			else:
				break
		c = col - axis.x
		r = row - axis.y
		while c >= 0 and c < BoardEngine.COLS and r >= 0 and r < BoardEngine.ROWS:
			var cell := _board.get_cell(c, r)
			if cell != null and cell.type != Piece.Type.LOCKED and cell.owner == opponent:
				count += 1
				c -= axis.x
				r -= axis.y
			else:
				break
		if count >= 3:
			return true
	return false


func _award_relic_points(col: int, row: int, gf: bool, points: int, popup_color: Color) -> void:
	var bonus_turn := TurnScore.new()
	bonus_turn.player_points = points
	_score_tracker.add_turn(bonus_turn)
	if _renderer != null and _renderer.layout != null:
		var pop_pos := _renderer.cell_rect(col, row, gf).get_center()
		_anim_layer.spawn_popup(pop_pos, "+%d" % points, popup_color)


func _spawn_blocked_popup(col: int, row: int, gf: bool) -> void:
	if _renderer == null or _renderer.layout == null:
		return
	var cell_center := _renderer.cell_rect(col, row, gf).get_center()
	var pos := cell_center - Vector2(0.0, _renderer.layout.cell_size)
	_anim_layer.spawn_popup(pos, "BLOCKED!", Color(1.0, 0.55, 0.1))
	_anim_layer.play_block_sfx()


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key := event as InputEventKey
		if key.pressed and key.ctrl_pressed and key.shift_pressed and key.keycode == KEY_W:
			_secret_autowin()
			return
		# Accessibility toggles work at any time
		if key.pressed and key.keycode == KEY_R:
			_anim_layer.reduced_motion = not _anim_layer.reduced_motion
			_anim_layer.shake_enabled = not _anim_layer.reduced_motion
		elif key.pressed and key.keycode == KEY_M:
			_anim_layer.muted = not _anim_layer.muted
			MusicPlayer.set_muted(_anim_layer.muted)

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
		if not btn.pressed:
			return
		var local_pos := get_local_mouse_position()
		if sandbox_mode and sandbox_placement_handler.is_valid():
			if sandbox_placement_handler.call(local_pos, btn.button_index):
				return
		if btn.button_index == MOUSE_BUTTON_LEFT:
			var col := _renderer.col_from_position(local_pos.x)
			if _renderer.is_col_valid(_state, col):
				column_selected.emit(col)
			elif col >= 0 and not _animating and not _state.input_locked and \
				_state.active_player == CellState.Occupant.PLAYER:
				_anim_layer.play_col_reject(col)
