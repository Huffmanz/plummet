class_name BoardCanvas extends Node2D

var renderer: BoardRenderer
var state: RenderState
var shake_offset: Vector2 = Vector2.ZERO


func refresh(new_state: RenderState) -> void:
	state = new_state
	queue_redraw()


func _draw() -> void:
	if renderer != null and state != null:
		draw_set_transform(shake_offset)
		renderer.render_board(state, self)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
