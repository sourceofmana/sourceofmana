@tool
extends EditorPlugin

#
const MainPanel : Resource = preload("res://addons/game_data_manager/GameData.tscn")

#
var mainPanelInstance : Node = null

#
func _enter_tree():
	mainPanelInstance = MainPanel.instantiate()
	EditorInterface.get_editor_main_screen().add_child(mainPanelInstance)
	_make_visible(false)

func _exit_tree():
	if mainPanelInstance:
		mainPanelInstance.queue_free()

func _has_main_screen():
	return true

func _make_visible(visible : bool):
	if mainPanelInstance:
		mainPanelInstance.visible = visible

func _get_plugin_name():
	return "Game Data"

func _get_plugin_icon():
	return EditorInterface.get_editor_theme().get_icon("Grid", "EditorIcons")
