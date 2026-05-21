class_name ShopAudio extends Node

@onready var _open: RandomAudioPlayer = $OpenSfx
@onready var _close: RandomAudioPlayer = $CloseSfx
@onready var _drag_pickup: RandomAudioPlayer = $DragPickupSfx
@onready var _drop_valid_hover: RandomAudioPlayer = $DropValidSfx
@onready var _drop_invalid: RandomAudioPlayer = $DropInvalidSfx
@onready var _modifier_attach: RandomAudioPlayer = $ModifierAttachSfx
@onready var _piece_type_apply: RandomAudioPlayer = $PieceTypeApplySfx
@onready var _relic_acquire: RandomAudioPlayer = $RelicAcquireSfx
@onready var _modifier_remove: RandomAudioPlayer = $ModifierRemoveSfx
@onready var _reroll: RandomAudioPlayer = $RerollSfx
@onready var _chip_spend: RandomAudioPlayer = $ChipSpendSfx
@onready var _cant_afford: RandomAudioPlayer = $CantAffordSfx
@onready var _offer_hover: RandomAudioPlayer = $OfferHoverSfx

const _PAN_POP_STREAMS: Array[AudioStream] = [
	preload("res://assets/sfx/kenney_impact-sounds/Audio/impactGeneric_light_000.ogg"),
	preload("res://assets/sfx/kenney_impact-sounds/Audio/impactGeneric_light_001.ogg"),
	preload("res://assets/sfx/kenney_impact-sounds/Audio/impactGeneric_light_002.ogg"),
	preload("res://assets/sfx/kenney_impact-sounds/Audio/impactGeneric_light_003.ogg"),
	preload("res://assets/sfx/kenney_impact-sounds/Audio/impactGeneric_light_004.ogg"),
]

var muted: bool = false


func _ready() -> void:
	_configure_player(
		_open,
		[
			preload("res://assets/sfx/571581__el_boss__playing-card-slide-right.wav"),
		],
		0.95,
		1.05,
		-6.0
	)
	_configure_player(
		_close,
		[
			preload("res://assets/sfx/kenney_interface-sounds/Audio/switch_005.ogg"),
			preload("res://assets/sfx/kenney_interface-sounds/Audio/switch_006.ogg"),
		],
		0.92,
		1.0,
		-6.0
	)
	_configure_player(
		_drag_pickup,
		[preload("res://assets/sfx/817579__silverdubloons__slidecard04.wav")],
		0.88,
		1.12,
		-5.0
	)
	_configure_player(
		_drop_valid_hover,
		[preload("res://assets/sfx/kenney_ui-audio/Audio/click3.ogg")],
		0.92,
		1.08,
		-8.0
	)
	_configure_player(
		_drop_invalid,
		[preload("res://assets/sfx/kenney_interface-sounds/Audio/bong_001.ogg")],
		0.85,
		1.0,
		-10.0
	)
	_configure_player(
		_modifier_attach,
		[
			preload("res://assets/sfx/kenney_interface-sounds/Audio/switch_003.ogg"),
			preload("res://assets/sfx/kenney_interface-sounds/Audio/switch_004.ogg"),
		],
		0.94,
		1.06,
		-4.0
	)
	_configure_player(
		_piece_type_apply,
		[
			preload("res://assets/sfx/kenney_interface-sounds/Audio/switch_005.ogg"),
			preload("res://assets/sfx/kenney_interface-sounds/Audio/switch_006.ogg"),
		],
		0.94,
		1.06,
		-4.0
	)
	_configure_player(
		_relic_acquire,
		[preload("res://assets/sfx/kenney_ui-audio/Audio/switch30.ogg")],
		0.94,
		1.06,
		-3.0
	)
	_configure_player(
		_modifier_remove,
		[
			preload("res://assets/sfx/kenney_interface-sounds/Audio/switch_002.ogg"),
			preload("res://assets/sfx/kenney_interface-sounds/Audio/switch_001.ogg"),
		],
		0.9,
		1.02,
		-5.0
	)
	_configure_player(
		_reroll,
		[
			preload("res://assets/sfx/kenney_casino-audio/Audio/dice-throw-1.ogg"),
			preload("res://assets/sfx/kenney_casino-audio/Audio/dice-throw-2.ogg"),
			preload("res://assets/sfx/kenney_casino-audio/Audio/dice-throw-3.ogg"),
		],
		0.92,
		1.08,
		-4.0
	)
	_configure_player(
		_chip_spend,
		[preload("res://assets/sfx/209578__zott820__cash-register-purchase.wav")],
		0.94,
		1.06,
		-5.0
	)
	_configure_player(
		_cant_afford,
		[preload("res://assets/sfx/kenney_interface-sounds/Audio/bong_001.ogg")],
		0.85,
		1.0,
		-12.0
	)
	_configure_player(_offer_hover, _PAN_POP_STREAMS, 0.92, 1.08, 0.0)


func play_open() -> void:
	_play(_open, false)


func play_close() -> void:
	_play(_close, false)


func play_drag_pickup() -> void:
	_play_overlapping(_drag_pickup)


func play_drop_valid_hover() -> void:
	_play_overlapping(_drop_valid_hover)


func play_drop_invalid() -> void:
	_play_overlapping(_drop_invalid)


func play_modifier_attach() -> void:
	_play(_modifier_attach, false)


func play_piece_type_apply() -> void:
	_play(_piece_type_apply, false)


func play_relic_acquire() -> void:
	_play(_relic_acquire, false)


func play_modifier_remove() -> void:
	_play(_modifier_remove, false)


func play_reroll() -> void:
	_play(_reroll, false)


func play_chip_spend() -> void:
	_play_overlapping(_chip_spend)


func play_cant_afford() -> void:
	_play_overlapping(_cant_afford)


func play_offer_hover() -> void:
	_play_overlapping(_offer_hover)


func _configure_player(
	player: RandomAudioPlayer,
	streams: Array[AudioStream],
	min_pitch: float,
	max_pitch: float,
	volume_db: float
) -> void:
	if player == null:
		return
	player.bus = &"sfx"
	player.volume_db = volume_db
	player.streams = streams
	player.randomize_pitch = true
	player.min_pitch = min_pitch
	player.max_pitch = max_pitch


func _play(player: RandomAudioPlayer, overlapping: bool) -> void:
	if muted or player == null or player.streams.is_empty():
		return
	if overlapping:
		player.play_random_overlapping(self)
	else:
		player.play_random()


func _play_overlapping(player: RandomAudioPlayer) -> void:
	_play(player, true)
