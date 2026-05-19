class_name ShopScreen extends Control

signal shop_closed(chips_remaining: int)

const MODIFIER_POOL: Array[String] = ["Echo", "Magnet", "Heavy", "Anchor", "Catalyst", "Volatile"]
const COST_ATTACH: int = 10
const COST_REMOVE: int = 5
const COST_UPGRADE: int = 20
const COST_REROLL: int = 5

enum Phase { IDLE, ATTACH_PICK_PIECE, REMOVE_PICK_MOD, UPGRADE_PICK_TYPE }

var _bag: PieceBag = null
var _chips: int = 0
var _offers: Array[String] = []
var _offer_used: Array[bool] = [false, false, false]
var _rerolled: bool = false
var _phase: Phase = Phase.IDLE
var _selected_offer: int = -1
var _selected_piece_idx: int = -1

var _chip_label: Label = null
var _phase_label: Label = null
var _offer_btns: Array[Button] = []
var _reroll_btn: Button = null
var _pieces_vbox: VBoxContainer = null
var _cancel_btn: Button = null
var _done_btn: Button = null


func _ready() -> void:
	_build_ui()
	hide()
	if get_parent() == get_tree().root:
		open(_make_preview_bag(), 30)


func _make_preview_bag() -> PieceBag:
	var bag := PieceBag.new(Piece.Owner.PLAYER)
	bag.get_piece_at(0).modifiers.append_array(["Echo", "Magnet"])
	bag.get_piece_at(1).type = Piece.Type.WEIGHTED
	bag.get_piece_at(1).modifiers.append("Heavy")
	bag.get_piece_at(2).type = Piece.Type.GHOST
	bag.get_piece_at(3).modifiers.append_array(["Anchor", "Catalyst", "Volatile"])
	return bag


func open(bag: PieceBag, chips: int) -> void:
	_bag = bag
	_chips = chips
	_offers = _roll_offers()
	_offer_used = [false, false, false]
	_rerolled = false
	_phase = Phase.IDLE
	_selected_offer = -1
	_selected_piece_idx = -1
	show()
	_refresh()


func _roll_offers() -> Array[String]:
	var pool: Array[String] = MODIFIER_POOL.duplicate()
	pool.shuffle()
	return [pool[0], pool[1], pool[2]]


