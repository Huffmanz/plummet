class_name ShopScreen extends Control

signal shop_closed(chips_remaining: int)

const COST_ATTACH: int = 10
const COST_REMOVE: int = 5
const COST_UPGRADE: int = 20
const COST_RELIC: int = 25
const COST_REROLL: int = 5

const COST_PIECE_TYPE: int = 20

const WEIGHT_MODIFIER: int = 10
const WEIGHT_PIECE_TYPE: int = 7
const WEIGHT_RELIC_COMMON: int = 5
const WEIGHT_RELIC_UNCOMMON: int = 2
const WEIGHT_RELIC_RARE: int = 1

@onready var _chip_label: Label = %ChipLabel
const _JUICY_BUTTON_SCENE := preload("res://scenes/ui/juicy_sfx_button.tscn")

@onready var _continue_btn: JuicySfxButton = %ContinueBtn
@onready var _reroll_btn: JuicySfxButton = %RerollBtn
@onready var _upgrade_popover: PanelContainer = %UpgradePopover
@onready var _popover_title: Label = %PopoverTitle
@onready var _popover_options: VBoxContainer = %PopoverOptions

var _offer_cards: Array[ShopOfferCard] = []
var _piece_slots: Array[ShopPieceSlot] = []
var _relic_slots: Array[ShopRelicSlot] = []

var _bag: PieceBag = null
var _relic_manager: RelicManager = null
var _chips: int = 0
var _offers: Array[Dictionary] = []
var _offer_count: int = 3
var _offer_used: Array[bool] = []
var _rerolled: bool = false
var _popover_piece_idx: int = -1

var _drag_offer_idx: int = -1
var _offer_dragging: bool = false


func _ready() -> void:
	add_to_group("shop_cursor_owner")
	z_index = 10
	_collect_nodes()
	_style_ui()
	_wire_signals()
	hide()
	if get_parent() == get_tree().root:
		open(_make_preview_bag(), 30, null)


func _collect_nodes() -> void:
	_offer_cards = [
		%Offer0 as ShopOfferCard,
		%Offer1 as ShopOfferCard,
		%Offer2 as ShopOfferCard,
		%Offer3 as ShopOfferCard,
	]
	_piece_slots = [
		%Piece0 as ShopPieceSlot, %Piece1 as ShopPieceSlot, %Piece2 as ShopPieceSlot,
		%Piece3 as ShopPieceSlot, %Piece4 as ShopPieceSlot, %Piece5 as ShopPieceSlot,
		%Piece6 as ShopPieceSlot,
	]
	_relic_slots = [
		%Relic0 as ShopRelicSlot, %Relic1 as ShopRelicSlot,
		%Relic2 as ShopRelicSlot, %Relic3 as ShopRelicSlot,
	]


func _style_ui() -> void:
	_chip_label.add_theme_color_override("font_color", UITheme.ACCENT)
	for section_title in [
		$Root/Body/OffersSection/OffersVBox/OffersHeader/OffersTitle,
		$Root/Body/BagSection/BagVBox/BagTitle,
		$Root/Body/RelicsSection/RelicsVBox/RelicsTitle,
	]:
		#UITheme.style_label_muted(section_title as Label)
		pass
	_continue_btn.normal_bg_color = UITheme.ACCENT
	_continue_btn.hover_bg_color = UITheme.ACCENT_HOVER
	_upgrade_popover.add_theme_stylebox_override("panel", UITheme.make_surface_style())
	UITheme.style_label_primary(_popover_title, true)
	var offers_hint: Label = $Root/Body/OffersSection/OffersVBox/OffersHint
	if offers_hint:
		UITheme.style_label_muted(offers_hint)


