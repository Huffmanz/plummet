class_name ShopOfferVisual extends Control
## Offer / drag icon — piece shader disc (bag proportions), rounded badges for modifiers & relics.

const DEFAULT_SIZE := Vector2(26, 26)
## Modifier badge on a bag piece — same ratio on offer cards.
const BADGE_FILL_RATIO := 0.42

const _PIECE_PREVIEW_SCENE := preload("res://scenes/game/shop_piece_preview.tscn")


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func setup(kind: String, id: String, display_size: Vector2 = DEFAULT_SIZE) -> void:
	custom_minimum_size = display_size
	size = display_size
	for child in get_children():
		child.queue_free()

	match kind:
		"modifier":
			_mount_modifier(id, display_size)
		"piece_type":
			_mount_piece_type(id, display_size)
		_:
			_mount_relic(id, display_size)


func _badge_size(display_size: Vector2) -> Vector2:
	var side := display_size.x * BADGE_FILL_RATIO
	return Vector2(side, side)


func _mount_modifier(modifier_id: String, display_size: Vector2) -> void:
	var badge := ModifierIconBadge.create_for_modifier(modifier_id, display_size)
	_add_centered(badge)


func _mount_piece_type(type_id: String, display_size: Vector2) -> void:
	var preview: ShopPiecePreview = _PIECE_PREVIEW_SCENE.instantiate()
	preview.custom_minimum_size = display_size
	preview.size = display_size
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_add_centered(preview)
	var piece := Piece.new(Piece.Owner.PLAYER, PieceVisualUtil.piece_type_from_registry_id(type_id))
	preview.setup(piece)


func _mount_relic(relic_id: String, display_size: Vector2) -> void:
	var badge := ModifierIconBadge.create_for_relic(relic_id, display_size)
	_add_centered(badge)


func _add_centered(content: Control) -> void:
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var host := CenterContainer.new()
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(host)
	host.add_child(content)