func _build_ui() -> void:
	z_index = 10
	mouse_filter = Control.MOUSE_FILTER_STOP

	var bg := preload("res://scenes/ui/cozy_stripe_background.tscn").instantiate()
	add_child(bg)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.grow_horizontal = Control.GROW_DIRECTION_BOTH
	scroll.grow_vertical = Control.GROW_DIRECTION_BOTH
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(margin)

	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 12)
	root_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(root_vbox)

	# Title row
	var title_row := HBoxContainer.new()
	root_vbox.add_child(title_row)

	var title_lbl := Label.new()
	title_lbl.text = "SHOP"
	title_lbl.add_theme_font_size_override("font_size", 22)
	title_lbl.add_theme_color_override("font_color", UITheme.TEXT_ON_CANVAS)
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title_lbl)

	_chip_label = Label.new()
	_chip_label.text = "Chips: 0"
	_chip_label.add_theme_font_size_override("font_size", 16)
	_chip_label.add_theme_color_override("font_color", UITheme.ACCENT)
	_chip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	title_row.add_child(_chip_label)

	_phase_label = Label.new()
	_phase_label.text = ""
	_phase_label.add_theme_color_override("font_color", UITheme.TEXT_ON_CANVAS)
	_phase_label.add_theme_font_size_override("font_size", 13)
	root_vbox.add_child(_phase_label)

	_cancel_btn = Button.new()
	_cancel_btn.text = "← Cancel"
	_cancel_btn.visible = false
	UITheme.style_button(_cancel_btn, UITheme.SURFACE_LIGHT, UITheme.SURFACE)
	_cancel_btn.pressed.connect(_on_cancel)
	root_vbox.add_child(_cancel_btn)

	var offers_panel := PanelContainer.new()
	offers_panel.add_theme_stylebox_override("panel", UITheme.make_surface_style())
	root_vbox.add_child(offers_panel)

	var offers_margin := MarginContainer.new()
	offers_margin.add_theme_constant_override("margin_left", 8)
	offers_margin.add_theme_constant_override("margin_right", 8)
	offers_margin.add_theme_constant_override("margin_top", 8)
	offers_margin.add_theme_constant_override("margin_bottom", 8)
	offers_panel.add_child(offers_margin)

	var offers_vbox := VBoxContainer.new()
	offers_vbox.add_theme_constant_override("separation", 6)
	offers_margin.add_child(offers_vbox)

	var offers_title := Label.new()
	offers_title.text = "MODIFIER OFFERS  (10 chips each)"
	offers_title.add_theme_font_size_override("font_size", 11)
	offers_title.add_theme_color_override("font_color", UITheme.TEXT_MUTED_ON_SURFACE)
	offers_vbox.add_child(offers_title)

	var offers_row := HBoxContainer.new()
	offers_row.add_theme_constant_override("separation", 6)
	offers_vbox.add_child(offers_row)

	_offer_btns.clear()
	for i in 3:
		var btn := Button.new()
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var idx := i
		btn.pressed.connect(func(): _on_offer_clicked(idx))
		offers_row.add_child(btn)
		_offer_btns.append(btn)

	_reroll_btn = Button.new()
	_reroll_btn.text = "Reroll (5)"
	UITheme.style_button(_reroll_btn, UITheme.SURFACE_LIGHT, UITheme.SURFACE)
	_reroll_btn.pressed.connect(_on_reroll)
	offers_row.add_child(_reroll_btn)

	var bag_panel := PanelContainer.new()
	bag_panel.add_theme_stylebox_override("panel", UITheme.make_surface_style())
	root_vbox.add_child(bag_panel)

	var bag_margin := MarginContainer.new()
	bag_margin.add_theme_constant_override("margin_left", 8)
	bag_margin.add_theme_constant_override("margin_right", 8)
	bag_margin.add_theme_constant_override("margin_top", 8)
	bag_margin.add_theme_constant_override("margin_bottom", 8)
	bag_panel.add_child(bag_margin)

	var bag_vbox := VBoxContainer.new()
	bag_vbox.add_theme_constant_override("separation", 6)
	bag_margin.add_child(bag_vbox)

	var bag_title := Label.new()
	bag_title.text = "YOUR BAG"
	bag_title.add_theme_font_size_override("font_size", 11)
	bag_title.add_theme_color_override("font_color", UITheme.TEXT_MUTED_ON_SURFACE)
	bag_vbox.add_child(bag_title)

	_pieces_vbox = VBoxContainer.new()
	_pieces_vbox.add_theme_constant_override("separation", 4)
	_pieces_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bag_vbox.add_child(_pieces_vbox)

	# Bottom row
	var bottom_row := HBoxContainer.new()
	root_vbox.add_child(bottom_row)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_row.add_child(spacer)

	_done_btn = Button.new()
	_done_btn.text = "Done →"
	_done_btn.add_theme_font_size_override("font_size", 16)
	UITheme.style_button(_done_btn)
	_done_btn.pressed.connect(_on_done)
	bottom_row.add_child(_done_btn)


func _refresh() -> void:
	if _chip_label == null:
		return

	_chip_label.text = "Chips: %d" % _chips

	match _phase:
		Phase.IDLE:
			_phase_label.text = "Select an action below"
			_cancel_btn.visible = false
		Phase.ATTACH_PICK_PIECE:
			_phase_label.text = "Select a piece to attach  %s  to" % _offers[_selected_offer]
			_cancel_btn.visible = true
		Phase.REMOVE_PICK_MOD:
			_phase_label.text = "Select a modifier to remove from piece %d" % (_selected_piece_idx + 1)
			_cancel_btn.visible = true
		Phase.UPGRADE_PICK_TYPE:
			_phase_label.text = "Select upgrade type for piece %d" % (_selected_piece_idx + 1)
			_cancel_btn.visible = true

	for i in 3:
		var btn: Button = _offer_btns[i]
		var used: bool = _offer_used[i]
		btn.text = "—" if used else _offers[i]
		btn.disabled = used or _chips < COST_ATTACH or _phase != Phase.IDLE
		btn.modulate = UITheme.ACCENT_POP \
			if (_phase == Phase.ATTACH_PICK_PIECE and _selected_offer == i) \
			else Color.WHITE
		if not btn.has_theme_stylebox_override("normal"):
			UITheme.style_button(btn, UITheme.SURFACE_LIGHT, UITheme.SURFACE)

	_reroll_btn.disabled = _rerolled or _chips < COST_REROLL or _phase != Phase.IDLE
	_reroll_btn.text = "Rerolled" if _rerolled else "Reroll (5)"

	_rebuild_piece_rows()

	_done_btn.disabled = _phase != Phase.IDLE


