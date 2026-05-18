class_name AnimLayer extends Node2D

const _FLASH_DUR: float = 2.0 / 60.0
const _SWEEP_DUR: float = 3.0 / 60.0
const _CONTRACT_DUR: float = 6.0 / 60.0
const _DROP_START_VEL: float = 500.0
const _DROP_ACCEL: float = 3000.0
const _SQUASH_DUR: float = 3.0 / 60.0
const _BOUNCE_UP_DUR: float = 5.0 / 60.0
const _BOUNCE_DOWN_DUR: float = 4.0 / 60.0
const _SETTLE_DUR: float = 3.0 / 60.0
const _BOUNCE_HEIGHT_FRAC: float = 0.25
const _POPUP_DUR: float = 0.5
const _DROP_SPEED: float = 1400.0  # used for gravity animation only
const _GRAV_SPEED: float = 1200.0
const _BURST_DUR: float = 0.35
const _SCORE_EXPLODE_DUR: float = 0.28
const _SCORE_SEEK_DUR: float = 0.75
const _COL_REJECT_DUR: float = 0.28
const _COL_FLASH_DUR: float = 0.2
const _AI_PREVIEW_PULSE: float = 4.0
const _COMBO_IN: float = 4.0 / 60.0
const _COMBO_HOLD: float = 12.0 / 60.0
const _COMBO_OUT: float = 8.0 / 60.0

@export var reduced_motion: bool = false
@export var shake_enabled: bool = true
@export var muted: bool = false

var renderer: BoardRenderer
var shake_offset: Vector2 = Vector2.ZERO

# --- Drop animation ---
var _drop_active: bool = false
var _drop_x: float = 0.0
var _drop_y: float = 0.0
var _drop_target_y: float = 0.0
var _drop_landing_y: float = 0.0
var _drop_vel: float = 0.0
var _drop_cs: float = 48.0
var _drop_owner: CellState.Occupant = CellState.Occupant.PLAYER
var _drop_phase: int = 0  # 0=fall 1=squash 2=bounce_up 3=bounce_down 4=settle
var _drop_phase_t: float = 0.0
var _drop_scale_y: float = 1.0
var _drop_burst_rect: Rect2 = Rect2()
var _drop_burst_owner: CellState.Occupant = CellState.Occupant.PLAYER
signal _drop_done

# --- Gravity animation ---
class _GravPiece:
	var x: float = 0.0
	var from_y: float = 0.0
	var to_y: float = 0.0
	var cur_y: float = 0.0
	var cs: float = 48.0
	var occupant: CellState.Occupant = CellState.Occupant.PLAYER
	var piece_type: CellState.PieceType = CellState.PieceType.NORMAL

var _grav_active: bool = false
var _grav_pieces: Array = []
signal _grav_done

# --- Clear animation ---
var _clear_active: bool = false
var _clear_rects: Array[Rect2] = []
var _clear_phase: int = 0  # -1=sweep 0=flash 1=contract
var _clear_t: float = 0.0
var _clear_sweep_a: Vector2 = Vector2.ZERO
var _clear_sweep_b: Vector2 = Vector2.ZERO
signal _clear_done

# --- Score popups ---
class _Popup:
	var text: String = ""
	var pos: Vector2 = Vector2.ZERO
	var elapsed: float = 0.0
	var color: Color = Color(1.0, 0.95, 0.3)

var _popups: Array = []

# --- Landing burst ---
class _BurstDot:
	var pos: Vector2 = Vector2.ZERO
	var vel: Vector2 = Vector2.ZERO
	var elapsed: float = 0.0
	var color: Color = Color.WHITE

var _burst_dots: Array = []

# --- Score particles ---
class _ScoreParticle:
	var pos: Vector2 = Vector2.ZERO
	var vel: Vector2 = Vector2.ZERO
	var elapsed: float = 0.0
	var color: Color = Color.WHITE
	var target: Vector2 = Vector2.ZERO
	var seek_start: Vector2 = Vector2.ZERO
	var seeking: bool = false

var _score_particles: Array = []

# --- Column rejection shake ---
var _col_rejects: Dictionary = {}  # col -> elapsed (float)

# --- Column lock flash ---
var _col_flashes: Dictionary = {}  # col -> elapsed (float)

# --- AI drop preview ---
var _ai_preview_col: int = -1
var _ai_preview_elapsed: float = 0.0
var _ai_preview_duration: float = 0.0

