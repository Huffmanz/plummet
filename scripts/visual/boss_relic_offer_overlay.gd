class_name BossRelicOfferOverlay extends Control

signal relic_chosen(relic_id: String)
signal finished

const _CARD_SCENE := preload("res://scenes/run/boss_relic_offer_card.tscn")
const _PREVIEW_OFFERS: Array[String] = ["Cartographer", "Cushion"]
const _OFFER_HOVER_PAD_Y: int = 8

@onready var _card_panel: PanelContainer = %CardPanel
@onready var _title_label: RichTextLabel = %TitleLabel
@onready var _subtitle_label: Label = %SubtitleLabel
@onready var _offers_row: HBoxContainer = %OffersRow
@onready var _fly_in: StaggerFlyInContainer = %FlyInVBox
@onready var _win_sfx: AudioStreamPlayer = %WinSfx

var _offer_cards: Array[BossRelicOfferCard] = []
var _selection_locked: bool = false

@export var preview_when_run_directly: bool = true
@export var reduced_motion: bool = false


func _ready() -> void:
	_apply_theme()
	if preview_when_run_directly and get_parent() == get_tree().root:
		call_deferred("setup_offers", _PREVIEW_OFFERS.duplicate())


func _apply_theme() -> void:
	_card_panel.add_theme_stylebox_override("panel", UITheme.make_surface_style())
	_title_label.add_theme_color_override("default_color", UITheme.VICTORY)
	UITheme.style_label_muted(_subtitle_label, true)
	_subtitle_label.add_theme_font_size_override("font_size", 12)


func setup_offers(relic_ids: Array[String]) -> void:
	_selection_locked = false
	_clear_offers()
	var ids: Array[String] = []
	for id in relic_ids:
		if id is String and not (id as String).is_empty():
			ids.append(id)
	if ids.is_empty():
		return
	for relic_id in ids:
		var card: BossRelicOfferCard = _CARD_SCENE.instantiate()
		card.reduced_motion = reduced_motion
		card.chosen.connect(_on_card_chosen)
		_offers_row.add_child(_wrap_offer_card(card))
		card.setup(relic_id)
		_offer_cards.append(card)
	_offers_row.alignment = BoxContainer.ALIGNMENT_CENTER
	if _win_sfx != null and not reduced_motion:
		_win_sfx.play()
	_fly_in.reset_targets()
	call_deferred("_unclip_offers_row")
	_fly_in.play_fly_in()


func _wrap_offer_card(card: BossRelicOfferCard) -> MarginContainer:
	var wrap := MarginContainer.new()
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_theme_constant_override("margin_top", _OFFER_HOVER_PAD_Y)
	wrap.add_theme_constant_override("margin_bottom", _OFFER_HOVER_PAD_Y)
	wrap.add_child(card)
	return wrap


func _unclip_offers_row() -> void:
	if not is_instance_valid(_offers_row):
		return
	for child in _fly_in.get_children():
		if child is StaggerFlyInSlot:
			var slot := child as StaggerFlyInSlot
			if slot.get_content() == _offers_row:
				slot.clip_contents = false
				return


func _clear_offers() -> void:
	for card in _offer_cards:
		if is_instance_valid(card):
			card.queue_free()
	_offer_cards.clear()
	for child in _offers_row.get_children():
		child.queue_free()


func _on_card_chosen(relic_id: String) -> void:
	if _selection_locked or relic_id.is_empty():
		return
	_selection_locked = true
	for card in _offer_cards:
		if card.relic_id != relic_id:
			card.mouse_filter = Control.MOUSE_FILTER_IGNORE
			if not reduced_motion:
				var t := card.create_tween()
				t.tween_property(card, "modulate:a", 0.35, 0.12)
	relic_chosen.emit(relic_id)
	var delay := 0.0 if reduced_motion else 0.22
	get_tree().create_timer(delay).timeout.connect(_finish)


func _finish() -> void:
	finished.emit()
	queue_free()
