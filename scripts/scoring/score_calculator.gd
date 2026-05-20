class_name ScoreCalculator extends RefCounted


func calculate(result: CascadeResult, modifier_bonus_points: int, surge_active: bool) -> TurnScore:
	var turn := TurnScore.new()

	# Group clear points by (owner, depth) using Vector2i(owner, depth) as key.
	var depth_points: Dictionary = {}
	var depth_count: Dictionary = {}

	for tc: TaggedClear in result.clears:
		var key := Vector2i(tc.run.owner, tc.depth)
		var base: int = _base_value(tc.run.cells.size())

		# Prism: doubles base value (only one Prism per clear counts — no stacking)
		if tc.has_prism:
			base *= 2

		# Surge: ×3 base if this is the surge-active piece clearing on landing (depth 0)
		if tc.has_surge and tc.depth == 0 and surge_active:
			base *= 3

		var pts: int = base * _depth_multiplier(tc.depth)
		depth_points[key] = depth_points.get(key, 0) + pts
		depth_count[key] = depth_count.get(key, 0) + 1

	for key: Vector2i in depth_points:
		var pts: int = depth_points[key]
		if depth_count[key] >= 2:
			pts = pts * 3 / 2  # ×1.5 simultaneous bonus
		if key.x == Piece.Owner.PLAYER:
			turn.player_points += pts
		else:
			turn.ai_points += pts

	# Cross-color bonus and modifier/bounty points go to whoever engineered the chain.
	var bonus: int = modifier_bonus_points
	if result.cross_color:
		bonus += 150
	if result.attribution == Piece.Owner.PLAYER:
		turn.player_points += bonus
	else:
		turn.ai_points += bonus

	return turn


func _base_value(cell_count: int) -> int:
	if cell_count >= 6:
		return 500
	if cell_count == 5:
		return 250
	return 100


func _depth_multiplier(depth: int) -> int:
	return 1 << depth