# --- Screen shake ---
var _shake_intensity: float = 0.0
var _shake_total: float = 0.0
var _shake_remaining: float = 0.0

# --- Combo text ---
var _combo_text: String = ""
var _combo_elapsed: float = 0.0
var _combo_active: bool = false



func _process(delta: float) -> void:
	var dirty := false

	if _drop_active:
		_tick_drop(delta)
		dirty = true

	if _grav_active:
		_tick_grav(delta)
		dirty = true

	if _clear_active:
		_tick_clear(delta)
		dirty = true

	if not _burst_dots.is_empty():
		_tick_bursts(delta)
		dirty = true

	if not _score_particles.is_empty():
		_tick_score_particles(delta)
		dirty = true

	if not _col_rejects.is_empty():
		_tick_col_rejects(delta)
		dirty = true

	if not _col_flashes.is_empty():
		_tick_col_flashes(delta)
		dirty = true

	if _ai_preview_col >= 0:
		_ai_preview_elapsed += delta
		if _ai_preview_elapsed >= _ai_preview_duration:
			_ai_preview_col = -1
		dirty = true

	for i in range(_popups.size() - 1, -1, -1):
		var p: _Popup = _popups[i]
		p.elapsed += delta
		p.pos.y -= 50.0 * delta
		if p.elapsed >= _POPUP_DUR:
			_popups.remove_at(i)
		dirty = true

	if _shake_remaining > 0.0:
		_shake_remaining -= delta
		if _shake_remaining <= 0.0:
			shake_offset = Vector2.ZERO
			_shake_remaining = 0.0
		elif shake_enabled:
			var frac := _shake_remaining / _shake_total
			shake_offset = Vector2(
				randf_range(-_shake_intensity * frac, _shake_intensity * frac),
				randf_range(-_shake_intensity * frac, _shake_intensity * frac)
			)
		dirty = true

	if _combo_active:
		_combo_elapsed += delta
		if _combo_elapsed >= _COMBO_IN + _COMBO_HOLD + _COMBO_OUT:
			_combo_active = false
		dirty = true

	if dirty:
		queue_redraw()


func _tick_drop(delta: float) -> void:
	match _drop_phase:
		0:  # accelerating fall
			_drop_vel += _DROP_ACCEL * delta
			_drop_y += _drop_vel * delta
			if _drop_y >= _drop_target_y:
				_drop_y = _drop_target_y
				_drop_phase = 1
				_drop_phase_t = 0.0
				_spawn_landing_burst(_drop_burst_rect, _drop_burst_owner)
		1:  # squash on impact
			_drop_phase_t = minf(_drop_phase_t + delta / _SQUASH_DUR, 1.0)
			_drop_scale_y = lerp(1.0, 0.65, _drop_phase_t)
			if _drop_phase_t >= 1.0:
				_drop_phase = 2
				_drop_phase_t = 0.0
		2:  # bounce up — ease out so it decelerates at the top
			_drop_phase_t = minf(_drop_phase_t + delta / _BOUNCE_UP_DUR, 1.0)
			var t_up := 1.0 - (1.0 - _drop_phase_t) * (1.0 - _drop_phase_t)
			_drop_y = lerp(_drop_landing_y, _drop_landing_y - _drop_cs * _BOUNCE_HEIGHT_FRAC, t_up)
			_drop_scale_y = lerp(0.65, 1.15, _drop_phase_t)
			if _drop_phase_t >= 1.0:
				_drop_phase = 3
				_drop_phase_t = 0.0
		3:  # bounce down — ease in so it accelerates back down
			_drop_phase_t = minf(_drop_phase_t + delta / _BOUNCE_DOWN_DUR, 1.0)
			var t_down := _drop_phase_t * _drop_phase_t
			_drop_y = lerp(_drop_landing_y - _drop_cs * _BOUNCE_HEIGHT_FRAC, _drop_landing_y, t_down)
			_drop_scale_y = lerp(1.15, 0.9, _drop_phase_t)
			if _drop_phase_t >= 1.0:
				_drop_phase = 4
				_drop_phase_t = 0.0
		4:  # settle
			_drop_phase_t = minf(_drop_phase_t + delta / _SETTLE_DUR, 1.0)
			_drop_scale_y = lerp(0.9, 1.0, _drop_phase_t)
			if _drop_phase_t >= 1.0:
				_drop_active = false
				_drop_done.emit()


