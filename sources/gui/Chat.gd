extends VBoxContainer
class_name ChatContainer

@onready var tabContainer : TabContainer		= $ChatTabContainer
@onready var lineEdit : LineEdit				= $NewText

@onready var tabInstance : Control				= FileSystem.LoadGui("labels/ChatLabel", false)
@onready var backlog : ChatBacklog				= ChatBacklog.new()

#
func AddEntityText(channelID : GUICommons.ChatChannel, entityName : String, speech : String):
	AddText(channelID, entityName, UICommons.PlayerNameToColor(entityName))
	AddText(channelID, ": " + speech + "\n", UICommons.LightTextColor)

func AddSystemText(speech : String):
	AddText(GUICommons.ChatChannel.Local, speech + "\n", UICommons.TextColor)

func AddText(channelID : GUICommons.ChatChannel, speech : String, color : Color):
	if tabContainer:
		var tab : Control = tabContainer.get_tab_control(channelID)
		if tab and tab is RichTextLabel:
			tab.text += "[color=#" + color.to_html(false) + "]" + speech + "[/color]"

func isNewLineEnabled() -> bool:
	return lineEdit.is_visible() and lineEdit.has_focus() if lineEdit else false

func SetNewLineEnabled(enable : bool):
	if Launcher.Action and lineEdit:
		if not LauncherCommons.isMobile:
			lineEdit.set_visible(enable)
		if enable:
			lineEdit.grab_focus()

#
func OnNewTextSubmitted(newText : String):
	if lineEdit:
		if newText.is_empty() == false:
			lineEdit.clear()
			if Launcher.Player:
				backlog.Add(newText)
				if newText[0] == "/":
					Network.TriggerCommand(newText.trim_prefix("/"))
				else:
					Network.TriggerChat(newText, tabContainer.get_current_tab())
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
			lineEdit.set_caret_column(lineEdit.text.length())

		elif Launcher.Action.TryJustPressed(event, "ui_down", true):
			backlog.Down()
			lineEdit.text = backlog.Get()
			lineEdit.set_caret_column(lineEdit.text.length())
		elif Launcher.Action.TryJustPressed(event, "ui_validate", true):
			OnNewTextSubmitted(lineEdit.text)

func _ready():
	AddSystemText("Welcome to " + LauncherCommons.ProjectName)
	SetNewLineEnabled(false)

func _on_new_text_editing_toggled(toggled_on):
	Launcher.Action.Enable(!toggled_on)
