extends VBoxContainer
class_name ChatContainer

@onready var tabContainer : TabContainer		= $ChatTabContainer
@onready var lineEdit : LineEdit				= $NewText

@onready var backlog : ChatBacklog				= ChatBacklog.new()

var whisperTabs : Dictionary[String, int]		= {}

#
func AddEntityText(channelID : GUICommons.ChatChannel, entityName : String, speech : String):
	AddText(channelID, entityName, UICommons.PlayerNameToColor(entityName))
	AddText(channelID, ": " + speech + "\n", UICommons.LightTextColor)

func AddSystemText(channelID : GUICommons.ChatChannel, speech : String):
	AddText(channelID, speech + "\n", UICommons.TextColor)

func AddText(channelID : GUICommons.ChatChannel, speech : String, color : Color):
	if tabContainer:
		var tab : Control = tabContainer.get_tab_control(channelID)
		if tab and tab is RichTextLabel:
			tab.text += "[color=#" + color.to_html(false) + "]" + speech + "[/color]"

#
func GetChannelIndex(entityName : String) -> GUICommons.ChatChannel:
	if not whisperTabs.has(entityName):
		OpenWhisperTab(entityName)
	return whisperTabs.get(entityName, GUICommons.ChatChannel.Local)

func OpenWhisperTab(entityName : String):
	if whisperTabs.has(entityName):
		tabContainer.current_tab = whisperTabs[entityName]
		return

	var newTab : Control = FileSystem.LoadGui("labels/ChatLabel")
	newTab.name = entityName

	var tabIdx : GUICommons.ChatChannel = tabContainer.get_tab_count() as GUICommons.ChatChannel
	tabContainer.add_child(newTab)
	whisperTabs[entityName] = tabIdx
	tabContainer.current_tab = tabIdx

func GetWhisperPartner(tabIdx : int) -> String:
	for partnerName in whisperTabs:
		if whisperTabs[partnerName] == tabIdx:
			return partnerName
	return ""

#
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
					var currentTabIdx : int = tabContainer.get_current_tab()
					if currentTabIdx < GUICommons.ChatChannel.DefaultCount:
						Network.TriggerChat(newText, currentTabIdx as GUICommons.ChatChannel)
					else:
						var partnerName : String = GetWhisperPartner(currentTabIdx)
						Network.TriggerWhisper(partnerName, newText)
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

func OnTabCloseRequested(tabIdx : int):
	if tabIdx < GUICommons.ChatChannel.DefaultCount:
		return

	var partnerName : String = GetWhisperPartner(tabIdx)
	if partnerName.is_empty():
		return

	var tabControl : Control = tabContainer.get_tab_control(tabIdx)
	if tabControl:
		tabContainer.remove_child(tabControl)
		tabControl.queue_free()

	whisperTabs.erase(partnerName)
	for partner in whisperTabs:
		if whisperTabs[partner] > tabIdx:
			whisperTabs[partner] -= 1

func OnTabChanged(tabIdx : int):
	var tabBar = tabContainer.get_tab_bar()
	if tabIdx <= GUICommons.ChatChannel.Global:
		tabBar.tab_close_display_policy = TabBar.CLOSE_BUTTON_SHOW_NEVER
		tabBar.drag_to_rearrange_enabled = false
	else:
		tabBar.tab_close_display_policy = TabBar.CLOSE_BUTTON_SHOW_ACTIVE_ONLY
		tabBar.drag_to_rearrange_enabled = true

func _ready():
	var tabBar : TabBar = tabContainer.get_tab_bar()
	tabBar.drag_to_rearrange_enabled = false
	tabBar.tab_close_display_policy = TabBar.CLOSE_BUTTON_SHOW_NEVER
	tabBar.tab_close_pressed.connect(OnTabCloseRequested)
	tabContainer.tab_changed.connect(OnTabChanged)
	AddSystemText(GUICommons.ChatChannel.Local, "Welcome to " + LauncherCommons.ProjectName)
	SetNewLineEnabled(false)

func _on_new_text_editing_toggled(toggled_on):
	Launcher.Action.Enable(!toggled_on)
