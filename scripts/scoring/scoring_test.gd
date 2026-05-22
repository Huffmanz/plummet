extends Node

var _passed: int = 0
var _failed: int = 0
var _calc: ScoreCalculator


func _ready() -> void:
	_calc = ScoreCalculator.new()
	test_no_clears_zero_points()
	test_single_4_in_a_row_depth_0()
	test_single_4_in_a_row_depth_1()
	test_four_embers_linear_multiplier()
	test_one_ember_linear_multiplier()
	test_single_5_in_a_row_depth_0()
	test_single_6_in_a_row_depth_0()
	test_two_simultaneous_4_in_a_row_depth_0()
	test_simultaneous_bonus_not_applied_across_depths()
	test_cross_color_bonus()
	test_modifier_triggers()
	test_ai_attribution()
	test_score_accumulates()
	test_score_delta()
	test_no_clears_turn_adds_zero()
	test_match_result_player_wins()
	test_match_result_ai_wins()
	test_match_result_tie()
	test_round_breakdown_stored()
	print("-----------------------------")
	print("Results: %d passed, %d failed" % [_passed, _failed])


func _assert(label: String, condition: bool) -> void:
	if condition:
		print("[PASS] %s" % label)
		_passed += 1
	else:
		print("[FAIL] %s" % label)
		_failed += 1


func _run(owner: Piece.Owner, cell_count: int) -> MatchedRun:
	var cells: Array[Vector2i] = []
	for i in cell_count:
		cells.append(Vector2i(i, 0))
	return MatchedRun.new(owner, cells)


func _result(attribution: Piece.Owner) -> CascadeResult:
	return CascadeResult.new(attribution)


func test_no_clears_zero_points() -> void:
	var r := _result(Piece.Owner.PLAYER)
	var turn := _calc.calculate(r, 0)
	_assert("no clears: 0 player points", turn.player_points == 0)
	_assert("no clears: 0 ai points", turn.ai_points == 0)


func test_single_4_in_a_row_depth_0() -> void:
	var r := _result(Piece.Owner.PLAYER)
	r.clears.append(TaggedClear.new(_run(Piece.Owner.PLAYER, 4), 0))
	var turn := _calc.calculate(r, 0)
	_assert("4-in-a-row depth 0 = 100", turn.player_points == 100)


func test_single_4_in_a_row_depth_1() -> void:
	var r := _result(Piece.Owner.PLAYER)
	r.clears.append(TaggedClear.new(_run(Piece.Owner.PLAYER, 4), 1))
	var turn := _calc.calculate(r, 0)
	_assert("4-in-a-row depth 1 = 200", turn.player_points == 200)


func test_four_embers_linear_multiplier() -> void:
	var r := _result(Piece.Owner.PLAYER)
	var tc := TaggedClear.new(_run(Piece.Owner.PLAYER, 4), 0)
	tc.ember_bonus = 4
	r.clears.append(tc)
	var turn := _calc.calculate(r, 0)
	_assert("4 Embers at cascade 0 = 100 × 4 = 400", turn.player_points == 400)


func test_one_ember_linear_multiplier() -> void:
	var r := _result(Piece.Owner.PLAYER)
	var tc := TaggedClear.new(_run(Piece.Owner.PLAYER, 4), 0)
	tc.ember_bonus = 1
	r.clears.append(tc)
	var turn := _calc.calculate(r, 0)
	_assert("1 Ember at cascade 0 = 100 × 2 = 200", turn.player_points == 200)


func test_single_5_in_a_row_depth_0() -> void:
	var r := _result(Piece.Owner.PLAYER)
	r.clears.append(TaggedClear.new(_run(Piece.Owner.PLAYER, 5), 0))
	var turn := _calc.calculate(r, 0)
	_assert("5-in-a-row depth 0 = 250", turn.player_points == 250)


func test_single_6_in_a_row_depth_0() -> void:
	var r := _result(Piece.Owner.PLAYER)
	r.clears.append(TaggedClear.new(_run(Piece.Owner.PLAYER, 6), 0))
	var turn := _calc.calculate(r, 0)
	_assert("6-in-a-row depth 0 = 500", turn.player_points == 500)


