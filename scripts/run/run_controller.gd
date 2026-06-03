extends Control

const _GAME_BOARD_SCENE := preload("res://scenes/game/game_board.tscn")
const _BOSS_RELIC_OVERLAY_SCENE := preload("res://scenes/run/boss_relic_offer_overlay.tscn")

# All non-boss opponents; three per act are drawn without replacement. Match 4 uses _ACT_BOSSES.
const _ALL_REGULAR_ENEMIES: Array[String] = [
	"The Stoic",
	"The Blocker",
	"The Gravedigger",
	"The Architect",
	"The Painter",
	"The Shifter",
]
const _ACT_BOSSES: Array = [
	"",
	"The Mirror",
	"The Taxman",
	"The Hoarder",
]
const _ENEMY_GIMMICK: Dictionary = {
	"The Stoic":      "No gimmick",
	"The Blocker":    "Freezes your column every 5 turns",
	"The Gravedigger": "Cleared pieces sink as obstacles",
	"The Architect":  "Only scores clears of 5+",
	"The Mirror":     "Copies your modifier onto their piece",
	"The Painter":    "Recolors a 2×2 area every 6 turns",
	"The Shifter":    "Slides board contents every 8 drops",
	"The Taxman":     "Each piece you place costs 1 chip",
	"The Hoarder":    "Scores double, but only pure-color clears",
}

var _run_state: RunState
var _game_board: GameBoard = null
var _main_menu = null
var _summary_screen = null
func _ready() -> void:
	_main_menu = preload("res://scenes/run/main_menu.tscn").instantiate()
	add_child(_main_menu)
	_main_menu.start_run_pressed.connect(_on_start_run)


func _on_start_run() -> void:
	await TransitionManager.transition_screen(_begin_new_run)


func _begin_new_run() -> void:
	_main_menu.hide()
	_run_state = RunState.new()
	_run_state.player_bag = PieceBag.new(Piece.Owner.PLAYER)
	_run_state.chip_count = 0
	_run_state.win_streak = 0
	_start_match()


func _get_relic_manager() -> RelicManager:
	return _run_state.relic_manager if _run_state != null else null


func _start_match() -> void:
	_teardown_game_board()

	if _run_state.match_in_act == 1:
		_run_state.enemies_used_this_act.clear()

	var enemy_name := _pick_enemy_for_match()
	var gimmick := _ENEMY_GIMMICK.get(enemy_name, "No gimmick") as String

	_game_board = _GAME_BOARD_SCENE.instantiate()
	_game_board.standalone = false
	add_child(_game_board)
	move_child(_game_board, -1)
	_game_board.match_complete.connect(_on_match_complete)
	_game_board.run_shop_finished.connect(_on_run_shop_finished)
	# Momentum relic: starting score bonus for consecutive wins
	var momentum_bonus := _run_state.relic_manager.momentum_bonus(_run_state.win_streak)

	_game_board.setup_match(
		_run_state.player_bag,
		_run_state.chip_count,
		_run_state.win_streak,
		_run_state.act,
		_run_state.match_in_act,
		enemy_name,
		gimmick,
		_run_state.is_boss_match(),
		_run_state.relic_manager
	)
	if momentum_bonus > 0:
		_game_board._score_tracker.add_starting_bonus(momentum_bonus)


func _pick_enemy_for_match() -> String:
	if _run_state.is_boss_match():
		return _ACT_BOSSES[_run_state.act] as String

	# First match of the run is always The Stoic (tutorial).
	if _run_state.total_matches_played() == 0:
		_run_state.enemies_used_this_act.append("The Stoic")
		return "The Stoic"

	var pool := _unused_regular_enemies()
	if pool.is_empty():
		push_warning("RunController: no unused enemies for act %d match %d" % [
			_run_state.act, _run_state.match_in_act
		])
		return "The Stoic"

	pool.shuffle()
	var pick: String = pool[0]
	_run_state.enemies_used_this_act.append(pick)
	return pick


func _unused_regular_enemies() -> Array[String]:
	var pool: Array[String] = []
	for enemy_id in _ALL_REGULAR_ENEMIES:
		if not _run_state.enemies_used_this_act.has(enemy_id):
			pool.append(enemy_id)
	return pool


