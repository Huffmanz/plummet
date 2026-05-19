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


func _ready() -> void:
	_main_menu = preload("res://scenes/run/main_menu.tscn").instantiate()
	add_child(_main_menu)
	_main_menu.start_run_pressed.connect(_on_start_run)


func _on_start_run() -> void:
	_main_menu.hide()
	_run_state = RunState.new()
	_run_state.player_bag = PieceBag.new(Piece.Owner.PLAYER)
	_run_state.chip_count = 0
	_run_state.win_streak = 0
	_start_match()


func _start_match() -> void:
	if _game_board != null:
		_game_board.queue_free()

	var enemy_name := _get_enemy_name(_run_state.act, _run_state.match_in_act)
	var gimmick := _ENEMY_GIMMICK.get(enemy_name, "No gimmick") as String

	_game_board = _GAME_BOARD_SCENE.instantiate()
	_game_board.standalone = false
	add_child(_game_board)
	_game_board.match_complete.connect(_on_match_complete)
	_game_board.setup_match(
		_run_state.player_bag,
		_run_state.chip_count,
		_run_state.win_streak,
		_run_state.act,
		_run_state.match_in_act,
		enemy_name,
		gimmick,
		_run_state.is_boss_match()
	)


func _get_enemy_name(act: int, match_in_act: int) -> String:
	var schedule: Array = _ENEMY_SCHEDULE[act]
	if match_in_act == 3:
		# Random from first two in act
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
		_run_state.win_streak = 0
		_end_run(false)
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
		_end_run(true)
	else:
		_start_match()


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

	if _game_board != null:
		_game_board.queue_free()
		_game_board = null

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
