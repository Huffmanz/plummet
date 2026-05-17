class_name AnimLayer extends Node2D

const _FLASH_DUR: float = 2.0 / 60.0
const _CONTRACT_DUR: float = 6.0 / 60.0
const _SQUASH_PHASE_DUR: float = 3.0 / 60.0
const _POPUP_DUR: float = 0.5
const _DROP_SPEED: float = 1400.0
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
var _drop_cs: float = 48.0
var _drop_owner: CellState.Occupant = CellState.Occupant.PLAYER
var _drop_phase: int = 0  # 0=fall 1=squash 2=stretch 3=restore
var _drop_phase_t: float = 0.0
var _drop_scale_y: float = 1.0
signal _drop_done

# --- Clear animation ---
var _clear_active: bool = false
var _clear_rects: Array[Rect2] = []
var _clear_phase: int = 0  # 0=flash 1=contract
var _clear_t: float = 0.0
signal _clear_done

# --- Score popups ---
class _Popup:
	var text: String = ""
	var pos: Vector2 = Vector2.ZERO
	var elapsed: float = 0.0

var _popups: Array = []

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

	if _clear_active:
		_tick_clear(delta)
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
		0:
			_drop_y += _DROP_SPEED * delta
			if _drop_y >= _drop_target_y:
				_drop_y = _drop_target_y
				_drop_phase = 1
				_drop_phase_t = 0.0
		1:
			_drop_phase_t = minf(_drop_phase_t + delta / _SQUASH_PHASE_DUR, 1.0)
			_drop_scale_y = lerp(1.0, 0.6, _drop_phase_t)
			if _drop_phase_t >= 1.0:
				_drop_phase = 2
				_drop_phase_t = 0.0
		2:
			_drop_phase_t = minf(_drop_phase_t + delta / _SQUASH_PHASE_DUR, 1.0)
			_drop_scale_y = lerp(0.6, 1.3, _drop_phase_t)
			if _drop_phase_t >= 1.0:
				_drop_phase = 3
				_drop_phase_t = 0.0
		3:
			_drop_phase_t = minf(_drop_phase_t + delta / _SQUASH_PHASE_DUR, 1.0)
			_drop_scale_y = lerp(1.3, 1.0, _drop_phase_t)
			if _drop_phase_t >= 1.0:
				_drop_active = false
				_drop_done.emit()


func _tick_clear(delta: float) -> void:
	if _clear_phase == 0:
		_clear_t = minf(_clear_t + delta / _FLASH_DUR, 1.0)
		if _clear_t >= 1.0:
			_clear_phase = 1
			_clear_t = 0.0
	else:
		_clear_t = minf(_clear_t + delta / _CONTRACT_DUR, 1.0)
		if _clear_t >= 1.0:
			_clear_active = false
			_clear_done.emit()


func _draw() -> void:
	if renderer == null:
		return
	_draw_clear_anim()
	_draw_drop_anim()
	_draw_popups()
	_draw_combo_text()


func _draw_clear_anim() -> void:
	if not _clear_active:
		return
	for rect: Rect2 in _clear_rects:
		var shifted := Rect2(rect.position + shake_offset, rect.size)
		if _clear_phase == 0:
			draw_rect(shifted, Color(1.0, 1.0, 1.0, 0.75 - _clear_t * 0.35))
		else:
			var s := 1.0 - _clear_t
			draw_circle(shifted.get_center(), rect.size.x * 0.42 * s, Color(1.0, 1.0, 1.0, s * 0.9))


func _draw_drop_anim() -> void:
	if not _drop_active:
		return
	var color: Color = renderer.theme.color_player \
		if _drop_owner == CellState.Occupant.PLAYER else renderer.theme.color_ai
	var center := Vector2(_drop_x + _drop_cs * 0.5, _drop_y + _drop_cs * 0.5) + shake_offset
	var radius := _drop_cs * 0.42
	draw_set_transform(center, 0.0, Vector2(1.0, _drop_scale_y))
	draw_circle(Vector2.ZERO, radius, color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_popups() -> void:
	if renderer == null or renderer.layout == null:
		return
	var font := ThemeDB.fallback_font
	var font_size := int(renderer.layout.cell_size * 0.55)
	for p: _Popup in _popups:
		var alpha := clampf(1.0 - p.elapsed / _POPUP_DUR, 0.0, 1.0)
		var pos := p.pos + shake_offset
		draw_string(font, pos + Vector2(1.5, 1.5), p.text, HORIZONTAL_ALIGNMENT_LEFT, -1,
			font_size, Color(0.0, 0.0, 0.0, alpha * 0.7))
		draw_string(font, pos, p.text, HORIZONTAL_ALIGNMENT_LEFT, -1,
			font_size, Color(1.0, 0.95, 0.3, alpha))


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
	_drop_cs = cs
	_drop_owner = owner
	_drop_phase = 0
	_drop_phase_t = 0.0
	_drop_scale_y = 1.0
	_drop_active = true
	queue_redraw()
	await _drop_done


func play_clear(cells: Array[Vector2i], gravity_flipped: bool) -> void:
	if reduced_motion or cells.is_empty() or renderer == null or renderer.layout == null:
		return
	_clear_rects.clear()
	for cell in cells:
		_clear_rects.append(renderer.cell_rect(cell.x, cell.y, gravity_flipped))
	_clear_phase = 0
	_clear_t = 0.0
	_clear_active = true
	queue_redraw()
	await _clear_done


func spawn_popup(pos: Vector2, text: String) -> void:
	var p := _Popup.new()
	p.text = text
	p.pos = pos
	p.elapsed = 0.0
	_popups.append(p)


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