func _rebuild_piece_rows() -> void:
	var kids := _pieces_vbox.get_children()
	for child in kids:
		_pieces_vbox.remove_child(child)
		child.queue_free()
	if _bag == null:
		return
	for i in PieceBag.BAG_SIZE:
		_pieces_vbox.add_child(_build_piece_row(i, _bag.get_piece_at(i)))


func _build_piece_row(idx: int, piece: Piece) -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UITheme.make_surface_style(8, UITheme.SURFACE_LIGHT))
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var inner := MarginContainer.new()
	inner.add_theme_constant_override("margin_left", 6)
	inner.add_theme_constant_override("margin_right", 6)
	inner.add_theme_constant_override("margin_top", 4)
	inner.add_theme_constant_override("margin_bottom", 4)
	panel.add_child(inner)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.add_child(hbox)

	var type_lbl := Label.new()
	type_lbl.text = "%d. %s" % [idx + 1, _type_name(piece.type)]
	type_lbl.custom_minimum_size = Vector2(115, 0)
	type_lbl.add_theme_font_size_override("font_size", 12)
	type_lbl.add_theme_color_override("font_color", UITheme.TEXT_ON_SURFACE)
	hbox.add_child(type_lbl)

	var mods_lbl := Label.new()
	if piece.modifiers.is_empty():
		mods_lbl.text = "(none)"
		mods_lbl.add_theme_color_override("font_color", UITheme.TEXT_MUTED_ON_SURFACE)
	else:
		mods_lbl.text = " · ".join(PackedStringArray(piece.modifiers))
		mods_lbl.add_theme_color_override("font_color", UITheme.TEXT_ON_SURFACE)
	mods_lbl.add_theme_font_size_override("font_size", 11)
	mods_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(mods_lbl)

	match _phase:
		Phase.IDLE:
			if piece.type == Piece.Type.NORMAL:
				var up_btn := Button.new()
				up_btn.text = "Upgrade (20)"
				up_btn.disabled = _chips < COST_UPGRADE
				up_btn.add_theme_font_size_override("font_size", 11)
				var i := idx
				up_btn.pressed.connect(func(): _on_upgrade_clicked(i))
				hbox.add_child(up_btn)
			if not piece.modifiers.is_empty():
				var rem_btn := Button.new()
				rem_btn.text = "Remove (5)"
				rem_btn.disabled = _chips < COST_REMOVE
				rem_btn.add_theme_font_size_override("font_size", 11)
				var i := idx
				rem_btn.pressed.connect(func(): _on_remove_clicked(i))
				hbox.add_child(rem_btn)

		Phase.ATTACH_PICK_PIECE:
			if piece.modifiers.size() < 3:
				var att_btn := Button.new()
				att_btn.text = "Attach here"
				att_btn.add_theme_font_size_override("font_size", 11)
				var i := idx
				att_btn.pressed.connect(func(): _on_attach_piece_clicked(i))
				hbox.add_child(att_btn)
			else:
				var full_lbl := Label.new()
				full_lbl.text = "(full)"
				full_lbl.add_theme_color_override("font_color", UITheme.TEXT_MUTED_ON_SURFACE)
				full_lbl.add_theme_font_size_override("font_size", 11)
				hbox.add_child(full_lbl)

		Phase.REMOVE_PICK_MOD:
			if idx == _selected_piece_idx:
				for mi in piece.modifiers.size():
					var mod_btn := Button.new()
					mod_btn.text = piece.modifiers[mi]
					mod_btn.add_theme_font_size_override("font_size", 11)
					var i := idx
					var m := mi
					mod_btn.pressed.connect(func(): _on_remove_mod_clicked(i, m))
					hbox.add_child(mod_btn)

		Phase.UPGRADE_PICK_TYPE:
			if idx == _selected_piece_idx:
				var w_btn := Button.new()
				w_btn.text = "Weighted"
				w_btn.add_theme_font_size_override("font_size", 11)
				var i := idx
				w_btn.pressed.connect(func(): _on_type_selected(i, Piece.Type.WEIGHTED))
				hbox.add_child(w_btn)

				var g_btn := Button.new()
				g_btn.text = "Ghost"
				g_btn.add_theme_font_size_override("font_size", 11)
				g_btn.pressed.connect(func(): _on_type_selected(i, Piece.Type.GHOST))
				hbox.add_child(g_btn)

	return panel


