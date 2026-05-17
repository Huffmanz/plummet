extends Control

signal column_selected(col: int)

@onready var _board_canvas: BoardCanvas = $BoardCanvas
@onready var _ghost_canvas: GhostCanvas = $GhostCanvas
@onready var _queue_canvas: QueueCanvas = $LeftPanel/QueueCanvas
@onready var _player_score_label: Label = $LeftPanel/PlayerScore
@onready var _player_turns_label: Label = $LeftPanel/PlayerTurns
@onready var _ai_score_label: Label = $RightPanel/AIScore
@onready var _ai_turns_label: Label = $RightPanel/AITurns
@onready var _chip_label: Label = $RightPanel/ChipCount
@onready var _enemy_name_label: Label = $RightPanel/EnemyName
@onready var _enemy_gimmick_label: Label = $RightPanel/EnemyGimmick
@onready var _turn_indicator_label: Label = $BottomStrip/TurnIndicator
@onready var _match_info_label: Label = $BottomStrip/MatchInfo
@onready var _rotate_prompt: Label = $RotatePrompt
@onready var _left_panel: Control = $LeftPanel
@onready var _right_panel: Control = $RightPanel
@onready var _bottom_strip: Control = $BottomStrip

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
var _match_active: bool = false


func _ready() -> void:
	_theme = ThemeJam.new()
	_renderer = BoardRenderer.new(_theme)
	_layout_mgr = LayoutManager.new()

	_board_canvas.renderer = _renderer
	_ghost_canvas.renderer = _renderer
	_queue_canvas.renderer = _renderer

	get_viewport().size_changed.connect(_on_viewport_resized)
	_on_viewport_resized()

	_init_game()
	column_selected.connect(_on_column_selected)


func _init_game() -> void:
	_board = BoardEngine.new()
	_score_calc = ScoreCalculator.new()
	_score_tracker = ScoreTracker.new()
	_turn_manager = TurnManager.new()
	_cascade_loop = CascadeLoop.new()
	_ai = AIOpponent.new(0.1)
	_builder = RenderStateBuilder.new()
	_match_active = true

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
		[], [], [], false,
		1, 1, "The Stoic", "No gimmick",
		0, false
	)


func _on_column_selected(col: int) -> void:
	if not _match_active:
		return

	# Player turn
	var p_piece := Piece.new(Piece.Owner.PLAYER)
	_board.drop_piece(col, p_piece)
	var p_result := _cascade_loop.run(_board, Piece.Owner.PLAYER)
	_score_tracker.add_turn(_score_calc.calculate(p_result, 0))
	_turn_manager.advance(_board)

	_state = _build_state()
	_refresh_all()

	if not _match_active:
		return

	# AI turn
	if _turn_manager.current_turn == Piece.Owner.AI:
		_run_ai_turn()


func _run_ai_turn() -> void:
	var ai_col := _ai.choose_column(_board)
	if ai_col < 0:
		_turn_manager.on_ai_skipped()
		_state = _build_state()
		_refresh_all()
		return

	_board.drop_piece(ai_col, _ai.current_piece)
	var ai_result := _cascade_loop.run(_board, Piece.Owner.AI)
	_score_tracker.add_turn(_score_calc.calculate(ai_result, 0))
	_ai.advance_queue()
	_turn_manager.advance(_board)

	_state = _build_state()
	_refresh_all()


func _on_match_ended(_reason: TurnManager.MatchEndReason) -> void:
	_match_active = false


func _refresh_all() -> void:
	_board_canvas.refresh(_state)
	_ghost_canvas.refresh(_state)
	_queue_canvas.refresh(_state)
	_update_labels()


func _update_labels() -> void:
	_player_score_label.text = "Score: %d" % _state.player_score
	_player_turns_label.text = "Turns: %d" % _state.player_turns_remaining
	_ai_score_label.text = "Score: %d" % _state.ai_score
	_ai_turns_label.text = "Turns: %d" % _state.ai_turns_remaining
	_chip_label.text = "Chips: %d" % _state.chip_count
	_enemy_name_label.text = _state.enemy_name
	_enemy_gimmick_label.text = _state.enemy_gimmick
	_match_info_label.text = "Act %d · Match %d" % [_state.act, _state.match_number]
	_turn_indicator_label.text = "YOUR TURN" if _state.active_player == CellState.Occupant.PLAYER \
		else "AI TURN"


func _on_viewport_resized() -> void:
	_layout = _layout_mgr.compute(get_viewport().get_visible_rect().size)
	_renderer.layout = _layout
	_rotate_prompt.visible = _layout.mode == LayoutManager.LayoutMode.TOO_SMALL

	var vp := _layout.viewport_size
	var pw: float = _layout.panel_width
	var bh: float = _layout.bottom_height
	var board_area_h: float = vp.y - bh

	if _layout.mode == LayoutManager.LayoutMode.DESKTOP:
		_left_panel.visible = true
		_right_panel.visible = true
		_left_panel.position = Vector2(0.0, 0.0)
		_left_panel.size = Vector2(pw, board_area_h)
		_right_panel.position = Vector2(vp.x - pw, 0.0)
		_right_panel.size = Vector2(pw, board_area_h)
	else:
		_left_panel.visible = true
		_right_panel.visible = true
		_left_panel.position = Vector2(0.0, 0.0)
		_left_panel.size = Vector2(vp.x, 36.0)
		_right_panel.position = Vector2(0.0, 36.0)
		_right_panel.size = Vector2(vp.x, 36.0)

	_bottom_strip.position = Vector2(0.0, vp.y - bh)
	_bottom_strip.size = Vector2(vp.x, bh)

	var cs: float = _layout.cell_size
	var gap: float = LayoutManager.CELL_GAP
	_queue_canvas.custom_minimum_size = Vector2(cs, cs * 2.0 + gap)

	if _state != null:
		_refresh_all()


func _input(event: InputEvent) -> void:
	if _state == null or _state.input_locked:
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
				column_selected.emit(col)
