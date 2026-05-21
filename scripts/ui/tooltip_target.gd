class_name TooltipTarget extends Node
## Attach as a child of any Control to show a themed tooltip on hover.
## Text can be set in the inspector or updated from code via `set_text`.

@export_multiline var text: String = ""


func _ready() -> void:
	var parent_ctrl := get_parent()
	if parent_ctrl is Control:
		_apply(parent_ctrl as Control)
	else:
		push_warning("TooltipTarget must be a child of a Control.")


func set_text(new_text: String) -> void:
	text = new_text
	var parent_ctrl := get_parent()
	if parent_ctrl is Control:
		_apply(parent_ctrl as Control)


func _apply(control: Control) -> void:
	if text.is_empty():
		GameTooltip.unbind(control)
	else:
		GameTooltip.bind(control, text)


func _exit_tree() -> void:
	var parent_ctrl := get_parent()
	if parent_ctrl is Control:
		GameTooltip.unbind(parent_ctrl as Control)
