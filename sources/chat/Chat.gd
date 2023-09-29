extends VBoxContainer
class_name ChatContainer

@onready var tabContainer : TabContainer		= $ChatTabContainer
@onready var lineEdit : LineEdit				= $NewText

@onready var tabInstance : Object				= FileSystem.LoadGui("chat/ChatTab", false)
@onready var chatHistory : ChatHistory			= ChatHistory.new()

var playerColor : Color 						= Color("FFFFDD")
var systemColor : Color 						= Color("EECC77")
var enabledLastFrame : bool						= false

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
	if lineEdit && enabledLastFrame == false:
		lineEdit.set_visible(enable)
		Launcher.Action.Enable(!enable)
		if enable:
			lineEdit.grab_focus()
		else:
			enabledLastFrame = true

#
func OnNewTextSubmitted(newText):
	if lineEdit:
		if newText.is_empty() == false:
			lineEdit.clear()
			if Launcher.Player:
				chatHistory.Add(newText)
				emit_signal('NewTextTyped', newText)
				SetNewLineEnabled(false)
		else:
			SetNewLineEnabled(false)

#
func _process(_deltaTime : float):
	if isNewLineEnabled():
		if Input.is_action_just_pressed("ui_cancel"):
			SetNewLineEnabled(false)
		elif Input.is_action_just_pressed("ui_up"):
			chatHistory.Up()
			lineEdit.text = chatHistory.Get()
		elif Input.is_action_just_pressed("ui_down"):
			chatHistory.Down()
			lineEdit.text = chatHistory.Get()

	if enabledLastFrame:
		enabledLastFrame = false

func _ready():
	Util.Assert(tabContainer && tabInstance, "TabContainer or TabInstance not correctly set")
	if tabContainer && tabInstance:
		var newTab : RichTextLabel = tabInstance.instantiate()
		newTab.set_name("General")
		tabContainer.add_child(newTab)

		AddSystemText("Welcome to " + Launcher.Conf.GetString("Default", "projectName", Launcher.Conf.Type.PROJECT))