func _tick_grav(delta: float) -> void:
	var all_done := true
	for gp: _GravPiece in _grav_pieces:
		if not is_equal_approx(gp.cur_y, gp.to_y):
			gp.cur_y = move_toward(gp.cur_y, gp.to_y, _GRAV_SPEED * delta)
			all_done = false
	if all_done:
		_grav_active = false
		_grav_pieces.clear()
		_grav_done.emit()


func _tick_clear(delta: float) -> void:
	if _clear_phase == -1:
		_clear_t = minf(_clear_t + delta / _SWEEP_DUR, 1.0)
		if _clear_t >= 1.0:
			_clear_phase = 0
			_clear_t = 0.0
	elif _clear_phase == 0:
		_clear_t = minf(_clear_t + delta / _FLASH_DUR, 1.0)
		if _clear_t >= 1.0:
			_clear_phase = 1
			_clear_t = 0.0
	else:
		_clear_t = minf(_clear_t + delta / _CONTRACT_DUR, 1.0)
		if _clear_t >= 1.0:
			_clear_active = false
			_clear_done.emit()


func _tick_bursts(delta: float) -> void:
	for i in range(_burst_dots.size() - 1, -1, -1):
		var d: _BurstDot = _burst_dots[i]
		d.elapsed += delta
		d.pos += d.vel * delta
		d.vel *= 0.85
		if d.elapsed >= _BURST_DUR:
			_burst_dots.remove_at(i)


func _tick_score_particles(delta: float) -> void:
	for i in range(_score_particles.size() - 1, -1, -1):
		var p: _ScoreParticle = _score_particles[i]
		p.elapsed += delta
		if p.elapsed >= _SCORE_EXPLODE_DUR + _SCORE_SEEK_DUR:
			_score_particles.remove_at(i)
			continue
		if p.elapsed < _SCORE_EXPLODE_DUR:
			p.vel *= 0.92
			p.pos += p.vel * delta
		else:
			if not p.seeking:
				p.seek_start = p.pos
				p.seeking = true
			var seek_frac := (p.elapsed - _SCORE_EXPLODE_DUR) / _SCORE_SEEK_DUR
			var t := seek_frac * seek_frac  # quadratic ease-in: slow start, fast arrival
			p.pos = p.seek_start.lerp(p.target, t)


func _tick_col_rejects(delta: float) -> void:
	var to_remove: Array = []
	for col: int in _col_rejects:
		_col_rejects[col] += delta
		if _col_rejects[col] >= _COL_REJECT_DUR:
			to_remove.append(col)
	for col in to_remove:
		_col_rejects.erase(col)


func _tick_col_flashes(delta: float) -> void:
	var to_remove: Array = []
	for col: int in _col_flashes:
		_col_flashes[col] += delta
		if _col_flashes[col] >= _COL_FLASH_DUR:
			to_remove.append(col)
	for col in to_remove:
		_col_flashes.erase(col)


func _draw() -> void:
	if renderer == null:
		return
	_draw_ai_preview()
	_draw_col_rejects()
	_draw_col_flashes()
	_draw_clear_anim()
	_draw_grav()
	_draw_drop_anim()
	_draw_bursts()
	_draw_score_particles()
	_draw_popups()
	_draw_combo_text()


func _draw_ai_preview() -> void:
	if _ai_preview_col < 0 or renderer == null or renderer.layout == null:
		return
	var step := renderer.layout.cell_size + LayoutManager.CELL_GAP
	var board := renderer.layout.board_origin
	var h := RenderState.ROWS * renderer.layout.cell_size + (RenderState.ROWS - 1) * LayoutManager.CELL_GAP
	var col_x := board.x + _ai_preview_col * step
	var pulse := 0.5 + 0.5 * sin(_ai_preview_elapsed * _AI_PREVIEW_PULSE)
	var rect := Rect2(col_x + shake_offset.x, board.y + shake_offset.y, renderer.layout.cell_size, h)
	draw_rect(rect, Color(1.0, 0.9, 0.2, 0.18 * pulse))


