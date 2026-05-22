class_name MatchPiecesPanel extends VBoxContainer

const CURRENT_PREVIEW_SIZE := 32.0
const NEXT_PREVIEW_SIZE := 22.0

@onready var _section_title: Label = %SectionTitle
@onready var _current_label: Label = %CurrentLabel
@onready var _next_label: Label = %NextLabel
@onready var _current_row: MatchPieceRow = %CurrentRow
@onready var _next_block: VBoxContainer = %NextBlock
@onready var _next_row: MatchPieceRow = %NextRow

var renderer: BoardRenderer


func _ready() -> void:
	UITheme.style_label_primary(_section_title, true)
	_section_title.add_theme_font_size_override("font_size", 8)
	_section_title.add_theme_constant_override("outline_size", 0)
	for lbl: Label in [_current_label, _next_label]:
		if lbl != null:
			UITheme.style_label_muted(lbl, true)


func refresh(state: RenderState) -> void:
	if state == null or renderer == null:
		return
	_current_row.setup(state.active_piece, renderer, CURRENT_PREVIEW_SIZE)
	if state.player_queue.is_empty():
		_next_block.visible = false
	else:
		_next_block.visible = true
		_next_row.setup(state.player_queue[0], renderer, NEXT_PREVIEW_SIZE)
