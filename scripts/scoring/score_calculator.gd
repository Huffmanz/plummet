class_name ScoreCalculator extends RefCounted

func calculate(result: CascadeResult, modifier_triggers: int) -> TurnScore:
	var turn := TurnScore.new()

	# Group clear points by (owner, depth) using Vector2i(owner, depth) as key.
	var depth_points: Dictionary = {}
	var depth_count: Dictionary = {}

	for tc: TaggedClear in result.clears:
		var key := Vector2i(tc.run.owner, tc.depth)
		var pts: int = _base_value(tc.run.cells.size()) * _depth_multiplier(tc.depth)
		depth_points[key] = depth_points.get(key, 0) + pts
		depth_count[key] = depth_count.get(key, 0) + 1

	var total: int = 0
	for key: Vector2i in depth_points:
		var pts: int = depth_points[key]
		if depth_count[key] >= 2:
			pts = pts * 3 / 2  # ×1.5 simultaneous bonus
		total += pts

	if result.cross_color:
		total += 150

	total += modifier_triggers * 25

	if result.attribution == Piece.Owner.PLAYER:
		turn.player_points = total
	else:
		turn.ai_points = total

	return turn


func _base_value(cell_count: int) -> int:
	if cell_count >= 6:
		return 500
	if cell_count == 5:
		return 250
	return 100


func _depth_multiplier(depth: int) -> int:
	return 1 << depth
