class_name ShopOfferDragIcon extends Control
## Cursor-following drag preview using ShopOfferVisual (same look as bag pieces).

const BADGE_SIZE := Vector2(40, 40)

var _visual: ShopOfferVisual = null
var _snapping: bool = false
var _offer_kind: String = ""
var _offer_id: String = ""


static func create_for_offer(kind: String, id: String) -> ShopOfferDragIcon:
	var icon := ShopOfferDragIcon.new()
	icon._offer_kind = kind
	icon._offer_id = id
	return icon


func _init() -> void:
	custom_minimum_size = BADGE_SIZE
	size = BADGE_SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 1000


func _ready() -> void:
	_build_visual()


func _build_visual() -> void:
	if _visual != null and is_instance_valid(_visual):
		_visual.queue_free()
	_visual = ShopOfferVisual.new()
	_visual.setup(_offer_kind, _offer_id, BADGE_SIZE)
	_visual.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_visual)


func follow_cursor(viewport: Viewport) -> void:
	if _snapping:
		return
	position = viewport.get_mouse_position() - size * 0.5


func snap_to(target_global_pos: Vector2, callback: Callable, reduced_motion: bool = false) -> void:
	_snapping = true
	if reduced_motion:
		queue_free()
		callback.call()
		return
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(self, "global_position", target_global_pos - size * 0.5, 0.16) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	t.tween_property(self, "scale", Vector2(0.4, 0.4), 0.16).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "modulate:a", 0.0, 0.14).set_ease(Tween.EASE_IN)
	t.chain().tween_callback(func() -> void:
		queue_free()
		callback.call()
	)
