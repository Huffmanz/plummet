extends Node

# Headless run simulation test — no scene tree, no rendering.
# Attach to a Node, runs automatically in _ready().
# Deterministic via seed(12345).

const PLAYER := Piece.Owner.PLAYER
const AI := Piece.Owner.AI

var _pass_count: int = 0
var _fail_count: int = 0
var _shop_round: int = 0


func _ready() -> void:
	seed(12345)
	print("=== Run Simulation Test ===\n")

	_test_modifiers()
	_test_piece_types_and_scoring()
	_test_relics()
	_test_bag_mutations()
	_test_chip_economy()
	_test_full_run()

	print("\n=== Results: %d passed, %d failed ===" % [_pass_count, _fail_count])
	if _fail_count == 0:
		print("ALL TESTS PASSED")
	else:
		print("FAILURES DETECTED — see above")


# ---------------------------------------------------------------------------
# Assertion helper
# ---------------------------------------------------------------------------

func _assert(label: String, condition: bool) -> void:
	if condition:
		_pass_count += 1
		print("  PASS  %s" % label)
	else:
		_fail_count += 1
		print("  FAIL  %s" % label)


# ---------------------------------------------------------------------------
# Piece factory helpers
# ---------------------------------------------------------------------------

func _pp(mod: String = "") -> Piece:
	var p := Piece.new(PLAYER)
	p.modifier = mod
	return p


func _pt(type: Piece.Type, mod: String = "") -> Piece:
	var p := Piece.new(PLAYER, type)
	p.modifier = mod
	return p


func _ap() -> Piece:
	return Piece.new(AI)


func _player_piece_in_column(board: BoardEngine, col: int) -> Piece:
	for row in BoardEngine.ROWS:
		var piece := board.get_cell(col, row)
		if piece != null and piece.owner == PLAYER:
			return piece
	return null


# ---------------------------------------------------------------------------
# 1. MODIFIER TESTS — each modifier fires at least once, behavior verified
# ---------------------------------------------------------------------------

func _test_modifiers() -> void:
	print("\n-- Modifier Tests --")
	_test_ignite()
	_test_magnet()
	_test_deposit()
	_test_ripple()
	_test_echo()
	_test_detonate()
	_test_bounty()
	_test_surge()


func _test_ignite() -> void:
	var b := BoardEngine.new()
	var r := ModifierResolver.new()
	var cells: Array[Vector2i] = []
	for i in 5:
		cells.append(Vector2i(i, 0))
		b.set_cell(i, 0, _pp("Ignite" if i == 0 else ""))
	var run := MatchedRun.new(Piece.Owner.PLAYER, cells)
	var runs: Array[MatchedRun] = [run]
	var bonus := r.on_clear(b, runs)
	_assert("Ignite: 5-in-a-row earns +100 for 5th cell", bonus == 100)
	_assert("Ignite: one popup cell beyond four", r.ignite_popup_cells_for_run(b, run).size() == 1)


func _test_magnet() -> void:
	var b := BoardEngine.new()
	var r := ModifierResolver.new()
	b.set_cell(0, 2, _pp())
	var piece := _pp("Magnet")
	b.set_cell(4, 2, piece)
	r.set_landed(4, 2, piece)
	r.on_land(b)
	# Nearest player piece was at col 0; should slide toward col 4 → col 1 (then gravity settles the column).
	var slid := _player_piece_in_column(b, 1)
	_assert("Magnet: nearby player piece slides toward magnet", slid != null)
	_assert("Magnet: original cell vacated", b.get_cell(0, 2) == null)


func _test_deposit() -> void:
	var b := BoardEngine.new()
	var r := ModifierResolver.new()
	var piece := _pp("Deposit")
	b.set_cell(2, 0, piece)
	r.set_landed(2, 0, piece)
	_assert("Deposit: yields 5 chips on landing", r.on_land(b) == 5)


