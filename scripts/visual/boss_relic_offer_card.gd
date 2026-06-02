class_name BossRelicOfferCard extends PanelContainer

signal chosen(relic_id: String)

const RELIC_BORDER := Color("#4DA8B0")

@onready var _icon: ShopOfferVisual = %ShopIcon
@onready var _name_lbl: Label = %NameLabel
@onready var _type_lbl: Label = %TypeLabel
@onready var _desc_lbl: Label = %DescLabel
@onready var _footer_lbl: Label = %FooterLabel
@onready var _choose_sfx: RandomAudioPlayer = %ChooseSfx

var relic_id: String = ""
var _pending_setup_id: String = ""
var _panel_style: StyleBoxFlat
var _border_base_color: Color = Color.WHITE
var _hover_tween: Tween
var _chosen: bool = false

@export var reduced_motion: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_style_labels()
	_ignore_mouse_on_children(self)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	if not _pending_setup_id.is_empty():
		_apply_setup(_pending_setup_id)
		_pending_setup_id = ""


func setup(id: String) -> void:
	relic_id = id
	_chosen = false
	visible = not id.is_empty()
	if not is_node_ready():
		_pending_setup_id = id
		return
	_apply_setup(id)


func _apply_setup(id: String) -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	modulate = Color.WHITE
	scale = Vector2.ONE
	if id.is_empty():
		return
	var rd: RelicData = DataRegistry.get_relic(id)
	if rd == null:
		_name_lbl.text = id
		_type_lbl.text = ShopOfferCard.format_relic_type()
		_desc_lbl.text = ""
		_icon.setup("relic", "", Vector2(30, 30))
	else:
		_name_lbl.text = rd.display_name
		_type_lbl.text = _format_relic_type(rd)
		_desc_lbl.text = rd.description
		_icon.setup("relic", id, Vector2(30, 30))
	_apply_border()
	_footer_lbl.text = "Click to choose"


func _format_relic_type(rd: RelicData) -> String:
	return "Relic · %s · boss drop" % rd.rarity


func _style_labels() -> void:
	UITheme.style_label_primary(_name_lbl, true)
	UITheme.style_label_muted(_type_lbl, true)
	UITheme.style_label_primary(_desc_lbl, true)
	_desc_lbl.add_theme_font_size_override("font_size", 9)
	_footer_lbl.add_theme_color_override("font_color", UITheme.ACCENT_POP)
	_footer_lbl.add_theme_font_size_override("font_size", 9)


func _apply_border() -> void:
	var sb := UITheme.make_surface_style(10, UITheme.SURFACE_LIGHT)
	sb.border_color = RELIC_BORDER
	sb.set_border_width_all(3)
	_panel_style = sb
	_border_base_color = sb.border_color
	add_theme_stylebox_override("panel", sb)


func _gui_input(event: InputEvent) -> void:
	if _chosen or relic_id.is_empty():
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			_accept_choice()
			accept_event()


func _accept_choice() -> void:
	_chosen = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _choose_sfx != null:
		_choose_sfx.play_random()
	if not reduced_motion:
		pivot_offset = size * 0.5
		var t := create_tween().set_parallel(true)
		t.tween_property(self, "scale", Vector2(0.92, 0.92), 0.14) \
			.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		t.tween_property(self, "modulate:a", 0.35, 0.14)
	chosen.emit(relic_id)


func _on_mouse_entered() -> void:
	if _chosen or relic_id.is_empty():
		return
	GameCursor.apply_open()
	if not reduced_motion:
		_start_hover()


func _on_mouse_exited() -> void:
	_stop_hover()
	GameCursor.apply_default()


func _start_hover() -> void:
	if _hover_tween != null and _hover_tween.is_valid():
		_hover_tween.kill()
	pivot_offset = size * 0.5
	_hover_tween = create_tween().set_parallel(true)
	_hover_tween.tween_property(self, "scale", Vector2(1.04, 1.04), 0.12) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	if _panel_style != null:
		_hover_tween.tween_property(
			_panel_style, "border_color", _border_base_color.lightened(0.35), 0.12
		).set_ease(Tween.EASE_OUT)


func _stop_hover() -> void:
	if _hover_tween != null and _hover_tween.is_valid():
		_hover_tween.kill()
	_hover_tween = null
	if _chosen:
		return
	var t := create_tween().set_parallel(true)
	t.tween_property(self, "scale", Vector2.ONE, 0.1).set_ease(Tween.EASE_OUT)
	if _panel_style != null:
		t.tween_property(_panel_style, "border_color", _border_base_color, 0.1) \
			.set_ease(Tween.EASE_OUT)


func _ignore_mouse_on_children(node: Node) -> void:
	for child in node.get_children():
		if child is Control:
			(child as Control).mouse_filter = Control.MOUSE_FILTER_PASS
		_ignore_mouse_on_children(child)