func _wire_signals() -> void:
	_continue_btn.pressed.connect(_on_continue)
	_reroll_btn.pressed.connect(_on_reroll)
	for card in _offer_cards:
		card.drag_started.connect(_on_offer_drag_started)
		card.drag_ended.connect(_on_offer_drag_ended)
	for slot in _piece_slots:
		slot.remove_pressed.connect(_on_remove_modifier)
		slot.slot_clicked.connect(_on_piece_clicked)
		slot.offer_dropped.connect(_on_piece_offer_dropped)
	for slot in _relic_slots:
		slot.relic_dropped.connect(_on_relic_dropped)


func _make_preview_bag() -> PieceBag:
	var bag := PieceBag.new(Piece.Owner.PLAYER)
	bag.get_piece_at(0).modifier = "Echo"
	bag.get_piece_at(1).type = Piece.Type.PRISM
	bag.get_piece_at(1).modifier = "Surge"
	bag.get_piece_at(2).type = Piece.Type.COIN
	bag.get_piece_at(3).type = Piece.Type.EMBER
	return bag


func open(bag: PieceBag, chips: int, relic_mgr: RelicManager) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bag = bag
	_chips = chips
	_relic_manager = relic_mgr if relic_mgr != null else RelicManager.new()
	_relic_manager.begin_shop_visit()
	_offer_count = _relic_manager.offer_count()
	_offers = _roll_offers()
	_offer_used.resize(_offers.size())
	_offer_used.fill(false)
	_rerolled = false
	_hide_popover()
	_offer_dragging = false
	show()
	_refresh()
	_update_shop_cursor()


func _roll_offers() -> Array[Dictionary]:
	var pool := _build_offer_pool()
	var count := mini(_offer_count, pool.size())
	var result: Array[Dictionary] = []
	for _i in count:
		var pick := _weighted_pick(pool)
		if pick.is_empty():
			break
		result.append(pick)
		pool.erase(pick)
	return result


func _build_offer_pool() -> Array[Dictionary]:
	var pool: Array[Dictionary] = []
	for m in DataRegistry.get_all_modifiers():
		var md := m as ModifierData
		if md == null:
			continue
		pool.append({"kind": "modifier", "id": md.id, "weight": WEIGHT_MODIFIER})
	for pt in DataRegistry.get_all_piece_types():
		var td := pt as PieceTypeData
		if td == null or td.id == "NORMAL":
			continue
		pool.append({"kind": "piece_type", "id": td.id, "weight": WEIGHT_PIECE_TYPE})
	for r in DataRegistry.get_all_relics():
		var rd := r as RelicData
		if rd == null:
			continue
		if rd.source != "shop" and rd.source != "both":
			continue
		if _relic_manager.has_relic(rd.id):
			continue
		var w := WEIGHT_RELIC_COMMON
		match rd.rarity:
			"uncommon": w = WEIGHT_RELIC_UNCOMMON
			"rare": w = WEIGHT_RELIC_RARE
		pool.append({"kind": "relic", "id": rd.id, "weight": w})
	return pool


func _weighted_pick(pool: Array[Dictionary]) -> Dictionary:
	if pool.is_empty():
		return {}
	var total := 0
	for entry in pool:
		total += int(entry.get("weight", 1))
	var roll := randi_range(1, total)
	var acc := 0
	for entry in pool:
		acc += int(entry.get("weight", 1))
		if roll <= acc:
			return entry
	return pool[0]


func _refresh() -> void:
	_chip_label.text = "%d chips" % _chips
	_reroll_btn.disabled = _rerolled or _chips < COST_REROLL
	_reroll_btn.button_text = "Rerolled" if _rerolled else "Reroll (%d)" % COST_REROLL
	_refresh_offers()
	_refresh_bag()
	_refresh_relics()