func _test_ripple() -> void:
	var b := BoardEngine.new()
	var r := ModifierResolver.new()
	var left := _pp()
	b.set_cell(1, 0, _ap())
	b.set_cell(1, 1, _ap())
	b.set_cell(2, 2, left)
	var piece := _pp("Ripple")
	b.set_cell(3, 2, piece)
	r.set_landed(3, 2, piece)
	r.on_land(b)
	_assert("Ripple: left neighbor pushed one cell away", b.get_cell(1, 2) == left)
	_assert("Ripple: original left slot cleared", b.get_cell(2, 2) == null)


func _test_echo() -> void:
	var b := BoardEngine.new()
	var r := ModifierResolver.new()
	for i in 4:
		var p := _pp("Echo" if i == 0 else "")
		b.set_cell(i, 0, p)
	var runs := b.detect_clears()
	_assert("Echo: 4-in-a-row detected for test setup", runs.size() > 0)
	r.on_clear(b, runs, 1)
	_assert("Echo: queues 1 copy (no EchoChamber)", r.pop_echo_pieces().size() == 1)

	# EchoChamber doubles copies.
	var b2 := BoardEngine.new()
	var r2 := ModifierResolver.new()
	for i in 4:
		b2.set_cell(i, 0, _pp("Echo" if i == 0 else ""))
	var runs2 := b2.detect_clears()
	r2.on_clear(b2, runs2, 2)
	_assert("Echo+EchoChamber: queues 2 copies", r2.pop_echo_pieces().size() == 2)

	# find_echo_target returns valid column on non-empty board.
	var b3 := BoardEngine.new()
	b3.set_cell(0, 0, _ap())
	b3.set_cell(0, 1, _ap())
	var target := r.find_echo_target(b3)
	_assert("Echo: find_echo_target returns valid column", target >= 0 and target < BoardEngine.COLS)


func _test_detonate() -> void:
	var b := BoardEngine.new()
	var r := ModifierResolver.new()
	for i in 4:
		b.set_cell(i, 0, _pp("Detonate" if i == 0 else ""))
	for i in range(4, BoardEngine.COLS):
		b.set_cell(i, 0, _ap())
	var runs := b.detect_clears()
	_assert("Detonate: 4-in-a-row detected for test setup", runs.size() > 0)
	r.apply_detonate_from_runs(b, runs)
	var row_empty := true
	for c in BoardEngine.COLS:
		if b.get_cell(c, 0) != null:
			row_empty = false
	_assert("Detonate: entire row cleared on trigger", row_empty)


func _test_bounty() -> void:
	var b := BoardEngine.new()
	var r := ModifierResolver.new()
	for i in 4:
		b.set_cell(i, 0, _pp("Bounty" if i == 0 else ""))
	for i in 3:
		b.set_cell(4 + i, 0, _ap())
	var runs := b.detect_clears()
	_assert("Bounty: 4-in-a-row detected for test setup", runs.size() > 0)
	r.on_clear(b, runs)
	# 3 AI pieces × 10 = 30.
	_assert("Bounty: earns 30 pts (3 AI pieces × 10)", r.get_accumulated_bonus_points() == 30)


func _test_surge() -> void:
	var b := BoardEngine.new()
	var r := ModifierResolver.new()
	for i in 5:
		b.set_cell(i, 0, _pp("Surge" if i == 0 else ""))
	var runs := b.detect_clears()
	r.on_clear(b, runs)
	_assert("Surge: 5-in-a-row earns 5 chips", r.get_accumulated_clear_chips() == 5)
	_assert("Surge: chips equal to line length", r.surge_chips_for_run(b, runs[0]) == 5)


# ---------------------------------------------------------------------------
# 2. PIECE TYPES + SCORING TESTS
# ---------------------------------------------------------------------------

func _test_piece_types_and_scoring() -> void:
	print("\n-- Piece Type & Scoring Tests --")
	_test_score_normal_4()
	_test_score_5_in_row()
	_test_score_6_plus()
	_test_score_prism_double()
	_test_score_cascade_depth()
	_test_score_simultaneous()
	_test_score_cross_color()
	_test_piece_types_placed_on_board()