func _draw_col_rejects() -> void:
	if renderer == null or renderer.layout == null:
		return
	var step := renderer.layout.cell_size + LayoutManager.CELL_GAP
	var board := renderer.layout.board_origin
	var h := RenderState.ROWS * renderer.layout.cell_size + (RenderState.ROWS - 1) * LayoutManager.CELL_GAP
	for col: int in _col_rejects:
		var t: float = _col_rejects[col] / _COL_REJECT_DUR
		var shake_x := sin(t * TAU * 3.0) * 4.0 * (1.0 - t)
		var col_x := board.x + col * step + shake_x + shake_offset.x
		var rect := Rect2(col_x, board.y + shake_offset.y, renderer.layout.cell_size, h)
		draw_rect(rect, Color(1.0, 0.1, 0.1, 0.25 * (1.0 - t)))


func _draw_col_flashes() -> void:
	if renderer == null or renderer.layout == null:
		return
	var step := renderer.layout.cell_size + LayoutManager.CELL_GAP
	var board := renderer.layout.board_origin
	var h := RenderState.ROWS * renderer.layout.cell_size + (RenderState.ROWS - 1) * LayoutManager.CELL_GAP
	for col: int in _col_flashes:
		var t: float = _col_flashes[col] / _COL_FLASH_DUR
		var col_x := board.x + col * step + shake_offset.x
		var rect := Rect2(col_x, board.y + shake_offset.y, renderer.layout.cell_size, h)
		draw_rect(rect, Color(1.0, 1.0, 1.0, 0.5 * (1.0 - t)))


func _draw_clear_anim() -> void:
	if not _clear_active:
		return
	if _clear_phase == -1:
		var line_color := Color(1.0, 1.0, 1.0, 0.9 * _clear_t)
		var a := _clear_sweep_a + shake_offset
		var progress_b := _clear_sweep_a.lerp(_clear_sweep_b, _clear_t) + shake_offset
		draw_line(a, progress_b, line_color, 3.0)
		return
	for rect: Rect2 in _clear_rects:
		var shifted := Rect2(rect.position + shake_offset, rect.size)
		if _clear_phase == 0:
			draw_rect(shifted, Color(1.0, 1.0, 1.0, 0.75 - _clear_t * 0.35))
		else:
			var s := 1.0 - _clear_t
			draw_circle(shifted.get_center(), rect.size.x * 0.42 * s, Color(1.0, 1.0, 1.0, s * 0.9))


func _draw_grav() -> void:
	if not _grav_active or renderer == null:
		return
	for gp: _GravPiece in _grav_pieces:
		var center := Vector2(gp.x + gp.cs * 0.5, gp.cur_y + gp.cs * 0.5) + shake_offset
		var radius := gp.cs * 0.42
		var color: Color = renderer.theme.color_player \
			if gp.occupant == CellState.Occupant.PLAYER else renderer.theme.color_ai
		draw_circle(center, radius, color)
		if gp.occupant == CellState.Occupant.AI:
			var dot_size := gp.cs * 0.15
			draw_rect(Rect2(center - Vector2(dot_size, dot_size) * 0.5, Vector2(dot_size, dot_size)), Color.WHITE)


