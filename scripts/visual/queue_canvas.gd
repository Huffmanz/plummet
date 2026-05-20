class_name QueueCanvas extends Control

var renderer: BoardRenderer
var state: RenderState

var _t: float = 0.0
var _slide_offset: float = 0.0  # pixels: slides in when queue consumes a piece


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR


func refresh(new_state: RenderState) -> void:
	var old_len := state.player_queue.size() if state != null else 0
	var new_len := new_state.player_queue.size()
	if new_len < old_len and renderer != null and renderer.layout != null:
		_slide_offset = -(renderer.layout.cell_size + LayoutManager.CELL_GAP)
	state = new_state
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	if _slide_offset < 0.0:
		_slide_offset = minf(_slide_offset + delta * 600.0, 0.0)
	queue_redraw()


func _draw() -> void:
	if renderer == null or renderer.layout == null or state == null:
		return
	var cs: float = renderer.layout.cell_size
	var gap: float = LayoutManager.CELL_GAP
	var step := cs + gap

	for i in state.player_queue.size():
		var base_y := float(i) * step + _slide_offset
		var extra_y := 0.0

		if i == 1:
			extra_y = sin(_t * 5.0) * 2.5

		var rect := Rect2(0.0, base_y + extra_y, cs, cs)
		renderer.theme.draw_queue_entry(self, rect, state.player_queue[i])

		# Modifier badge pulse: overdraw a dim layer that pulses, creating a breathing effect
		if not state.player_queue[i].modifier.is_empty():
			var dim := 0.15 + 0.15 * sin(_t * 6.0 + float(i) * 1.5)
			var badge_size := cs * 0.42
			var badge_y := rect.position.y + cs - badge_size - 2.0
			var badge_x := rect.get_center().x - badge_size * 0.5
			draw_rect(Rect2(badge_x, badge_y, badge_size, badge_size), Color(0.0, 0.0, 0.0, dim))