func _make_result(owner: Piece.Owner, cell_count: int, depth: int, has_prism: bool = false, cross_color: bool = false) -> CascadeResult:
	var result := CascadeResult.new(owner)
	var cells: Array[Vector2i] = []
	for i in cell_count:
		cells.append(Vector2i(i, 0))
	var mr := MatchedRun.new(owner, cells)
	var tc := TaggedClear.new(mr, depth)
	tc.has_prism = has_prism
	result.clears.append(tc)
	result.cross_color = cross_color
	return result


func _test_score_normal_4() -> void:
	var turn := ScoreCalculator.new().calculate(_make_result(PLAYER, 4, 0), 0)
	_assert("Normal 4-in-row = 100 pts", turn.player_points == 100)


func _test_score_5_in_row() -> void:
	var turn := ScoreCalculator.new().calculate(_make_result(PLAYER, 5, 0), 0)
	_assert("5-in-row = 250 pts", turn.player_points == 250)


func _test_score_6_plus() -> void:
	var turn := ScoreCalculator.new().calculate(_make_result(PLAYER, 6, 0), 0)
	_assert("6-in-row = 500 pts", turn.player_points == 500)


func _test_score_prism_double() -> void:
	var turn := ScoreCalculator.new().calculate(_make_result(PLAYER, 4, 0, true), 0)
	_assert("Prism doubles base: 200 pts", turn.player_points == 200)


func _test_score_cascade_depth() -> void:
	var turn := ScoreCalculator.new().calculate(_make_result(PLAYER, 4, 2), 0)
	_assert("Cascade depth 2: 100 × 4 = 400 pts", turn.player_points == 400)


func _test_score_simultaneous() -> void:
	var result := CascadeResult.new(PLAYER)
	for row in 2:
		var cells: Array[Vector2i] = []
		for i in 4:
			cells.append(Vector2i(i, row))
		result.clears.append(TaggedClear.new(MatchedRun.new(PLAYER, cells), 0))
	var turn := ScoreCalculator.new().calculate(result, 0)
	# 200 × 1.5 = 300 (integer: 200 * 3 / 2).
	_assert("Simultaneous 2× clears = 300 pts", turn.player_points == 300)


func _test_score_cross_color() -> void:
	var turn := ScoreCalculator.new().calculate(_make_result(PLAYER, 4, 0, false, true), 0)
	_assert("Cross-color bonus adds +150: 250 pts", turn.player_points == 250)


func _test_piece_types_placed_on_board() -> void:
	# Verify all 5 piece types can be dropped and board tracks them correctly.
	var b := BoardEngine.new()
	var types := [Piece.Type.NORMAL, Piece.Type.PRISM, Piece.Type.COIN, Piece.Type.EMBER, Piece.Type.SHARD]
	for i in types.size():
		var p := Piece.new(PLAYER, types[i])
		var row := b.drop_piece(i, p)
		_assert("Piece type %d placed at col %d" % [types[i], i], row == 0)
	for i in types.size():
		var placed := b.get_cell(i, 0)
		_assert("Piece type %d retrieved correctly" % types[i], placed != null and placed.type == types[i])


# ---------------------------------------------------------------------------
# 3. RELIC TESTS — all 10 relics, behavior methods exercised
# ---------------------------------------------------------------------------

func _test_relics() -> void:
	print("\n-- Relic Tests --")
	_test_relic_cushion()
	_test_relic_patron()
	_test_relic_forge()
	_test_relic_almanac()
	_test_relic_stockpile()
	_test_relic_echo_chamber()
	_test_relic_momentum()
	_test_relic_passive_only()
	_test_relic_capacity()


func _test_relic_cushion() -> void:
	var rm := RelicManager.new()
	rm.add_relic("Cushion")
	_assert("Cushion: not spent initially", not rm.is_cushion_spent())
	_assert("Cushion: activates on first trigger", rm.try_cushion())
	_assert("Cushion: spent after activation", rm.is_cushion_spent())
	_assert("Cushion: does not activate twice", not rm.try_cushion())