func _refresh_offers() -> void:
	for i in _offer_cards.size():
		var card := _offer_cards[i]
		if i >= _offer_count or i >= _offers.size():
			card.visible = false
			continue
		card.visible = true
		var offer := _offers[i]
		var used := i < _offer_used.size() and _offer_used[i]
		var kind: String = offer.get("kind", "")
		var id: String = offer.get("id", "")
		var cost := _offer_cost(kind)
		var title := id
		var type_lbl := ""
		var desc := ""
		var hint := "drag onto any piece"
		var icon_color := UITheme.ACCENT
		var icon_texture: Texture2D = null
		var is_relic := kind == "relic"
		match kind:
			"modifier":
				var md: ModifierData = DataRegistry.get_modifier(id)
				if md:
					title = md.display_name
					type_lbl = ShopOfferCard.format_modifier_type(md.trigger)
					desc = md.description
					icon_color = md.badge_color
					icon_texture = md.icon
			"piece_type":
				var td: PieceTypeData = DataRegistry.get_piece_type(id)
				if td:
					title = td.display_name
					type_lbl = ShopOfferCard.format_piece_type()
					desc = td.description
					icon_color = UITheme.PLAYER
					icon_texture = td.icon
				cost = COST_PIECE_TYPE
			"relic":
				var rd: RelicData = DataRegistry.get_relic(id)
				if rd:
					title = rd.display_name
					type_lbl = ShopOfferCard.format_relic_type()
					desc = rd.description
					icon_color = ShopOfferCard.RELIC_BORDER
					icon_texture = rd.icon
				hint = "drag to relic row"
				cost = _relic_purchase_cost()
		card.setup(i, kind, id, cost, title, type_lbl, desc, hint, icon_color, is_relic, icon_texture)
		card.set_consumed(used)
		var can_use := not used and _chips >= cost
		if not used and kind == "modifier" and _count_empty_mod_slots() == 0:
			can_use = false
		if not used and kind == "relic" and not _relic_manager.can_add_relic():
			can_use = false
		card.set_affordable(can_use)


func _refresh_bag() -> void:
	if _bag == null:
		return
	for i in _piece_slots.size():
		var slot := _piece_slots[i]
		var piece := _bag.get_piece_at(i)
		slot.setup(i, piece)
		slot.set_remove_enabled(_chips >= COST_REMOVE and not piece.modifier.is_empty())
		slot.set_drop_highlight(false)


func _refresh_relics() -> void:
	var relics: Array[String] = []
	if _relic_manager != null:
		relics = _relic_manager.get_active_relics()
	for i in _relic_slots.size():
		var id := relics[i] if i < relics.size() else ""
		_relic_slots[i].setup(i, id)
		_relic_slots[i].set_drop_highlight(false)


func _offer_cost(kind: String) -> int:
	match kind:
		"relic":
			return _relic_purchase_cost()
		"piece_type":
			return COST_PIECE_TYPE
		_:
			return COST_ATTACH


func _relic_purchase_cost() -> int:
	if _relic_manager.has_relic("Patron") and not _relic_manager.is_patron_spent():
		return 0
	return COST_RELIC


func _count_empty_mod_slots() -> int:
	var n := 0
	for i in PieceBag.BAG_SIZE:
		if _bag.get_piece_at(i).modifier.is_empty():
			n += 1
	return n


func _process(_delta: float) -> void:
	if visible:
		_update_shop_cursor()


func _update_shop_cursor() -> void:
	if _is_any_offer_dragging():
		GameCursor.apply_closed()
		return
	var hovered := _get_hovered_offer_card()
	if hovered != null and hovered.is_offer_hover_target():
		GameCursor.apply_open()
		return
	GameCursor.apply_default()


func _is_any_offer_dragging() -> bool:
	for card in _offer_cards:
		if card.is_dragging():
			return true
	return false


func _get_hovered_offer_card() -> ShopOfferCard:
	var node: Node = get_viewport().gui_get_hovered_control()
	while node != null:
		if node is ShopOfferCard:
			return node as ShopOfferCard
		node = node.get_parent()
	return null


