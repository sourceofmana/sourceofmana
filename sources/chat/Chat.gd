extends VBoxContainer

@onready var tabContainer : TabContainer		= $ChatTabContainer
@onready var lineEdit : LineEdit				= $NewText

var tabInstance : Object						= Launcher.FileSystem.ResourceLoad("res://scenes/gui/Chat/ChatTab.tscn")
var playerColor : Color 						= Color("FFFFDD")
var systemColor : Color 						= Color("EECC77")

signal NewTextTyped(text : String)

#
func AddPlayerText(playerName : String, speech : String):
	AddText(playerName + ": " + speech, playerColor)

func AddSystemText(speech : String):
	AddText(speech, systemColor)

func AddText(speech : String, color : Color):
	if tabContainer && tabContainer.get_current_tab_control():
		tabContainer.get_current_tab_control().text += "[color=#" + color.to_html(false) + "]" + speech + "[/color]\n"

func isNewLineEnabled():
	return lineEdit.is_visible() if lineEdit else false 

func SetNewLineEnabled(enable : bool):
	if lineEdit:
		lineEdit.set_visible(enable)
		if enable:
			lineEdit.grab_focus()

#
func OnNewTextSubmitted(newText):
	if lineEdit:
		if newText.is_empty() == false:
			lineEdit.clear()
			if Launcher.Entities.activePlayer:
				AddPlayerText(Launcher.Entities.activePlayer.entityName, newText)
				emit_signal('NewTextTyped', newText)

#
func _unhandled_input(_event):
	if lineEdit && isNewLineEnabled():
		lineEdit.set_process(true)
		lineEdit.set_process_input(true)
		lineEdit.set_process_internal(true)
		lineEdit.set_process_unhandled_input(true)
		lineEdit.set_process_unhandled_key_input(true)
		lineEdit.set_physics_process(true)
		lineEdit.set_physics_process_internal(true)

func _ready():
	Launcher.Util.Assert(tabContainer && tabInstance, "TabContainer or TabInstance not correctly set")
	if tabContainer && tabInstance:
		var newTab : RichTextLabel = tabInstance.instantiate()
		newTab.set_name("General")
		tabContainer.add_child(newTab)

		AddSystemText("Welcome to Source of Mana")
