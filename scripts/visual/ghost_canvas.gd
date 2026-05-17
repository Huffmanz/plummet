class_name GhostCanvas extends Node2D

var renderer: BoardRenderer
var state: RenderState


func refresh(new_state: RenderState) -> void:
	state = new_state
	queue_redraw()


func _draw() -> void:
	if renderer != null and state != null:
		renderer.render_ghost(state, self)