func _on_offer_drag_started(offer_idx: int) -> void:
	_offer_dragging = true
	_drag_offer_idx = offer_idx
	_update_shop_cursor()
	if offer_idx >= _offers.size():
		return
	var kind: String = _offers[offer_idx].get("kind", "")
	if kind == "modifier":
		for slot in _piece_slots:
			var piece := _bag.get_piece_at(slot.piece_index)
			slot.set_drop_highlight(piece.modifier.is_empty())
	elif kind == "piece_type":
		for slot in _piece_slots:
			slot.set_drop_highlight(true)
	elif kind == "relic" and _relic_manager.can_add_relic():
		for slot in _relic_slots:
			slot.set_drop_highlight(not slot.is_occupied())


func _on_offer_drag_ended() -> void:
	_offer_dragging = false
	_drag_offer_idx = -1
	_update_shop_cursor()
	for slot in _piece_slots:
		slot.set_drop_highlight(false)
	for slot in _relic_slots:
		slot.set_drop_highlight(false)


func _on_piece_offer_dropped(piece_idx: int, data: Dictionary) -> void:
	var offer_idx: int = data.get("index", -1)
	if offer_idx < 0 or offer_idx >= _offers.size():
		return
	if _offer_used[offer_idx]:
		return
	var offer := _offers[offer_idx]
	var kind: String = offer.get("kind", "")
	if kind == "modifier":
		_apply_modifier_offer(offer_idx, piece_idx, offer)
	elif kind == "piece_type":
		_apply_piece_type_offer(offer_idx, piece_idx, offer)


func _apply_modifier_offer(offer_idx: int, piece_idx: int, offer: Dictionary) -> void:
	if _chips < COST_ATTACH:
		return
	var piece := _bag.get_piece_at(piece_idx)
	if not piece.modifier.is_empty():
		return
	_chips -= COST_ATTACH
	piece.modifier = offer.get("id", "")
	_offer_used[offer_idx] = true
	_refresh()


func _apply_piece_type_offer(offer_idx: int, piece_idx: int, offer: Dictionary) -> void:
	if _chips < COST_PIECE_TYPE:
		return
	var type_id: String = offer.get("id", "")
	if type_id.is_empty() or type_id == "NORMAL":
		return
	var piece := _bag.get_piece_at(piece_idx)
	_chips -= COST_PIECE_TYPE
	piece.type = _piece_type_from_id(type_id)
	_offer_used[offer_idx] = true
	_refresh()


func _on_relic_dropped(slot_idx: int, data: Dictionary) -> void:
	var offer_idx: int = data.get("index", -1)
	if offer_idx < 0 or offer_idx >= _offers.size():
		return
	if _offer_used[offer_idx]:
		return
	var offer := _offers[offer_idx]
	if offer.get("kind", "") != "relic":
		return
	if not _relic_manager.can_add_relic():
		return
	if slot_idx < 0 or slot_idx >= _relic_slots.size():
		return
	var slot := _relic_slots[slot_idx]
	if not slot.can_accept_relic_drop():
		return
	var cost := _relic_purchase_cost()
	if _chips < cost:
		return
	if cost == 0:
		if not _relic_manager.try_patron():
			return
	else:
		_chips -= cost
	if not _relic_manager.add_relic(offer.get("id", "")):
		return
	_offer_used[offer_idx] = true
	_refresh()


func _on_remove_modifier(piece_idx: int) -> void:
	if _chips < COST_REMOVE:
		return
	var piece := _bag.get_piece_at(piece_idx)
	if piece.modifier.is_empty():
		return
	_chips -= COST_REMOVE
	piece.modifier = ""
	_refresh()


