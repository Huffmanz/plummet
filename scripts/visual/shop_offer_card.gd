class_name ShopOfferCard extends PanelContainer

signal drag_started(offer_index: int)
signal drag_ended

const RELIC_BORDER := ShopIcon.RELIC_BORDER
const _DragIconScript := preload("res://scripts/visual/shop_offer_drag_icon.gd")

@onready var _offer_visual: ShopOfferVisual = %OfferVisual
@onready var _name_lbl: Label = %NameLabel
@onready var _type_lbl: Label = %TypeLabel
@onready var _desc_lbl: Label = %DescLabel
@onready var _footer_lbl: Label = %FooterLabel

var _is_relic: bool = false
var _footer_text: String = ""
var _icon_border_color: Color = UITheme.ACCENT
var offer_index: int = 0
var offer_kind: String = ""
var offer_id: String = ""
var offer_cost: int = 0

var _can_drag: bool = true
var _consumed: bool = false
var shop_audio: ShopAudio = null

var _press_pos: Vector2 = Vector2.ZERO
var _pressed: bool = false
var _hidden_for_drag: bool = false
var _drop_accepted: bool = false
var _affordable: bool = true
var _cursor_icon: ShopOfferDragIcon = null
var _shrink_tween: Tween = null

@export var reduced_motion: bool = false
var _panel_style: StyleBoxFlat = null
var _border_base_color: Color = Color.WHITE
var _hover_tween: Tween = null
var _pulse_tween: Tween = null
var _shimmer_tween: Tween = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_style_labels()
	_ignore_mouse_on_children(self)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _style_labels() -> void:
	UITheme.style_label_primary(_name_lbl, true)
	UITheme.style_label_muted(_type_lbl, true)
	UITheme.style_label_primary(_desc_lbl, true)
	_desc_lbl.add_theme_font_size_override("font_size", 9)
	_footer_lbl.add_theme_color_override("font_color", UITheme.ACCENT_POP)
	_footer_lbl.add_theme_font_size_override("font_size", 9)


func setup(
	index: int,
	kind: String,
	id: String,
	cost: int,
	title: String,
	type_label: String,
	description: String,
	hint: String,
	icon_color: Color,
	is_relic: bool,
	icon_texture: Texture2D = null
) -> void:
	_kill_all_tweens()
	scale = Vector2.ONE
	pivot_offset = Vector2.ZERO
	offer_index = index
	offer_kind = kind
	offer_id = id
	offer_cost = cost
	_name_lbl.text = title
	_type_lbl.text = type_label
	_desc_lbl.text = description
	_icon_border_color = icon_color
	_is_relic = is_relic
	_footer_text = _format_footer(cost, hint)
	_footer_lbl.text = _footer_text
	call_deferred("_setup_offer_visual", kind, id)
	_apply_border(is_relic)
	set_consumed(false)
	set_affordable(true)
	if is_relic and not reduced_motion:
		_start_relic_shimmer()


func _setup_offer_visual(kind: String, id: String) -> void:
	if _offer_visual != null:
		_offer_visual.setup(kind, id)


static func format_modifier_type(trigger: String) -> String:
	var effect := "land effect" if trigger == "land" else "%s effect" % trigger
	return "Modifier · %s" % effect


static func format_relic_type() -> String:
	return "Relic · run-wide"


static func format_piece_type() -> String:
	return "Piece type"


func _format_footer(cost: int, hint: String) -> String:
	if cost < 0:
		return hint
	if cost == 0:
		return "Free · %s" % hint
	return "%d chips · %s" % [cost, hint]


func restore_visibility_for_deal_in() -> void:
	set_affordable(_affordable)


func set_affordable(affordable: bool) -> void:
	if _consumed:
		return
	_affordable = affordable
	_can_drag = affordable and not _hidden_for_drag
	var dim := not affordable
	modulate = Color(1, 1, 1, 0.42) if dim else Color.WHITE
	_footer_lbl.add_theme_color_override(
		"font_color",
		UITheme.TEXT_MUTED_ON_SURFACE if dim else UITheme.ACCENT_POP
	)
	if dim and not reduced_motion:
		_start_unaffordable_pulse()
	else:
		_stop_unaffordable_pulse()


const EXIT_DURATION := 0.18


func play_exit() -> void:
	_kill_all_tweens()
	_stop_hover_immediate()
	_stop_relic_shimmer()
	if reduced_motion or modulate.a <= 0.01:
		modulate = Color(1, 1, 1, 0)
		return
	pivot_offset = size * 0.5
	var t := create_tween().set_parallel(true)
	t.tween_property(self, "scale", Vector2(0.8, 0.8), EXIT_DURATION) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	t.tween_property(self, "modulate:a", 0.0, EXIT_DURATION).set_ease(Tween.EASE_IN)


