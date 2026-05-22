class_name MatchRelicDisplay extends VBoxContainer

const _ENTRY_SCENE := preload("res://scenes/game/match_relic_entry.tscn")

@export var grid_columns: int = 4

@onready var _grid: GridContainer = %Grid
@onready var _empty_label: Label = %EmptyLabel


func _ready() -> void:
	_grid.columns = grid_columns
	var title := get_node_or_null("SectionTitle") as Label
	if title != null:
		UITheme.style_label_primary(title, true)
		title.add_theme_font_size_override("font_size", 8)
		title.add_theme_constant_override("outline_size", 0)
	UITheme.style_label_muted(_empty_label, true)


func refresh(relic_manager: RelicManager) -> void:
	for child in _grid.get_children():
		if child is MatchRelicEntry:
			GameTooltip.unbind(child)
		child.queue_free()
	var ids: Array[String] = []
	if relic_manager != null:
		for relic_id in relic_manager.get_owned_relic_ids():
			ids.append(relic_id)
	_empty_label.visible = ids.is_empty()
	_grid.visible = not ids.is_empty()
	for relic_id in ids:
		var entry: MatchRelicEntry = _ENTRY_SCENE.instantiate()
		_grid.add_child(entry)
		entry.setup(relic_id)