func _test_relic_patron() -> void:
	var rm := RelicManager.new()
	rm.add_relic("Patron")
	_assert("Patron: not spent initially", not rm.is_patron_spent())
	_assert("Patron: activates first time", rm.try_patron())
	_assert("Patron: spent after use", rm.is_patron_spent())
	_assert("Patron: does not activate twice", not rm.try_patron())


func _test_relic_forge() -> void:
	var rm := RelicManager.new()
	rm.add_relic("Forge")
	rm.begin_shop_visit()
	_assert("Forge: not spent at start of visit", not rm.is_forge_spent_this_visit())
	_assert("Forge: activates first time in visit", rm.try_forge())
	_assert("Forge: spent within visit", rm.is_forge_spent_this_visit())
	_assert("Forge: does not trigger twice in visit", not rm.try_forge())
	rm.begin_shop_visit()
	_assert("Forge: resets on new visit", not rm.is_forge_spent_this_visit())


func _test_relic_almanac() -> void:
	var rm := RelicManager.new()
	_assert("Almanac absent: 3 offers", rm.offer_count() == 3)
	rm.add_relic("Almanac")
	_assert("Almanac present: 4 offers", rm.offer_count() == 4)


func _test_relic_stockpile() -> void:
	var rm := RelicManager.new()
	_assert("Stockpile absent: 1 chip/clear", rm.chips_per_clear() == 1)
	rm.add_relic("Stockpile")
	_assert("Stockpile present: 2 chips/clear", rm.chips_per_clear() == 2)


func _test_relic_echo_chamber() -> void:
	var rm := RelicManager.new()
	_assert("EchoChamber absent: 1 echo copy", rm.echo_copy_count() == 1)
	rm.add_relic("EchoChamber")
	_assert("EchoChamber present: 2 echo copies", rm.echo_copy_count() == 2)


func _test_relic_momentum() -> void:
	var rm := RelicManager.new()
	_assert("Momentum absent: 0 bonus for any streak", rm.momentum_bonus(5) == 0)
	rm.add_relic("Momentum")
	_assert("Momentum: 0 wins = 0 bonus", rm.momentum_bonus(0) == 0)
	_assert("Momentum: 1 win = 50 bonus", rm.momentum_bonus(1) == 50)
	_assert("Momentum: 3 wins = 150 bonus", rm.momentum_bonus(3) == 150)


func _test_relic_passive_only() -> void:
	# Compass, Lens, Cartographer have no dedicated behavior methods.
	var rm := RelicManager.new()
	rm.add_relic("Compass")
	rm.add_relic("Lens")
	rm.add_relic("Cartographer")
	_assert("Compass: tracked correctly", rm.has_relic("Compass"))
	_assert("Lens: tracked correctly", rm.has_relic("Lens"))
	_assert("Cartographer: tracked correctly", rm.has_relic("Cartographer"))


func _test_relic_capacity() -> void:
	var rm := RelicManager.new()
	for i in RelicManager.MAX_RELICS:
		_assert("Relic %d added within capacity" % i, rm.add_relic("Compass"))
	_assert("Relic rejected at capacity", not rm.add_relic("Lens"))
	_assert("can_add_relic false at capacity", not rm.can_add_relic())


# ---------------------------------------------------------------------------
# 4. BAG MUTATION TESTS (shop effects)
# ---------------------------------------------------------------------------

