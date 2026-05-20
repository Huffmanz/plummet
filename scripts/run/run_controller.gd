extends Control

const _GAME_BOARD_SCENE := preload("res://scenes/game/game_board.tscn")

# Enemy name/gimmick per [act][match_in_act] (match_in_act 1-4, 4=boss)
const _ENEMY_SCHEDULE: Array = [
	[],  # unused index 0
	["The Stoic", "The Blocker", "", "The Mirror"],          # act 1
	["The Gravedigger", "The Architect", "", "The Inverter"], # act 2
	["The Painter", "The Shifter", "", "The Hoarder"],        # act 3
]
const _ENEMY_GIMMICK: Dictionary = {
	"The Stoic":      "No gimmick",
	"The Blocker":    "Freezes your column every 5 turns",
	"The Gravedigger": "Cleared pieces sink as obstacles",
	"The Architect":  "Only scores clears of 5+",
	"The Mirror":     "Copies your modifier onto their piece",
	"The Painter":    "Recolors a 2×2 area every 6 turns",
	"The Shifter":    "Slides board contents every 8 drops",
	"The Inverter":   "Flips the board once per match",
	"The Hoarder":    "Scores double, but only pure-color clears",
}

var _run_state: RunState
var _game_board = null
var _main_menu = null
var _summary_screen = null
# Cartographer relic: overrides first-match enemy order per act (act -> [enemy1, enemy2])
var _cartographer_overrides: Dictionary = {}


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
	var had_board := _game_board != null
	_teardown_game_board()
	if had_board:
		await get_tree().process_frame

	var enemy_name := _get_enemy_name(_run_state.act, _run_state.match_in_act)
	var gimmick := _ENEMY_GIMMICK.get(enemy_name, "No gimmick") as String

	_game_board = _GAME_BOARD_SCENE.instantiate()
	_game_board.standalone = false
	add_child(_game_board)
	move_child(_game_board, -1)
	_game_board.match_complete.connect(_on_match_complete)
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


func _get_enemy_name(act: int, match_in_act: int) -> String:
	var schedule: Array = _ENEMY_SCHEDULE[act]
	if _cartographer_overrides.has(act):
		var override: Array = _cartographer_overrides[act]
		if match_in_act - 1 < override.size():
			return override[match_in_act - 1]
	if match_in_act == 3:
		return schedule[randi() % 2]
	return schedule[match_in_act - 1]


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
	else:
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
		# Nothing to offer — check Cartographer then advance
		if _run_state.relic_manager.has_relic("Cartographer"):
			call_deferred("_offer_cartographer_choice")
		else:
			call_deferred("_start_match")
		return

	var overlay := _build_relic_offer_overlay(offer_a, offer_b)
	add_child(overlay)


func _offer_cartographer_choice() -> void:
	var act := _run_state.act
	if act > 3 or not _ENEMY_SCHEDULE[act] is Array:
		call_deferred("_start_match")
		return
	var schedule: Array = _ENEMY_SCHEDULE[act]
	var enemy_a: String = schedule[0]
	var enemy_b: String = schedule[1]
	if enemy_a.is_empty() or enemy_b.is_empty():
		call_deferred("_start_match")
		return

	var overlay := Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 20

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.05, 0.05, 0.12, 0.88)
	overlay.add_child(bg)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.add_theme_constant_override("separation", 16)
	overlay.add_child(vbox)

	var title := Label.new()
	title.text = "CARTOGRAPHER — CHOOSE FIRST ENEMY"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	for chosen_first in [enemy_a, enemy_b]:
		var chosen_second := enemy_b if chosen_first == enemy_a else enemy_a
		var btn := Button.new()
		btn.text = chosen_first + " first"
		btn.add_theme_font_size_override("font_size", 15)
		btn.custom_minimum_size = Vector2(260, 48)
		btn.pressed.connect(func():
			_cartographer_overrides[act] = [chosen_first, chosen_second]
			overlay.queue_free()
			call_deferred("_start_match")
		)
		vbox.add_child(btn)

	add_child(overlay)


func _build_relic_offer_overlay(offer_a: String, offer_b: String) -> Control:
	var overlay := Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 20

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.05, 0.05, 0.12, 0.88)
	overlay.add_child(bg)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.add_theme_constant_override("separation", 16)
	overlay.add_child(vbox)

	var title := Label.new()
	title.text = "BOSS DEFEATED — CHOOSE A RELIC"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	for offer in [offer_a, offer_b]:
		if offer.is_empty():
			continue
		var btn := Button.new()
		btn.text = offer
		btn.add_theme_font_size_override("font_size", 16)
		btn.custom_minimum_size = Vector2(260, 48)
		btn.pressed.connect(func():
			if _run_state.relic_manager.can_add_relic():
				_run_state.relic_manager.add_relic(offer)
			overlay.queue_free()
			if _run_state.match_in_act == 1 and _run_state.relic_manager.has_relic("Cartographer"):
				call_deferred("_offer_cartographer_choice")
			else:
				call_deferred("_start_match")
		)
		vbox.add_child(btn)

	return overlay


func _teardown_game_board() -> void:
	if _game_board == null:
		return
	if _game_board.match_complete.is_connected(_on_match_complete):
		_game_board.match_complete.disconnect(_on_match_complete)
	_game_board.queue_free()
	_game_board = null


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
