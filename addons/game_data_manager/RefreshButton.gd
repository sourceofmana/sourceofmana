@tool
extends Button

func _ready():
	icon = EditorInterface.get_editor_theme().get_icon("Reload", "EditorIcons")

func _on_pressed():
	$"../../ItemList".refresh()
