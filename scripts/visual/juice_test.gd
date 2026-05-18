extends "res://scripts/visual/game_board.gd"

# Juice test harness — pre-seeds a 4-level cascade + cross-color chain.
# Drop into column 3 (the empty gap in the bottom row) to trigger.
# Press T to reset the board back to the seeded state.
#
# Cascade on drop in col 3:
#   Depth 0 — 7-wide horizontal player clear (500 pts)
#   Depth 1 — 4-wide horizontal player clear (×2 = 200 pts)
#   Depth 2 — 4-wide horizontal AI clear    (cross-color trigger)
#   Depth 3 — 4-tall vertical player clear  (×8 = 800 + 150 chain bonus)
#
# Board layout (row 0 = bottom):
#   Row 6: . . . P . . .
#   Row 5: . . . P . . .
#   Row 4: . . . P . . .
#   Row 3: . . . P . . .
#   Row 2: A A A A . . .
#   Row 1: . P P P P . .
#   Row 0: P P P [X] P P P   ← drop col 3 here


func _init_game() -> void:
	super._init_game()
	_seed_combo_board()


func _seed_combo_board() -> void:
	var p := Piece.Owner.PLAYER
	var a := Piece.Owner.AI

	# Row 0 — gap at col 3 is the drop target
	_board.set_cell(0, 0, Piece.new(p))
	_board.set_cell(1, 0, Piece.new(p))
	_board.set_cell(2, 0, Piece.new(p))
	_board.set_cell(4, 0, Piece.new(p))
	_board.set_cell(5, 0, Piece.new(p))
	_board.set_cell(6, 0, Piece.new(p))

	# Row 1
	_board.set_cell(1, 1, Piece.new(p))
	_board.set_cell(2, 1, Piece.new(p))
	_board.set_cell(3, 1, Piece.new(p))
	_board.set_cell(4, 1, Piece.new(p))

	# Row 2 — AI pieces that will form the cross-color clear
	_board.set_cell(0, 2, Piece.new(a))
	_board.set_cell(1, 2, Piece.new(a))
	_board.set_cell(2, 2, Piece.new(a))
	_board.set_cell(3, 2, Piece.new(a))

	# Rows 3-6 — vertical stack in col 3 for the final player clear
	for r: int in [3, 4, 5, 6]:
		_board.set_cell(3, r, Piece.new(p))

	_state = _build_state()
	_refresh_all()


func _update_labels() -> void:
	super._update_labels()
	_enemy_name_label.text = "JUICE TEST"
	_enemy_gimmick_label.text = "Drop col 3 (middle gap) — 4-level cascade + chain"


func _input(event: InputEvent) -> void:
	super._input(event)
	if event is InputEventKey:
		var key := event as InputEventKey
		if key.pressed and key.keycode == KEY_T and not _animating:
			_init_game()
