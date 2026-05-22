class_name PieceQueuePreview extends Control

var renderer: BoardRenderer
var entry: QueueEntry = QueueEntry.new()


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_entry(new_entry: QueueEntry) -> void:
	entry = new_entry
	queue_redraw()


func _draw() -> void:
	if renderer == null or renderer.theme == null:
		return
	var side := minf(size.x, size.y)
	var origin := (size - Vector2(side, side)) * 0.5
	var rect := Rect2(origin, Vector2(side, side))
	renderer.theme.draw_queue_entry(self, rect, entry)
