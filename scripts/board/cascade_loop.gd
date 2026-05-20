class_name CascadeLoop extends RefCounted

# Hooks called at specific points in the loop for modifier resolution.
# on_land:        func(board: BoardEngine) — after piece lands, before first clear check
# on_clear:       func(board: BoardEngine, runs: Array[MatchedRun]) — after detection, before removal
# on_pre_gravity: func(board: BoardEngine) — after remove_clears, before apply_gravity
# on_gravity:     func(board: BoardEngine) — after gravity settles each round (Echo drop)
var _on_land_hooks: Array[Callable] = []
var _on_clear_hooks: Array[Callable] = []
var _on_pre_gravity_hooks: Array[Callable] = []
var _on_gravity_hooks: Array[Callable] = []


func register_on_land(hook: Callable) -> void:
	_on_land_hooks.append(hook)


func register_on_clear(hook: Callable) -> void:
	_on_clear_hooks.append(hook)


func register_on_pre_gravity(hook: Callable) -> void:
	_on_pre_gravity_hooks.append(hook)


func register_on_gravity(hook: Callable) -> void:
	_on_gravity_hooks.append(hook)


func run(board: BoardEngine, attribution: Piece.Owner) -> CascadeResult:
	var result := CascadeResult.new(attribution)

	_fire(_on_land_hooks, [board])

	var depth: int = 0
	var ai_cleared: bool = false

	while true:
		var runs: Array[MatchedRun] = board.detect_clears()
		if runs.is_empty():
			break

		_fire(_on_clear_hooks, [board, runs])

		for matched_run in runs:
			result.clears.append(TaggedClear.new(matched_run, depth))

		if attribution == Piece.Owner.PLAYER:
			var has_player_clear := false
			var has_ai_clear := false
			for matched_run in runs:
				if matched_run.owner == Piece.Owner.PLAYER:
					has_player_clear = true
				else:
					has_ai_clear = true
			if has_player_clear and ai_cleared:
				result.cross_color = true
			if has_ai_clear:
				ai_cleared = true

		board.remove_clears(runs)

		_fire(_on_pre_gravity_hooks, [board])
		board.apply_gravity()

		_fire(_on_gravity_hooks, [board])

		depth += 1

	result.max_depth = maxi(0, depth - 1)
	return result


func _fire(hooks: Array[Callable], args: Array) -> void:
	for hook in hooks:
		hook.callv(args)
