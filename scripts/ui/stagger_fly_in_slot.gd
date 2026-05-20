class_name StaggerFlyInSlot extends Control
## Wraps one child so horizontal fly-in can animate without fighting VBox layout.

var _content: Control
var _pan: Control


func wrap(content: Control) -> void:
	_content = content
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = content.size_flags_vertical
	clip_contents = true
	_pan = Control.new()
	_pan.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_pan)
	_pan.add_child(content)
	_layout_content_in_pan()
	_sync_minimum_size()


func get_content() -> Control:
	if _content == null and _pan != null and _pan.get_child_count() > 0:
		_content = _pan.get_child(0) as Control
	return _content


func prepare_fly_in(offset: float) -> void:
	if _pan == null:
		return
	_layout_pan()
	_pan.position = Vector2(-offset, 0.0)
	var mod := _pan.modulate
	mod.a = 0.0
	_pan.modulate = mod


func tween_fly_in(tween: Tween, duration: float, delay: float) -> void:
	if _pan == null:
		return
	tween.tween_property(_pan, "position:x", 0.0, duration) \
		.set_delay(delay) \
		.set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_OUT)
	tween.tween_property(_pan, "modulate:a", 1.0, duration * 0.9) \
		.set_delay(delay) \
		.set_trans(Tween.TRANS_QUAD) \
		.set_ease(Tween.EASE_OUT)


func _layout_content_in_pan() -> void:
	var content := get_content()
	if content == null or _pan == null:
		return
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _layout_pan() -> void:
	if _pan == null:
		return
	_pan.position = Vector2.ZERO
	_pan.size = size


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout_pan()
		_sync_minimum_size()


func _sync_minimum_size() -> void:
	var content := get_content()
	if content == null:
		return
	var min_h := content.get_combined_minimum_size().y
	if content is Label and (content as Label).autowrap_mode != TextServer.AUTOWRAP_OFF:
		min_h = maxf(min_h, content.get_minimum_size().y)
	custom_minimum_size = Vector2(0.0, min_h)