func _on_match_complete(
	player_won: bool,
	player_score: int,
	_ai_score: int,
	chips: int,
	win_streak: int,
	max_cascade: int,
	cross_color_count: int
) -> void:
	_run_state.last_match_score = player_score
	_run_state.total_score += player_score
	_run_state.chip_count = chips
	_run_state.win_streak = win_streak
	_run_state.highest_cascade = maxi(_run_state.highest_cascade, max_cascade)
	_run_state.cross_color_count += cross_color_count

	if not player_won:
		# Cushion relic absorbs one loss
		if _run_state.relic_manager.try_cushion():
			_run_state.win_streak = 0
			_run_state.match_in_act += 1
			if _run_state.match_in_act > 4:
				_run_state.act += 1
				_run_state.match_in_act = 1
			if _run_state.is_run_complete():
				call_deferred("_end_run", true)
			else:
				call_deferred("_start_match")
		else:
			_run_state.win_streak = 0
			call_deferred("_end_run", false)
		return

	var was_regular_win := not _run_state.is_boss_match()

	# Award fragments for this match
	if _run_state.is_boss_match():
		_run_state.bosses_defeated += 1
		_run_state.fragments_earned += 5
		_award_act_fragments()
	else:
		_run_state.regular_wins += 1
		_run_state.fragments_earned += 3

	# Advance match pointer
	_run_state.match_in_act += 1
	if _run_state.match_in_act > 4:
		_run_state.act += 1
		_run_state.match_in_act = 1

	if _run_state.is_run_complete():
		call_deferred("_end_run", true)
	elif _run_state.match_in_act == 1:
		# Just entered a new act (via boss win) — offer boss relic drop
		call_deferred("_offer_boss_relic")
	elif was_regular_win:
		# Run state advanced; shop on current board then _on_run_shop_finished starts next match.
		pass
	else:
		call_deferred("_start_match")


func _on_run_shop_finished(chips: int) -> void:
	_run_state.chip_count = chips
	call_deferred("_start_match")


const _BOSS_DROP_RELICS: Array[String] = ["Cushion", "Patron", "EchoChamber", "Cartographer"]

func _offer_boss_relic() -> void:
	# Pick 2 relic options the player doesn't already own
	var available: Array[String] = []
	for r in _BOSS_DROP_RELICS:
		if not _run_state.relic_manager.has_relic(r):
			available.append(r)
	available.shuffle()
	var offer_a: String = available[0] if available.size() > 0 else ""
	var offer_b: String = available[1] if available.size() > 1 else ""

	if offer_a.is_empty() or not _run_state.relic_manager.can_add_relic():
		call_deferred("_start_match")
		return

	var offers: Array[String] = [offer_a]
	if not offer_b.is_empty():
		offers.append(offer_b)
	var overlay: BossRelicOfferOverlay = _BOSS_RELIC_OVERLAY_SCENE.instantiate()
	overlay.z_index = 20
	overlay.relic_chosen.connect(_on_boss_relic_chosen)
	overlay.finished.connect(func() -> void: call_deferred("_start_match"), CONNECT_ONE_SHOT)
	add_child(overlay)
	overlay.setup_offers(offers)


func _on_boss_relic_chosen(relic_id: String) -> void:
	if _run_state.relic_manager.can_add_relic():
		_run_state.relic_manager.add_relic(relic_id)


func _teardown_game_board() -> void:
	if _game_board == null:
		return
	var board := _game_board
	_game_board = null
	if board.match_complete.is_connected(_on_match_complete):
		board.match_complete.disconnect(_on_match_complete)
	if board.run_shop_finished.is_connected(_on_run_shop_finished):
		board.run_shop_finished.disconnect(_on_run_shop_finished)
	if is_instance_valid(board):
		board.free()


func _award_act_fragments() -> void:
	match _run_state.act:
		1:
			_run_state.fragments_earned += 10
		2:
			_run_state.fragments_earned += 20
		3:
			_run_state.fragments_earned += 40


func _end_run(victory: bool) -> void:
	# Score threshold bonuses (stacking)
	if _run_state.total_score >= 2000:
		_run_state.fragments_earned += 5
	if _run_state.total_score >= 5000:
		_run_state.fragments_earned += 10

	_teardown_game_board()

	_summary_screen = preload("res://scenes/run/run_summary_screen.tscn").instantiate()
	add_child(_summary_screen)
	_summary_screen.show_summary(_run_state, victory)
	_summary_screen.new_run_pressed.connect(_on_new_run)
	_summary_screen.main_menu_pressed.connect(_on_main_menu)


func _on_new_run() -> void:
	_summary_screen.queue_free()
	_summary_screen = null
	_main_menu.show()


func _on_main_menu() -> void:
	_summary_screen.queue_free()
	_summary_screen = null
	_main_menu.show()