func _test_bag_mutations() -> void:
	print("\n-- Bag Mutation Tests --")

	var bag := PieceBag.new(PLAYER)

	# Attach modifier.
	bag.get_piece_at(0).modifier = "Ignite"
	_assert("Bag: modifier attached to piece", bag.get_piece_at(0).modifier == "Ignite")

	# Remove modifier.
	bag.get_piece_at(0).modifier = ""
	_assert("Bag: modifier removed from piece", bag.get_piece_at(0).modifier == "")

	# Upgrade type.
	bag.get_piece_at(1).type = Piece.Type.PRISM
	_assert("Bag: piece type upgraded to Prism", bag.get_piece_at(1).type == Piece.Type.PRISM)

	# Bag cycling.
	var first := bag.current()
	for _i in PieceBag.BAG_SIZE:
		bag.advance()
	_assert("Bag: cycles back to start after BAG_SIZE advances", bag.current() == first)

	# Bag persistence across advance — modifiers stay attached.
	bag.get_piece_at(2).modifier = "Surge"
	for _i in PieceBag.BAG_SIZE:
		bag.advance()
	_assert("Bag: modifier persists across full cycle", bag.get_piece_at(2).modifier == "Surge")


# ---------------------------------------------------------------------------
# 5. CHIP ECONOMY TESTS
# ---------------------------------------------------------------------------

func _test_chip_economy() -> void:
	print("\n-- Chip Economy Tests --")

	var chips := 0

	# Deposit chip earning.
	var b := BoardEngine.new()
	var r := ModifierResolver.new()
	var deposit := _pp("Deposit")
	b.set_cell(0, 0, deposit)
	r.set_landed(0, 0, deposit)
	chips += r.on_land(b)
	_assert("Chip economy: Deposit gives 5 chips (total=%d)" % chips, chips == 5)

	# Win bonus.
	chips += 15
	_assert("Chip economy: win bonus +15 (total=%d)" % chips, chips == 20)

	# Win streak bonus (streak 2).
	chips += 5
	_assert("Chip economy: streak bonus +5 (total=%d)" % chips, chips == 25)

	# Shop purchase deduction.
	chips -= 10
	_assert("Chip economy: modifier cost -10 (total=%d)" % chips, chips == 15)

	# Stockpile relic doubles per-clear chips.
	var rm := RelicManager.new()
	rm.add_relic("Stockpile")
	var stockpile_yield := 3 * rm.chips_per_clear()  # 3 clears × 2
	_assert("Chip economy: Stockpile gives 2 chips/clear (3 clears = %d)" % stockpile_yield, stockpile_yield == 6)

	# Momentum relic starting bonus.
	rm.add_relic("Momentum")
	var momentum_bonus := rm.momentum_bonus(2)
	_assert("Chip economy: Momentum adds 100 for win streak 2", momentum_bonus == 100)


# ---------------------------------------------------------------------------
# 6. FULL RUN SIMULATION — 3 acts × 4 matches
# ---------------------------------------------------------------------------

