class_name MatchPieceRow extends Control

@onready var _preview: PieceQueuePreview = %Preview


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func setup(entry: QueueEntry, board_renderer: BoardRenderer, preview_size: float) -> void:
	var sz := Vector2(preview_size, preview_size)
	custom_minimum_size = sz
	size = sz
	_preview.renderer = board_renderer
	_preview.custom_minimum_size = sz
	_preview.set_entry(entry)
	GameTooltip.unbind(self)
	var text := _tooltip_text(entry)
	if not text.is_empty():
		GameTooltip.bind(self, text)


func _exit_tree() -> void:
	GameTooltip.unbind(self)


func _tooltip_text(entry: QueueEntry) -> String:
	var lines: PackedStringArray = []
	var td: PieceTypeData = PieceVisualUtil.piece_type_data(entry.piece_type)
	if td != null:
		lines.append(td.display_name)
		if not td.description.is_empty():
			lines.append(td.description)
	if not entry.modifier.is_empty():
		if not lines.is_empty():
			lines.append("")
		var md: ModifierData = DataRegistry.get_modifier(entry.modifier)
		if md != null:
			lines.append(md.display_name)
			if not md.description.is_empty():
				lines.append(md.description)
		else:
			lines.append(entry.modifier)
	return "\n".join(lines)