func _on_piece_clicked(piece_idx: int) -> void:
	var piece := _bag.get_piece_at(piece_idx)
	_popover_piece_idx = piece_idx
	_clear_popover_options()
	if piece.type == Piece.Type.NORMAL:
		_popover_title.text = "Upgrade piece"
		var forge_free := _relic_manager != null and _relic_manager.has_relic("Forge") \
			and not _relic_manager.is_forge_spent_this_visit()
		for t in [Piece.Type.PRISM, Piece.Type.COIN, Piece.Type.EMBER, Piece.Type.SHARD]:
			var btn: JuicySfxButton = _JUICY_BUTTON_SCENE.instantiate()
			btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			btn.custom_minimum_size = Vector2(0, 32)
			btn.normal_bg_color = UITheme.SURFACE_LIGHT
			btn.hover_bg_color = UITheme.SURFACE
			var data: PieceTypeData = _piece_type_data(t)
			var type_name := data.display_name if data else "?"
			btn.button_text = "%s (FREE)" % type_name if forge_free else "%s (%d)" % [type_name, COST_UPGRADE]
			btn.disabled = (not forge_free) and _chips < COST_UPGRADE
			var chosen_type: Piece.Type = t
			btn.pressed.connect(func(): _apply_upgrade(piece_idx, chosen_type))
			_popover_options.add_child(btn)
	else:
		_popover_title.text = _piece_type_name(piece.type)
		var info := Label.new()
		var data: PieceTypeData = _piece_type_data(piece.type)
		info.text = data.description if data else ""
		info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UITheme.style_label_primary(info, true)
		_popover_options.add_child(info)
	_position_popover(_piece_slots[piece_idx])
	_upgrade_popover.visible = true


func _apply_upgrade(piece_idx: int, new_type: Piece.Type) -> void:
	var piece := _bag.get_piece_at(piece_idx)
	if piece.type != Piece.Type.NORMAL:
		_hide_popover()
		return
	var forge_free := _relic_manager != null and _relic_manager.has_relic("Forge") \
		and not _relic_manager.is_forge_spent_this_visit()
	if not forge_free and _chips < COST_UPGRADE:
		return
	if forge_free:
		_relic_manager.try_forge()
	else:
		_chips -= COST_UPGRADE
	piece.type = new_type
	_hide_popover()
	_refresh()


func _on_reroll() -> void:
	if _rerolled or _chips < COST_REROLL:
		return
	_chips -= COST_REROLL
	_offers = _roll_offers()
	_offer_used.resize(_offers.size())
	_offer_used.fill(false)
	_rerolled = true
	_refresh()


func _on_continue() -> void:
	_hide_popover()
	_offer_dragging = false
	GameCursor.apply_default()
	hide()
	shop_closed.emit(_chips)


func _hide_popover() -> void:
	_upgrade_popover.visible = false
	_popover_piece_idx = -1
	_clear_popover_options()


func _clear_popover_options() -> void:
	for child in _popover_options.get_children():
		child.queue_free()


func _position_popover(slot: ShopPieceSlot) -> void:
	var rect := slot.get_global_rect()
	_upgrade_popover.global_position = Vector2(
		rect.position.x,
		rect.position.y - _upgrade_popover.size.y - 8.0
	)


func _piece_type_from_id(id: String) -> Piece.Type:
	match id:
		"PRISM": return Piece.Type.PRISM
		"COIN": return Piece.Type.COIN
		"EMBER": return Piece.Type.EMBER
		"SHARD": return Piece.Type.SHARD
		_: return Piece.Type.NORMAL


func _piece_type_data(t: Piece.Type) -> PieceTypeData:
	match t:
		Piece.Type.NORMAL: return DataRegistry.get_piece_type("NORMAL")
		Piece.Type.PRISM:  return DataRegistry.get_piece_type("PRISM")
		Piece.Type.COIN:   return DataRegistry.get_piece_type("COIN")
		Piece.Type.EMBER:  return DataRegistry.get_piece_type("EMBER")
		Piece.Type.SHARD:  return DataRegistry.get_piece_type("SHARD")
	return null


func _piece_type_name(t: Piece.Type) -> String:
	var data := _piece_type_data(t)
	return data.display_name if data else "?"