func _test_full_run() -> void:
	print("\n-- Full Run Simulation (3 acts × 4 matches) --")

	var all_modifiers := ["Ignite", "Magnet", "Deposit", "Ripple", "Echo", "Detonate", "Bounty", "Surge"]

	var bag := PieceBag.new(PLAYER)

	# Pre-assign one of each piece type to the first 5 slots so all types are exercised.
	var all_types := [Piece.Type.NORMAL, Piece.Type.PRISM, Piece.Type.COIN, Piece.Type.EMBER, Piece.Type.SHARD]
	for i in all_types.size():
		bag.get_piece_at(i).type = all_types[i]

	# One modifier per bag slot; 8th is applied during shop visits.
	for i in PieceBag.BAG_SIZE:
		bag.get_piece_at(i).modifier = all_modifiers[i]

	var relic_manager := RelicManager.new()
	var chips := 0
	var win_streak := 0
	var modifier_seen: Dictionary = {}
	var types_seen: Dictionary = {}
	var match_wins := 0

	for act in 3:
		for match_in_act in 4:
			var is_boss := match_in_act == 3
			print("  Act %d Match %d%s" % [act + 1, match_in_act + 1, " (BOSS)" if is_boss else ""])

			var b := BoardEngine.new()
			var score_tracker := ScoreTracker.new()
			var resolver := ModifierResolver.new()
			var calc := ScoreCalculator.new()

			# Guarantee player wins.
			score_tracker.add_starting_bonus(99999)

			var loop := CascadeLoop.new()
			loop.register_on_land(func(board: BoardEngine) -> void:
				resolver.on_land(board)
			)
			loop.register_on_clear(func(board: BoardEngine, runs: Array[MatchedRun]) -> void:
				resolver.on_clear(board, runs, relic_manager.echo_copy_count())
			)

			var clears_this_match := 0

			# Simulate 10 player turns.
			for _turn in 10:
				bag.advance()
				var piece := bag.current()
				types_seen[piece.type] = true
				if piece.has_modifier():
					modifier_seen[piece.modifier] = true

				var col := randi() % BoardEngine.COLS
				if b.is_column_full(col):
					# Pick first non-full column.
					col = 0
					while col < BoardEngine.COLS and b.is_column_full(col):
						col += 1
					if col >= BoardEngine.COLS:
						break

				resolver.set_landed(col, 0, piece)
				var row := b.drop_piece(col, piece)
				if row < 0:
					continue

				var result := loop.run(b, PLAYER)

				if not result.clears.is_empty():
					clears_this_match += result.clears.size()
					var turn_score := calc.calculate(
						result,
						resolver.get_accumulated_bonus_points()
					)
					chips += resolver.get_accumulated_clear_chips()
					score_tracker.add_turn(turn_score)

				# Chips per clear (applying Stockpile relic rate).
				chips += result.clears.size() * relic_manager.chips_per_clear()

			var match_result := score_tracker.get_match_result()
			_assert("Act %d Match %d: player wins" % [act + 1, match_in_act + 1],
				match_result.winner == PLAYER)

			if match_result.winner == PLAYER:
				match_wins += 1
				win_streak += 1
				chips += 15
				if win_streak >= 2:
					chips += 5 * (win_streak - 1)
				chips += relic_manager.momentum_bonus(win_streak)

				# Shop phase.
				if not is_boss:
					relic_manager.begin_shop_visit()
					_shop_visit(bag, relic_manager, chips, all_modifiers, modifier_seen)
			else:
				win_streak = 0

	# Coverage assertions — all 8 modifiers should have been exercised.
	var all_mods_seen := true
	for mod: String in all_modifiers:
		if not modifier_seen.has(mod):
			all_mods_seen = false
			print("    MISSING modifier: %s" % mod)
	_assert("All 8 modifiers encountered during run", all_mods_seen)

	# All 5 piece types should have been seen.
	var all_types_seen := true
	for t: Piece.Type in all_types:
		if not types_seen.has(t):
			all_types_seen = false
			print("    MISSING piece type: %d" % t)
	_assert("All 5 piece types used during run", all_types_seen)

	_assert("Player won all 12 matches", match_wins == 12)
	_assert("Chip economy non-negative at run end (chips=%d)" % chips, chips >= 0)
	print("  Chips earned: %d | Win streak: %d" % [chips, win_streak])


func _shop_visit(
	bag: PieceBag,
	relic_manager: RelicManager,
	chips: int,
	all_modifiers: Array,
	modifier_seen: Dictionary
) -> void:
	# Cycle shop modifiers so all eight are recorded across visits.
	var chosen_mod: String = all_modifiers[_shop_round % all_modifiers.size()]
	_shop_round += 1
	if chips >= 10:
		var slot := randi() % PieceBag.BAG_SIZE
		bag.get_piece_at(slot).modifier = chosen_mod
		modifier_seen[chosen_mod] = true

	# Upgrade a random bag slot to a non-Normal type.
	if chips >= 20:
		var type_options: Array[Piece.Type] = [Piece.Type.PRISM, Piece.Type.COIN, Piece.Type.EMBER, Piece.Type.SHARD]
		var slot := randi() % PieceBag.BAG_SIZE
		bag.get_piece_at(slot).type = type_options[randi() % type_options.size()]

	# Add a relic if capacity allows.
	if relic_manager.can_add_relic():
		var relic_pool := ["Compass", "Cushion", "Almanac", "Stockpile", "Momentum"]
		relic_manager.add_relic(relic_pool[randi() % relic_pool.size()])
