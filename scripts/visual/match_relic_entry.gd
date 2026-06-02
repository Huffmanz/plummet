class_name MatchRelicEntry extends PanelContainer

@onready var _icon: ShopOfferVisual = %ShopIcon

var relic_id: String = ""


func setup(id: String) -> void:
	relic_id = id
	var rd: RelicData = DataRegistry.get_relic(id)
	_icon.setup("relic", id, Vector2(22, 22))
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	GameTooltip.unbind(self)
	GameTooltip.bind(self, _tooltip_text(rd, id))


func _exit_tree() -> void:
	GameTooltip.unbind(self)


func _tooltip_text(rd: RelicData, id: String) -> String:
	if rd == null:
		return id
	return "%s\n%s" % [rd.display_name, rd.description]