func _type_name(t: Piece.Type) -> String:
	match t:
		Piece.Type.NORMAL: return "Normal"
		Piece.Type.WEIGHTED: return "Weighted"
		Piece.Type.GHOST: return "Ghost"
		Piece.Type.VOLATILE: return "Volatile"
	return "?"


func _on_cancel() -> void:
	_phase = Phase.IDLE
	_selected_offer = -1
	_selected_piece_idx = -1
	_refresh()


func _on_offer_clicked(offer_idx: int) -> void:
	if _phase != Phase.IDLE or _chips < COST_ATTACH or _offer_used[offer_idx]:
		return
	_selected_offer = offer_idx
	_phase = Phase.ATTACH_PICK_PIECE
	_refresh()


func _on_reroll() -> void:
	if _rerolled or _chips < COST_REROLL or _phase != Phase.IDLE:
		return
	_chips -= COST_REROLL
	_offers = _roll_offers()
	_offer_used = [false, false, false]
	_rerolled = true
	_refresh()


func _on_attach_piece_clicked(piece_idx: int) -> void:
	if _phase != Phase.ATTACH_PICK_PIECE:
		return
	var piece: Piece = _bag.get_piece_at(piece_idx)
	if piece.modifiers.size() >= 3:
		return
	_chips -= COST_ATTACH
	piece.modifiers.append(_offers[_selected_offer])
	_offer_used[_selected_offer] = true
	_phase = Phase.IDLE
	_selected_offer = -1
	_refresh()


func _on_remove_clicked(piece_idx: int) -> void:
	if _phase != Phase.IDLE or _chips < COST_REMOVE:
		return
	_selected_piece_idx = piece_idx
	_phase = Phase.REMOVE_PICK_MOD
	_refresh()


func _on_remove_mod_clicked(piece_idx: int, mod_idx: int) -> void:
	if _phase != Phase.REMOVE_PICK_MOD:
		return
	var piece: Piece = _bag.get_piece_at(piece_idx)
	if mod_idx >= piece.modifiers.size():
		return
	_chips -= COST_REMOVE
	piece.modifiers.remove_at(mod_idx)
	_phase = Phase.IDLE
	_selected_piece_idx = -1
	_refresh()


func _on_upgrade_clicked(piece_idx: int) -> void:
	if _phase != Phase.IDLE or _chips < COST_UPGRADE:
		return
	_selected_piece_idx = piece_idx
	_phase = Phase.UPGRADE_PICK_TYPE
	_refresh()


func _on_type_selected(piece_idx: int, new_type: Piece.Type) -> void:
	if _phase != Phase.UPGRADE_PICK_TYPE:
		return
	var piece: Piece = _bag.get_piece_at(piece_idx)
	if piece.type != Piece.Type.NORMAL:
		return
	_chips -= COST_UPGRADE
	piece.type = new_type
	_phase = Phase.IDLE
	_selected_piece_idx = -1
	_refresh()


func _on_done() -> void:
	if _phase != Phase.IDLE:
		return
	hide()
	shop_closed.emit(_chips)