func set_consumed(consumed: bool) -> void:
	_consumed = consumed
	_drop_accepted = false
	if consumed:
		_stop_unaffordable_pulse()
		_stop_relic_shimmer()
		_stop_hover_immediate()
		if not reduced_motion and modulate.a > 0.01:
			pivot_offset = size * 0.5
			var t := create_tween().set_parallel(true)
			t.tween_property(self, "scale", Vector2(0.85, 0.85), 0.18) \
				.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
			t.tween_property(self, "modulate:a", 0.0, 0.18).set_ease(Tween.EASE_IN)
			t.set_parallel(false)
			t.tween_callback(_apply_consumed_appearance)
		else:
			_apply_consumed_appearance()
		return
	_apply_active_appearance()
	if not _hidden_for_drag:
		_footer_lbl.text = _footer_text
	set_affordable(_affordable)


func _apply_consumed_appearance() -> void:
	_can_drag = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	modulate = Color(1, 1, 1, 0)


func _apply_active_appearance() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_apply_border(_is_relic)


func _apply_border(is_relic: bool) -> void:
	var sb := UITheme.make_surface_style(10, UITheme.SURFACE_LIGHT)
	if is_relic:
		sb.border_color = RELIC_BORDER
		sb.set_border_width_all(3)
	else:
		sb.set_border_width_all(2)
	_panel_style = sb
	_border_base_color = sb.border_color
	add_theme_stylebox_override("panel", sb)


func _gui_input(event: InputEvent) -> void:
	if not _can_drag:
		if event is InputEventMouseButton:
			var mb := event as InputEventMouseButton
			if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed and shop_audio != null:
				shop_audio.play_cant_afford()
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if mb.pressed:
			_pressed = true
			_press_pos = mb.position
			accept_event()
		else:
			_pressed = false
	elif event is InputEventMouseMotion and _pressed:
		var mm := event as InputEventMouseMotion
		if mm.position.distance_to(_press_pos) >= 8.0:
			_pressed = false
			_start_drag()


func _start_drag() -> void:
	var data: Dictionary = _make_drag_payload()
	if data.is_empty():
		return
	if shop_audio != null:
		shop_audio.play_drag_pickup()
	_stop_hover_immediate()
	_hidden_for_drag = true
	GameCursor.apply_closed()
	pivot_offset = size * 0.5
	if _shrink_tween != null and _shrink_tween.is_valid():
		_shrink_tween.kill()
	_shrink_tween = create_tween().set_parallel(true)
	_shrink_tween.tween_property(self, "scale", Vector2.ZERO, 0.12) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	_shrink_tween.tween_property(self, "modulate:a", 0.0, 0.09).set_ease(Tween.EASE_IN)
	_spawn_cursor_icon()
	drag_started.emit(offer_index)
	force_drag(data, _make_drag_preview())


func _spawn_cursor_icon() -> void:
	_clear_cursor_icon()
	var vp := get_viewport()
	if vp == null:
		return
	_cursor_icon = _DragIconScript.create_for_offer(offer_kind, offer_id)
	vp.add_child(_cursor_icon)
	_cursor_icon.follow_cursor(vp)


func _clear_cursor_icon() -> void:
	if _cursor_icon != null and is_instance_valid(_cursor_icon):
		_cursor_icon.queue_free()
	_cursor_icon = null


func _process(_delta: float) -> void:
	if _cursor_icon == null or not is_instance_valid(_cursor_icon):
		return
	var vp := get_viewport()
	if vp:
		_cursor_icon.follow_cursor(vp)


func _make_drag_payload() -> Dictionary:
	if not _can_drag:
		return {}
	return {
		"type": "shop_offer",
		"index": offer_index,
		"kind": offer_kind,
		"id": offer_id,
		"cost": offer_cost,
	}


func _make_drag_preview() -> Control:
	var stub := Control.new()
	stub.custom_minimum_size = Vector2(1, 1)
	stub.size = Vector2(1, 1)
	stub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return stub


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		_stop_hover_immediate()
		if _shrink_tween != null and _shrink_tween.is_valid():
			_shrink_tween.kill()
		_shrink_tween = null
		scale = Vector2.ONE
		pivot_offset = Vector2.ZERO
		_hidden_for_drag = false
		if _drop_accepted or _consumed:
			modulate = Color(1, 1, 1, 0)
		else:
			set_affordable(_affordable)
		drag_ended.emit()
		call_deferred("_clear_cursor_icon")
		_pressed = false
		_refresh_shop_cursor()


