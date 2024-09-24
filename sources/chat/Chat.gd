extends VBoxContainer
class_name ChatContainer

@onready var tabContainer : TabContainer		= $ChatTabContainer
@onready var lineEdit : LineEdit				= $NewText

@onready var tabInstance : Object				= FileSystem.LoadGui("chat/ChatTab", false)
@onready var backlog : ChatBacklog			= ChatBacklog.new()

var enabledLastFrame : bool						= false

#
func AddPlayerText(playerName : String, speech : String):
	AddText(playerName + ": " + speech, UICommons.LightTextColor)

func AddSystemText(speech : String):
	AddText(speech, UICommons.TextColor)

func AddText(speech : String, color : Color):
	if tabContainer && tabContainer.get_current_tab_control():
		tabContainer.get_current_tab_control().text += "[color=#" + color.to_html(false) + "]" + speech + "[/color]\n"

func isNewLineEnabled() -> bool:
	return lineEdit.is_visible() and lineEdit.has_focus() if lineEdit else false

func SetNewLineEnabled(enable : bool):
	if lineEdit and not enabledLastFrame:
		enabledLastFrame = true
		if not LauncherCommons.isMobile:
			lineEdit.set_visible(enable)
			Launcher.Action.Enable(!enable)
		if enable:
			lineEdit.grab_focus()

#
func OnNewTextSubmitted(newText : String):
	if lineEdit:
		if newText.is_empty() == false:
			lineEdit.clear()
			if Launcher.Player:
				backlog.Add(newText)
				Launcher.Network.TriggerChat(newText)
				SetNewLineEnabled(false)
		else:
			SetNewLineEnabled(false)

#
func _input(event : InputEvent):
	if isNewLineEnabled():
		if Launcher.Action.TryJustPressed(event, "ui_cancel", true):
			SetNewLineEnabled(false)
		elif Launcher.Action.TryJustPressed(event, "ui_up", true):
			backlog.Up()
			lineEdit.text = backlog.Get()
		elif Launcher.Action.TryJustPressed(event, "ui_down", true):
			backlog.Down()
			lineEdit.text = backlog.Get()
		elif Launcher.Action.TryJustPressed(event, "ui_validate", true):
			OnNewTextSubmitted(lineEdit.text)

func _physics_process(_delta):
	if enabledLastFrame:
		enabledLastFrame = false

func _ready():
	assert(tabContainer && tabInstance, "TabContainer or TabInstance not correctly set")
	if tabContainer && tabInstance:
		var newTab : RichTextLabel = tabInstance.instantiate()
		newTab.set_name("General")
		tabContainer.add_child(newTab)

		AddSystemText("Welcome to " + LauncherCommons.ProjectName)
		SetNewLineEnabled(false)