# (100 + 100) × 1.5 = 300
func test_two_simultaneous_4_in_a_row_depth_0() -> void:
	var r := _result(Piece.Owner.PLAYER)
	r.clears.append(TaggedClear.new(_run(Piece.Owner.PLAYER, 4), 0))
	r.clears.append(TaggedClear.new(_run(Piece.Owner.PLAYER, 4), 0))
	var turn := _calc.calculate(r, 0)
	_assert("2x simultaneous 4-in-a-row = 300", turn.player_points == 300)


# One clear at depth 0 and one at depth 1 — no simultaneous bonus.
func test_simultaneous_bonus_not_applied_across_depths() -> void:
	var r := _result(Piece.Owner.PLAYER)
	r.clears.append(TaggedClear.new(_run(Piece.Owner.PLAYER, 4), 0))
	r.clears.append(TaggedClear.new(_run(Piece.Owner.PLAYER, 4), 1))
	var turn := _calc.calculate(r, 0)
	_assert("different depths: 100 + 200 = 300 (no simult bonus)", turn.player_points == 300)


func test_cross_color_bonus() -> void:
	var r := _result(Piece.Owner.PLAYER)
	r.clears.append(TaggedClear.new(_run(Piece.Owner.PLAYER, 4), 0))
	r.cross_color = true
	var turn := _calc.calculate(r, 0)
	_assert("cross_color adds +150: 100 + 150 = 250", turn.player_points == 250)


func test_modifier_triggers() -> void:
	var r := _result(Piece.Owner.PLAYER)
	var turn := _calc.calculate(r, 3)
	_assert("3 modifier triggers = 75", turn.player_points == 75)


func test_ai_attribution() -> void:
	var r := _result(Piece.Owner.AI)
	r.clears.append(TaggedClear.new(_run(Piece.Owner.AI, 4), 0))
	var turn := _calc.calculate(r, 0)
	_assert("AI attribution: ai_points = 100", turn.ai_points == 100)
	_assert("AI attribution: player_points = 0", turn.player_points == 0)


func test_score_accumulates() -> void:
	var tracker := ScoreTracker.new()
	var t1 := TurnScore.new()
	t1.player_points = 100
	var t2 := TurnScore.new()
	t2.player_points = 250
	tracker.add_turn(t1)
	tracker.add_turn(t2)
	_assert("scores accumulate: 350", tracker.player_score == 350)


func test_score_delta() -> void:
	var tracker := ScoreTracker.new()
	var t1 := TurnScore.new()
	t1.player_points = 100
	var t2 := TurnScore.new()
	t2.player_points = 250
	tracker.add_turn(t1)
	tracker.add_turn(t2)
	_assert("delta reflects last turn: 250", tracker.player_delta == 250)


func test_no_clears_turn_adds_zero() -> void:
	var tracker := ScoreTracker.new()
	tracker.add_turn(TurnScore.new())
	_assert("zero-point turn: scores still 0", tracker.player_score == 0 and tracker.ai_score == 0)


func test_match_result_player_wins() -> void:
	var tracker := ScoreTracker.new()
	var t := TurnScore.new()
	t.player_points = 100
	tracker.add_turn(t)
	var match_r := tracker.get_match_result()
	_assert("player wins: is_tie false", not match_r.is_tie)
	_assert("player wins: winner is PLAYER", match_r.winner == Piece.Owner.PLAYER)


func test_match_result_ai_wins() -> void:
	var tracker := ScoreTracker.new()
	var t := TurnScore.new()
	t.ai_points = 200
	tracker.add_turn(t)
	var match_r := tracker.get_match_result()
	_assert("ai wins: winner is AI", match_r.winner == Piece.Owner.AI)


func test_match_result_tie() -> void:
	var tracker := ScoreTracker.new()
	var match_r := tracker.get_match_result()
	_assert("tie: is_tie true", match_r.is_tie)


func test_round_breakdown_stored() -> void:
	var tracker := ScoreTracker.new()
	var t1 := TurnScore.new()
	t1.player_points = 100
	var t2 := TurnScore.new()
	t2.ai_points = 200
	tracker.add_turn(t1)
	tracker.add_turn(t2)
	var match_r := tracker.get_match_result()
	_assert("round breakdown: 2 rounds stored", match_r.rounds.size() == 2)
	_assert("round breakdown: round 1 player = 100", match_r.rounds[0].player_points == 100)
	_assert("round breakdown: round 2 ai = 200", match_r.rounds[1].ai_points == 200)
