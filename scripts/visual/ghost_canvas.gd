class_name GhostCanvas extends Node2D

var renderer: BoardRenderer
var state: RenderState
var shake_offset: Vector2 = Vector2.ZERO


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR


func refresh(new_state: RenderState) -> void:
	state = new_state
	queue_redraw()


func _draw() -> void:
	if renderer != null and state != null:
		draw_set_transform(shake_offset)
		renderer.render_ghost(state, self)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