func _draw_drop_anim() -> void:
	if not _drop_active:
		return
	var color: Color = renderer.theme.color_player \
		if _drop_owner == CellState.Occupant.PLAYER else renderer.theme.color_ai
	var center := Vector2(_drop_x + _drop_cs * 0.5, _drop_y + _drop_cs * 0.5) + shake_offset
	var radius := _drop_cs * 0.42

	# Piece trail during fall — spacing scales with velocity
	if _drop_phase == 0 and not reduced_motion:
		var trail_spacing := clampf(_drop_vel / 60.0, 8.0, 32.0)
		for i in 2:
			var trail_alpha := 0.45 - i * 0.2
			draw_circle(center - Vector2(0.0, (i + 1) * trail_spacing), radius * 0.9, Color(color.r, color.g, color.b, trail_alpha))

	draw_set_transform(center, 0.0, Vector2(1.0, _drop_scale_y))
	draw_circle(Vector2.ZERO, radius, color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_bursts() -> void:
	for d: _BurstDot in _burst_dots:
		var alpha := clampf(1.0 - d.elapsed / _BURST_DUR, 0.0, 1.0)
		draw_circle(d.pos + shake_offset, 3.0 * alpha, Color(d.color.r, d.color.g, d.color.b, alpha))


func _draw_score_particles() -> void:
	for p: _ScoreParticle in _score_particles:
		var alpha: float
		var radius: float
		if p.elapsed < _SCORE_EXPLODE_DUR:
			radius = 10.0
			alpha = 1.0
		else:
			var seek_frac := (p.elapsed - _SCORE_EXPLODE_DUR) / _SCORE_SEEK_DUR
			radius = lerpf(10.0, 3.0, seek_frac)
			alpha = 1.0 if seek_frac < 0.7 else lerpf(1.0, 0.0, (seek_frac - 0.7) / 0.3)
		draw_circle(p.pos + shake_offset, radius, Color(p.color.r, p.color.g, p.color.b, alpha))


func _draw_popups() -> void:
	if renderer == null or renderer.layout == null:
		return
	var font := ThemeDB.fallback_font
	var font_size := int(renderer.layout.cell_size * 0.9)
	for p: _Popup in _popups:
		var alpha := clampf(1.0 - p.elapsed / _POPUP_DUR, 0.0, 1.0)
		var jitter := sin(p.elapsed * 80.0) * 6.0 * clampf(1.0 - p.elapsed / (_POPUP_DUR * 0.35), 0.0, 1.0)
		var pos := p.pos + shake_offset + Vector2(jitter, 0.0)
		draw_string(font, pos + Vector2(2.0, 2.0), p.text, HORIZONTAL_ALIGNMENT_LEFT, -1,
			font_size, Color(0.0, 0.0, 0.0, alpha * 0.7))
		draw_string(font, pos, p.text, HORIZONTAL_ALIGNMENT_LEFT, -1,
			font_size, Color(p.color.r, p.color.g, p.color.b, alpha))


func _draw_combo_text() -> void:
	if not _combo_active or renderer == null or renderer.layout == null:
		return
	var alpha := _combo_alpha()
	if alpha <= 0.0:
		return
	var font := ThemeDB.fallback_font
	var font_size := int(renderer.layout.cell_size * 1.1)
	var text_w := font.get_string_size(_combo_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var step := renderer.layout.cell_size + LayoutManager.CELL_GAP
	var bx := renderer.layout.board_origin.x
	var bw := (RenderState.COLS - 1) * step + renderer.layout.cell_size
	var by := renderer.layout.board_origin.y
	var bh := (RenderState.ROWS - 1) * step + renderer.layout.cell_size
	var pos := Vector2(bx + (bw - text_w) * 0.5, by + bh * 0.5) + shake_offset
	draw_string(font, pos + Vector2(2.0, 2.0), _combo_text, HORIZONTAL_ALIGNMENT_LEFT, -1,
		font_size, Color(0.0, 0.0, 0.0, alpha * 0.7))
	draw_string(font, pos, _combo_text, HORIZONTAL_ALIGNMENT_LEFT, -1,
		font_size, Color(1.0, 0.9, 0.3, alpha))


func _combo_alpha() -> float:
	if _combo_elapsed < _COMBO_IN:
		return _combo_elapsed / _COMBO_IN
	var hold_end := _COMBO_IN + _COMBO_HOLD
	if _combo_elapsed < hold_end:
		return 1.0
	return clampf(1.0 - (_combo_elapsed - hold_end) / _COMBO_OUT, 0.0, 1.0)


# ---- Public API ----

func play_drop(col: int, landing_row: int, owner: CellState.Occupant, gravity_flipped: bool) -> void:
	if reduced_motion or renderer == null or renderer.layout == null:
		return
	var target_rect := renderer.cell_rect(col, landing_row, gravity_flipped)
	var cs := renderer.layout.cell_size
	var step := cs + LayoutManager.CELL_GAP
	_drop_x = renderer.layout.board_origin.x + col * step
	_drop_y = renderer.layout.board_origin.y - step
	_drop_target_y = target_rect.position.y
	_drop_landing_y = target_rect.position.y
	_drop_vel = _DROP_START_VEL
	_drop_burst_rect = target_rect
	_drop_burst_owner = owner
	_drop_cs = cs
	_drop_owner = owner
	_drop_phase = 0
	_drop_phase_t = 0.0
	_drop_scale_y = 1.0
	_drop_active = true
	queue_redraw()
	await _drop_done


func play_gravity(moves: Array, gravity_flipped: bool) -> void:
	if reduced_motion or moves.is_empty() or renderer == null or renderer.layout == null:
		return
	_grav_pieces.clear()
	for m: Dictionary in moves:
		var from_rect := renderer.cell_rect(m.col, m.from_row, gravity_flipped)
		var to_rect := renderer.cell_rect(m.col, m.to_row, gravity_flipped)
		var gp := _GravPiece.new()
		gp.x = from_rect.position.x
		gp.from_y = from_rect.position.y
		gp.to_y = to_rect.position.y
		gp.cur_y = from_rect.position.y
		gp.cs = renderer.layout.cell_size
		gp.occupant = m.occupant
		gp.piece_type = m.piece_type
		_grav_pieces.append(gp)
	if _grav_pieces.is_empty():
		return
	_grav_active = true
	queue_redraw()
	await _grav_done


func play_clear(cells: Array[Vector2i], gravity_flipped: bool) -> void:
	if reduced_motion or cells.is_empty() or renderer == null or renderer.layout == null:
		return
	_clear_rects.clear()
	var min_pos := Vector2(INF, INF)
	var max_pos := Vector2(-INF, -INF)
	for cell in cells:
		var r := renderer.cell_rect(cell.x, cell.y, gravity_flipped)
		_clear_rects.append(r)
		var c := r.get_center()
		if c.x < min_pos.x: min_pos.x = c.x
		if c.y < min_pos.y: min_pos.y = c.y
		if c.x > max_pos.x: max_pos.x = c.x
		if c.y > max_pos.y: max_pos.y = c.y
	_clear_sweep_a = min_pos
	_clear_sweep_b = max_pos
	_clear_phase = -1
	_clear_t = 0.0
	_clear_active = true
	queue_redraw()
	await _clear_done


func spawn_popup(pos: Vector2, text: String, color: Color = Color(1.0, 0.95, 0.3)) -> void:
	var p := _Popup.new()
	p.text = text
	p.pos = pos
	p.elapsed = 0.0
	p.color = color
	_popups.append(p)


func spawn_chip_popup(pos: Vector2) -> void:
	spawn_popup(pos, "+1 chip", Color(0.3, 1.0, 0.5))


func play_shake(intensity_px: float, duration_frames: int) -> void:
	if not shake_enabled:
		return
	if intensity_px >= _shake_intensity or _shake_remaining <= 0.0:
		var dur := duration_frames / 60.0
		_shake_intensity = intensity_px
		_shake_total = dur
		_shake_remaining = dur


func play_combo_text(cascade_depth: int) -> void:
	if cascade_depth < 2:
		return
	match cascade_depth:
		2:
			_combo_text = "COMBO"
		3:
			_combo_text = "CHAIN"
		_:
			_combo_text = "CASCADE"
	_combo_elapsed = 0.0
	_combo_active = true


func play_col_reject(col: int) -> void:
	_col_rejects[col] = 0.0


func play_col_flash(col: int) -> void:
	_col_flashes[col] = 0.0


func play_ai_preview(col: int, duration: float) -> void:
	_ai_preview_col = col
	_ai_preview_elapsed = 0.0
	_ai_preview_duration = duration


func stop_ai_preview() -> void:
	_ai_preview_col = -1


func spawn_score_particles(world_pos: Vector2, owner: CellState.Occupant, target: Vector2, count: int = 10) -> void:
	if reduced_motion or renderer == null:
		return
	var color: Color = renderer.theme.color_player \
		if owner == CellState.Occupant.PLAYER else renderer.theme.color_ai
	for i in count:
		var angle := i * TAU / count + randf_range(-0.4, 0.4)
		var speed := randf_range(150.0, 320.0)
		var p := _ScoreParticle.new()
		p.pos = world_pos
		p.vel = Vector2(cos(angle), sin(angle)) * speed
		p.elapsed = 0.0
		p.color = color
		p.target = target
		_score_particles.append(p)


func _spawn_landing_burst(rect: Rect2, owner: CellState.Occupant) -> void:
	if reduced_motion or renderer == null:
		return
	var center := rect.get_center() + shake_offset
	var burst_color: Color = renderer.theme.color_player \
		if owner == CellState.Occupant.PLAYER else renderer.theme.color_ai
	for i in 5:
		var angle := i * TAU / 5.0 + randf_range(-0.3, 0.3)
		var speed := randf_range(60.0, 130.0)
		var d := _BurstDot.new()
		d.pos = center
		d.vel = Vector2(cos(angle), sin(angle)) * speed
		d.elapsed = 0.0
		d.color = burst_color
		_burst_dots.append(d)
