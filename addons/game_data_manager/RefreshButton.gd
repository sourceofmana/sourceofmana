@tool
extends Button

func _ready():
	if PluginUtil.is_part_of_edited_scene(self):
		return
	icon = EditorInterface.get_editor_theme().get_icon("Reload", "EditorIcons")

func _on_pressed():
	$"../../ItemList".refresh()
