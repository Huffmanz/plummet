extends Node

var _passed: int = 0
var _failed: int = 0


func _ready() -> void:
	test_blocker_freezes_column()
	test_architect_filters_four_clear()
	test_gravedigger_places_locked()
	test_architect_ignores_four_clear_scoring()
	test_inverter_triggers_when_trailing()
	print("-----------------------------")
	print("Gimmick results: %d passed, %d failed" % [_passed, _failed])


func _assert(label: String, condition: bool) -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
		push_error("FAIL: " + label)


func test_blocker_freezes_column() -> void:
	var board := BoardEngine.new()
	var ai := AIOpponent.new(0.0)
	var st := ScoreTracker.new()
	var gimmick := EnemyGimmickController.for_enemy("The Blocker")
	gimmick.setup(ai, board, st)
	for i in 5:
		gimmick.on_drop()
	ai.fire_on_player_piece_landed(board, 3, 0)
	_assert("Blocker freezes player column", board.is_column_frozen(3))
	_assert("Frozen column is full", board.is_column_full(3))
	_assert("Freeze lasts through AI without player tick", board.frozen_columns[3] == 2)
	gimmick._on_blocker_player_turn_start(board)
	_assert("One player turn tick", board.frozen_columns[3] == 1)
	gimmick._on_blocker_player_turn_start(board)
	_assert("Unfrozen after two player turn starts", not board.is_column_frozen(3))


func test_architect_filters_four_clear() -> void:
	var gimmick := EnemyGimmickController.for_enemy("The Architect")
	var runs: Array[MatchedRun] = [
		MatchedRun.new(Piece.Owner.AI, [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)]),
		MatchedRun.new(Piece.Owner.PLAYER, [Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1)]),
	]
	var filtered := gimmick.filter_clears(runs)
	_assert("Architect removes AI 4-clear", filtered.size() == 1)
	_assert("Player 4-clear kept", filtered[0].owner == Piece.Owner.PLAYER)


func test_gravedigger_places_locked() -> void:
	var board := BoardEngine.new()
	var ai := AIOpponent.new(0.0)
	var st := ScoreTracker.new()
	var gimmick := EnemyGimmickController.for_enemy("The Gravedigger")
	gimmick.setup(ai, board, st)
	var result := CascadeResult.new(Piece.Owner.PLAYER)
	var run := MatchedRun.new(Piece.Owner.PLAYER, [Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, 0), Vector2i(5, 0)])
	result.clears.append(TaggedClear.new(run, 0))
	gimmick._on_gravedigger_cascade(board, result)
	var p: Piece = board.get_cell(2, 0)
	_assert("Gravedigger places locked at column floor", p != null and p.type == Piece.Type.LOCKED)


func test_architect_ignores_four_clear_scoring() -> void:
	var board := BoardEngine.new()
	var ai := AIOpponent.new(0.0)
	var st := ScoreTracker.new()
	var gimmick := EnemyGimmickController.for_enemy("The Architect")
	gimmick.setup(ai, board, st)
	var result := CascadeResult.new(Piece.Owner.AI)
	var run := MatchedRun.new(Piece.Owner.AI, [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)])
	result.clears.append(TaggedClear.new(run, 0))
	var turn := gimmick.adjust_ai_turn_score(TurnScore.new(), result)
	_assert("Architect scores 0 for 4-clear", turn.ai_points == 0)


func test_inverter_triggers_when_trailing() -> void:
	var board := BoardEngine.new()
	var ai := AIOpponent.new(0.0)
	var st := ScoreTracker.new()
	st.player_score = 500
	st.ai_score = 100
	var gimmick := EnemyGimmickController.for_enemy("The Inverter")
	gimmick.setup(ai, board, st)
	gimmick._on_inverter_turn_start(board)
	_assert("Inverter flips gravity when trailing", board.gravity_up)
