class_name BoardCanvas extends Node2D

var renderer: BoardRenderer
var state: RenderState
var shake_offset: Vector2 = Vector2.ZERO
var anim_layer: AnimLayer = null


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR


func refresh(new_state: RenderState) -> void:
	state = new_state
	queue_redraw()


func _process(_delta: float) -> void:
	if state == null or renderer == null:
		return
	if anim_layer != null and anim_layer.has_active_pieces():
		queue_redraw()
		return
	for c in RenderState.COLS:
		if c >= state.landing_rows.size():
			continue
		var lr := state.landing_rows[c]
		if lr < 0:
			continue
		var near_full := lr <= 1 if state.gravity_flipped else lr >= RenderState.ROWS - 2
		if near_full:
			queue_redraw()
			return


func _draw() -> void:
	if renderer == null or state == null:
		return
	var s := renderer.idle_breathe_scale
	if s != 1.0 and renderer.layout != null:
		var origin := renderer.layout.board_origin + shake_offset
		var bw := RenderState.COLS * renderer.layout.cell_size + (RenderState.COLS - 1) * LayoutManager.CELL_GAP
		var bh := RenderState.ROWS * renderer.layout.cell_size + (RenderState.ROWS - 1) * LayoutManager.CELL_GAP
		var center := origin + Vector2(bw, bh) * 0.5
		draw_set_transform(center * (1.0 - s), 0.0, Vector2(s, s))
	else:
		draw_set_transform(shake_offset)
	renderer.render_board_under(state, self)
	renderer.render_board_tiles(state, self)
	if anim_layer != null:
		anim_layer.draw_pieces_to(self)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