func is_offer_hover_target() -> bool:
	return not _consumed and not _hidden_for_drag


func is_dragging() -> bool:
	return _hidden_for_drag


func _on_mouse_entered() -> void:
	if is_offer_hover_target():
		GameCursor.apply_open()
		if _affordable:
			if shop_audio != null:
				shop_audio.play_offer_hover()
			if not reduced_motion:
				_start_hover()


func _on_mouse_exited() -> void:
	if is_dragging():
		return
	_stop_hover()
	_refresh_shop_cursor()


func _refresh_shop_cursor() -> void:
	get_tree().call_group("shop_cursor_owner", "_update_shop_cursor")


func _ignore_mouse_on_children(node: Node) -> void:
	for child in node.get_children():
		if child is Control:
			(child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ignore_mouse_on_children(child)


func set_drag_dim(on: bool) -> void:
	if _consumed or _hidden_for_drag or _drop_accepted:
		return
	if on:
		modulate = Color(1, 1, 1, 0.45)
	else:
		set_affordable(_affordable)


func take_cursor_icon() -> ShopOfferDragIcon:
	var icon := _cursor_icon as ShopOfferDragIcon
	_cursor_icon = null
	_drop_accepted = true
	return icon


# --- Hover ---

func _start_hover() -> void:
	if _shimmer_tween != null and _shimmer_tween.is_valid():
		_shimmer_tween.kill()
		_shimmer_tween = null
	if _hover_tween != null and _hover_tween.is_valid():
		_hover_tween.kill()
	pivot_offset = size * 0.5
	_hover_tween = create_tween().set_parallel(true)
	_hover_tween.tween_property(self, "scale", Vector2(1.03, 1.03), 0.12) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	if _panel_style != null:
		_hover_tween.tween_property(_panel_style, "border_color", _border_base_color.lightened(0.35), 0.12) \
			.set_ease(Tween.EASE_OUT)


func _stop_hover() -> void:
	if _hover_tween != null and _hover_tween.is_valid():
		_hover_tween.kill()
	_hover_tween = null
	if _consumed or _hidden_for_drag:
		return
	var t := create_tween().set_parallel(true)
	t.tween_property(self, "scale", Vector2.ONE, 0.1).set_ease(Tween.EASE_OUT)
	if _panel_style != null:
		t.tween_property(_panel_style, "border_color", _border_base_color, 0.1).set_ease(Tween.EASE_OUT)
	if _is_relic and not reduced_motion and not _consumed:
		t.set_parallel(false)
		t.tween_callback(_start_relic_shimmer)


func _stop_hover_immediate() -> void:
	if _hover_tween != null and _hover_tween.is_valid():
		_hover_tween.kill()
	_hover_tween = null
	if _panel_style != null:
		_panel_style.border_color = _border_base_color


# --- Unaffordable pulse ---

func _start_unaffordable_pulse() -> void:
	if _pulse_tween != null and _pulse_tween.is_valid():
		_pulse_tween.kill()
	_pulse_tween = create_tween().set_loops()
	_pulse_tween.tween_property(self, "modulate:a", 0.48, 0.6) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_pulse_tween.tween_property(self, "modulate:a", 0.35, 0.6) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


func _stop_unaffordable_pulse() -> void:
	if _pulse_tween != null and _pulse_tween.is_valid():
		_pulse_tween.kill()
	_pulse_tween = null


# --- Relic shimmer ---

func _start_relic_shimmer() -> void:
	if not _is_relic or reduced_motion or _panel_style == null or _consumed:
		return
	if _shimmer_tween != null and _shimmer_tween.is_valid():
		_shimmer_tween.kill()
	_shimmer_tween = create_tween().set_loops()
	_shimmer_tween.tween_property(_panel_style, "border_color", RELIC_BORDER.lightened(0.35), 0.75) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_shimmer_tween.tween_property(_panel_style, "border_color", RELIC_BORDER, 0.75) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


func _stop_relic_shimmer() -> void:
	if _shimmer_tween != null and _shimmer_tween.is_valid():
		_shimmer_tween.kill()
	_shimmer_tween = null
	if _panel_style != null:
		_panel_style.border_color = _border_base_color


# --- Utilities ---

func _kill_all_tweens() -> void:
	for tw: Tween in [_hover_tween, _pulse_tween, _shimmer_tween, _shrink_tween]:
		if tw != null and tw.is_valid():
			tw.kill()
	_hover_tween = null
	_pulse_tween = null
	_shimmer_tween = null
	_shrink_tween = null


