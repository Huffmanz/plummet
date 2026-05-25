extends Control
## Visual sandbox for enemy / boss gimmicks. Run `scenes/tests/boss_gimmick_test.tscn` (F6).

const _ENEMY_GIMMICK: Dictionary = {
	"The Stoic": "No gimmick",
	"The Blocker": "Freezes your column every 5 turns",
	"The Gravedigger": "Cleared pieces sink as obstacles",
	"The Architect": "Only scores clears of 5+",
	"The Mirror": "Copies your modifier onto their piece",
	"The Painter": "Recolors a 2×2 area every 6 turns",
	"The Shifter": "Slides board contents every 8 drops",
	"The Taxman": "Each piece you place costs 1 chip",
	"The Hoarder": "Scores double, but only pure-color clears",
}

const _ENEMIES: Array[Dictionary] = [
	{"id": "The Stoic", "boss": false, "act": 1,
		"tip": "Tutorial baseline — no gimmick."},
	{"id": "The Blocker", "boss": false, "act": 1,
		"tip": "After every 5 drops, your last column is frozen for your next 2 turns (AI cannot drop there either)."},
	{"id": "The Gravedigger", "boss": false, "act": 2,
		"tip": "Each clear leaves a locked tombstone at the bottom of that column."},
	{"id": "The Architect", "boss": false, "act": 2,
		"tip": "AI never clears 4-lines — only 5+. Watch it build long lines."},
	{"id": "The Mirror", "boss": true, "act": 1,
		"tip": "Boss — copies the modifier on your last piece onto the AI's next drop. Use bag modifiers."},
	{"id": "The Painter", "boss": false, "act": 3,
		"tip": "Every 6 AI turns, steals a 2×2 patch (PAINT popup)."},
	{"id": "The Shifter", "boss": false, "act": 3,
		"tip": "Every 8 drops, the whole board slides left or right."},
	{"id": "The Taxman", "boss": true, "act": 2,
		"tip": "Boss — every piece you drop costs 1 chip. Clears can still earn chips; placements add up fast."},
	{"id": "The Hoarder", "boss": true, "act": 3,
		"tip": "Boss — AI only scores pure-color lines (pollute with your pieces)."},
]

@onready var _game_board: GameBoard = %GameBoard
@onready var _enemy_list: VBoxContainer = %EnemyList
@onready var _tip_label: RichTextLabel = %TipLabel
@onready var _status_label: Label = %StatusLabel
@onready var _reset_btn: Button = %ResetBtn
@onready var _player_plus_btn: Button = %PlayerPlusBtn
@onready var _ai_plus_btn: Button = %AIPlusBtn

var _player_bag: PieceBag
var _selected_id: String = "The Blocker"
var _enemy_buttons: Dictionary = {}  # enemy_id -> Button


func _ready() -> void:
	_player_bag = _default_bag()
	_build_enemy_buttons()
	_reset_btn.pressed.connect(_restart_match)
	_player_plus_btn.pressed.connect(_cheat_player_score)
	_ai_plus_btn.pressed.connect(_cheat_ai_score)
	_game_board.gimmick_test_match_finished.connect(_on_match_finished)
	_select_enemy(_selected_id)


func _default_bag() -> PieceBag:
	var bag := PieceBag.new(Piece.Owner.PLAYER)
	# One modified piece helps test The Mirror.
	bag.get_piece_at(0).modifier = "Ignite"
	return bag


func _build_enemy_buttons() -> void:
	for child in _enemy_list.get_children():
		child.queue_free()
	_enemy_buttons.clear()

	for entry: Dictionary in _ENEMIES:
		var enemy_id: String = entry.id
		var btn := Button.new()
		btn.text = ("BOSS · " if entry.boss else "") + enemy_id
		btn.toggle_mode = true
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(func() -> void: _select_enemy(enemy_id))
		_enemy_list.add_child(btn)
		_enemy_buttons[enemy_id] = btn


func _select_enemy(enemy_id: String) -> void:
	_selected_id = enemy_id
	for id: String in _enemy_buttons:
		var btn: Button = _enemy_buttons[id]
		btn.button_pressed = id == enemy_id
	_refresh_tip()
	_restart_match()


func _restart_match() -> void:
	var entry := _entry_for(_selected_id)
	var gimmick: String = _ENEMY_GIMMICK.get(_selected_id, "No gimmick") as String
	_game_board.setup_match(
		_player_bag,
		20,
		0,
		entry.act,
		1,
		_selected_id,
		gimmick,
		entry.boss,
		null,
	)
	_status_label.text = "Playing vs %s" % _selected_id


func _entry_for(enemy_id: String) -> Dictionary:
	for entry: Dictionary in _ENEMIES:
		if entry.id == enemy_id:
			return entry
	return _ENEMIES[0]


func _refresh_tip() -> void:
	var entry := _entry_for(_selected_id)
	_tip_label.text = "[b]%s[/b]\n%s" % [_selected_id, entry.tip]


func _on_match_finished(player_won: bool) -> void:
	_status_label.text = "Match over — %s. Select an enemy or press Reset." % (
		"You win" if player_won else "AI wins"
	)


func _cheat_player_score() -> void:
	_game_board.gimmick_test_add_score(Piece.Owner.PLAYER, 500)
	_status_label.text = "+500 player"


func _cheat_ai_score() -> void:
	_game_board.gimmick_test_add_score(Piece.Owner.AI, 500)
	_status_label.text = "+500 AI"
