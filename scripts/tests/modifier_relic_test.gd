extends Control

const PIECE_TYPES: Array[Piece.Type] = [
	Piece.Type.NORMAL, Piece.Type.PRISM, Piece.Type.COIN,
	Piece.Type.EMBER, Piece.Type.SHARD,
]
const PIECE_TYPE_IDS: Array[String] = ["NORMAL", "PRISM", "COIN", "EMBER", "SHARD"]

const MODIFIERS: Array[String] = [
	"", "Ignite", "Magnet", "Deposit", "Ripple",
	"Echo", "Detonate", "Bounty", "Surge",
]

const RELICS: Array[String] = [
	"Cushion", "Almanac", "Forge", "Lens", "Stockpile",
	"Patron", "EchoChamber", "Momentum", "Cartographer", "Compass",
]

@onready var _game_board := %GameBoard
@onready var _type_grid := %TypeGrid
@onready var _mod_grid := %ModGrid
@onready var _relic_grid := %RelicGrid
@onready var _next_label: Label = %NextLabel
@onready var _chip_label: Label = %ChipLabel
@onready var _log_label: Label = %LogLabel
@onready var _reset_btn: Button = %ResetBtn

var _player_bag: PieceBag
var _relic_manager: RelicManager
var _selected_type: Piece.Type = Piece.Type.NORMAL
var _selected_modifier: String = ""


func _ready() -> void:
	_player_bag = PieceBag.new(Piece.Owner.PLAYER)
	_relic_manager = RelicManager.new()

	# Wire type buttons + tooltips
	var type_btns := _type_grid.get_children()
	for i in type_btns.size():
		var btn := type_btns[i] as Button
		var idx := i
		btn.pressed.connect(func(): _select_type(idx))
		var td := DataRegistry.get_piece_type(PIECE_TYPE_IDS[i])
		if td:
			btn.tooltip_text = td.description

	# Wire modifier buttons + tooltips
	var mod_btns := _mod_grid.get_children()
	for i in mod_btns.size():
		var btn := mod_btns[i] as Button
		var idx := i
		btn.pressed.connect(func(): _select_modifier(idx))
		if MODIFIERS[i] != "":
			var md := DataRegistry.get_modifier(MODIFIERS[i])
			if md:
				btn.tooltip_text = "[%s]  %s" % [md.trigger, md.description]

	# Wire relic toggle buttons + tooltips
	var relic_btns := _relic_grid.get_children()
	for i in relic_btns.size():
		var btn := relic_btns[i] as Button
		var relic_id := RELICS[i]
		btn.toggled.connect(func(on: bool): _toggle_relic(relic_id, on))
		var rd := DataRegistry.get_relic(relic_id)
		if rd:
			btn.tooltip_text = rd.description

	_reset_btn.pressed.connect(_reset)

	_game_board.get_node("MarginContainer/AIPanel").hide()
	_game_board.setup_match(_player_bag, 0, 0, 1, 1, "Sandbox", "No gimmick", false, _relic_manager)
	_game_board.match_complete.connect(_on_match_complete)

	_refresh_type_buttons()
	_refresh_mod_buttons()
	_refresh_next_label()


func _process(_delta: float) -> void:
	if _player_bag != null:
		var p: Piece = _player_bag.current()
		p.type = _selected_type
		p.modifier = _selected_modifier


func _select_type(idx: int) -> void:
	_selected_type = PIECE_TYPES[idx]
	_refresh_type_buttons()
	_refresh_next_label()


func _select_modifier(idx: int) -> void:
	_selected_modifier = MODIFIERS[idx]
	_refresh_mod_buttons()
	_refresh_next_label()



func _toggle_relic(relic_id: String, on: bool) -> void:
	if on:
		_relic_manager.add_relic(relic_id)
	else:
		_relic_manager = RelicManager.new()
		var relic_btns := _relic_grid.get_children()
		for i in relic_btns.size():
			if (relic_btns[i] as Button).button_pressed:
				_relic_manager.add_relic(RELICS[i])
		_game_board._relic_manager = _relic_manager
	_log("Relic %s: %s" % ["ON" if on else "OFF", relic_id])


func _reset() -> void:
	_game_board.match_complete.disconnect(_on_match_complete)
	_player_bag = PieceBag.new(Piece.Owner.PLAYER)

	_relic_manager = RelicManager.new()
	var relic_btns := _relic_grid.get_children()
	for i in relic_btns.size():
		if (relic_btns[i] as Button).button_pressed:
			_relic_manager.add_relic(RELICS[i])

	_game_board.setup_match(_player_bag, 0, 0, 1, 1, "Sandbox", "No gimmick", false, _relic_manager)
	_game_board.get_node("MarginContainer/AIPanel").hide()
	_game_board.match_complete.connect(_on_match_complete)
	_chip_label.text = "Chips: 0"
	_log("Board reset.")


func _on_match_complete(
	player_won: bool, player_score: int, ai_score: int,
	chips: int, _streak: int, _cascade: int, _cross: int
) -> void:
	_chip_label.text = "Chips: %d" % chips
	_log("Match ended: %s  P:%d vs AI:%d  Chips:%d" % [
		"WIN" if player_won else "LOSS", player_score, ai_score, chips
	])


func _refresh_type_buttons() -> void:
	var btns := _type_grid.get_children()
	for i in btns.size():
		(btns[i] as Button).modulate = Color(1.0, 0.85, 0.3) if PIECE_TYPES[i] == _selected_type else Color.WHITE


func _refresh_mod_buttons() -> void:
	var btns := _mod_grid.get_children()
	for i in btns.size():
		(btns[i] as Button).modulate = Color(1.0, 0.85, 0.3) if MODIFIERS[i] == _selected_modifier else Color.WHITE


func _refresh_next_label() -> void:
	_next_label.text = "%s  +  %s" % [_type_name(_selected_type), _mod_name(_selected_modifier)]


func _log(msg: String) -> void:
	_log_label.text = msg + "\n" + _log_label.text


func _type_name(t: Piece.Type) -> String:
	match t:
		Piece.Type.PRISM:  return "Prism"
		Piece.Type.COIN:   return "Coin"
		Piece.Type.EMBER:  return "Ember"
		Piece.Type.SHARD:  return "Shard"
	return "Normal"


func _mod_name(m: String) -> String:
	return m if m != "" else "(none)"
