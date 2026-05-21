class_name ShopOfferCard extends PanelContainer

signal drag_started(offer_index: int)
signal drag_ended

const RELIC_BORDER := Color("#4DA8B0")
const _DragIconScript := preload("res://scripts/visual/shop_offer_drag_icon.gd")

@onready var _icon_frame: PanelContainer = %IconFrame
@onready var _icon_texture: TextureRect = %IconTexture
@onready var _icon_glyph: ColorRect = %IconGlyph
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

var _press_pos: Vector2 = Vector2.ZERO
var _pressed: bool = false
var _hidden_for_drag: bool = false
var _drop_accepted: bool = false
var _affordable: bool = true
var _cursor_icon: PanelContainer = null
var _shrink_tween: Tween = null


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
	_apply_icon(icon_texture, icon_color)
	_apply_border(is_relic)
	set_consumed(false)
	set_affordable(true)


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


func set_consumed(consumed: bool) -> void:
	_consumed = consumed
	_drop_accepted = false
	if consumed:
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


func _apply_icon(texture: Texture2D, border_color: Color) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = UITheme.SURFACE
	sb.border_color = border_color
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(4)
	_icon_frame.add_theme_stylebox_override("panel", sb)

	if texture != null:
		_icon_texture.texture = texture
		_icon_texture.visible = true
		_icon_glyph.visible = false
	else:
		_icon_texture.visible = false
		_icon_glyph.visible = true
		if border_color == UITheme.PLAYER:
			_icon_glyph.color = border_color.lightened(0.22)
		else:
			_icon_glyph.color = Color(0.95, 0.93, 0.9, 1)


func _gui_input(event: InputEvent) -> void:
	if not _can_drag:
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
	_cursor_icon = _DragIconScript.create_for_offer(offer_kind, offer_id)
	var vp := get_viewport()
	if vp == null:
		return
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
		if _shrink_tween != null and _shrink_tween.is_valid():
			_shrink_tween.kill()
		_shrink_tween = null
		scale = Vector2.ONE
		pivot_offset = Vector2.ZERO
		_clear_cursor_icon()
		_hidden_for_drag = false
		if _drop_accepted or _consumed:
			modulate = Color(1, 1, 1, 0)
		else:
			set_affordable(_affordable)
		drag_ended.emit()
		_pressed = false
		_refresh_shop_cursor()


func is_offer_hover_target() -> bool:
	return not _consumed and not _hidden_for_drag


func is_dragging() -> bool:
	return _hidden_for_drag


func _on_mouse_entered() -> void:
	if is_offer_hover_target():
		GameCursor.apply_open()


func _on_mouse_exited() -> void:
	if is_dragging():
		return
	_refresh_shop_cursor()


func _refresh_shop_cursor() -> void:
	get_tree().call_group("shop_cursor_owner", "_update_shop_cursor")


func _ignore_mouse_on_children(node: Node) -> void:
	for child in node.get_children():
		if child is Control:
			(child as Control).mouse_filter = Control.MOUSE_FILTER_PASS
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


func _apply_border(is_relic: bool) -> void:
	var sb := UITheme.make_surface_style(10, UITheme.SURFACE_LIGHT)
	if is_relic:
		sb.border_color = RELIC_BORDER
		sb.set_border_width_all(3)
	else:
		sb.set_border_width_all(2)
	add_theme_stylebox_override("panel", sb)
