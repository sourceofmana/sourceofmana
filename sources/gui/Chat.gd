extends VBoxContainer
class_name ChatContainer

@onready var tabContainer : TabContainer		= $ChatTabContainer
@onready var lineEdit : LineEdit				= $NewText

@onready var tabInstance : Control				= FileSystem.LoadGui("labels/ChatLabel", false)
@onready var backlog : ChatBacklog				= ChatBacklog.new()

var enabledLastFrame : bool						= false

#
func AddPlayerText(playerName : String, speech : String):
	AddText(playerName, UICommons.PlayerNameToColor(playerName))
	AddText(": " + speech + "\n", UICommons.LightTextColor)

func AddSystemText(speech : String):
	AddText(speech + "\n", UICommons.TextColor)

func AddText(speech : String, color : Color):
	if tabContainer && tabContainer.get_current_tab_control():
		tabContainer.get_current_tab_control().text += "[color=#" + color.to_html(false) + "]" + speech + "[/color]"

func isNewLineEnabled() -> bool:
	return lineEdit.is_visible() and lineEdit.has_focus() if lineEdit else false

func SetNewLineEnabled(enable : bool):
	if Launcher.Action and lineEdit and not enabledLastFrame:
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
				Network.TriggerChat(newText)
				SetNewLineEnabled(false)
		else:
			SetNewLineEnabled(false)

#
func _input(event : InputEvent):
	if FSM.IsGameState() and isNewLineEnabled():
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
	AddSystemText("Welcome to " + LauncherCommons.ProjectName)
	SetNewLineEnabled(false)
