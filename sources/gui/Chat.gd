extends VBoxContainer
class_name ChatContainer

@onready var tabContainer : TabContainer		= $ChatTabContainer
@onready var lineEdit : LineEdit				= $NewText

@onready var backlog : ChatBacklog				= ChatBacklog.new()

var channelTabs : Dictionary[String, int]		= {}

#
func AddLocalFeedback(text : String):
	var channelIdx : GUICommons.ChatChannel = GUICommons.ChatChannel.LOCAL
	AddLine(channelIdx, text + "\n", UICommons.TextColor)

func AddPlayerChat(channelName : String, callerName : String, text : String):
	var channelIdx : GUICommons.ChatChannel = GetChannelIndex(channelName)
	if channelIdx == GUICommons.ChatChannel.UNKNOWN:
		return

	AddLine(channelIdx, callerName, UICommons.PlayerNameToColor(callerName))
	AddLine(channelIdx, ": " + text + "\n", UICommons.LightTextColor)

	if channelIdx == GUICommons.ChatChannel.LOCAL:
		var entity : Entity = Entities.GetNamed(callerName)
		if entity and entity.get_parent() and  entity.interactive:
			entity.interactive.DisplaySpeech(text)

func AddSystemChat(channelName : String, text : String):
	var channelIdx : GUICommons.ChatChannel = GetChannelIndex(channelName)
	if channelIdx == GUICommons.ChatChannel.UNKNOWN:
		return

	AddLine(channelIdx, text + "\n", UICommons.TextColor)

func AddLine(channelID : GUICommons.ChatChannel, text : String, color : Color):
	if tabContainer:
		var tab : Control = tabContainer.get_tab_control(channelID)
		if tab and tab is RichTextLabel:
			tab.text += "[color=#" + color.to_html(false) + "]" + text + "[/color]"

#
func GetChannelIndex(channelName : String) -> GUICommons.ChatChannel:
	if not channelTabs.has(channelName):
		return CreateChannel(channelName)
	return channelTabs.get(channelName, GUICommons.ChatChannel.UNKNOWN)

func SetChannelIndex(channelIdx : GUICommons.ChatChannel):
	tabContainer.current_tab = channelIdx

func CreateChannel(channelName : String) -> GUICommons.ChatChannel:
	if channelTabs.has(channelName):
		return channelTabs[channelName] as GUICommons.ChatChannel

	var newTab : Control = FileSystem.LoadGui("labels/ChatLabel")
	newTab.name = channelName

	var channelIdx : GUICommons.ChatChannel = tabContainer.get_tab_count() as GUICommons.ChatChannel
	tabContainer.add_child(newTab)
	channelTabs[channelName] = channelIdx
	tabContainer.current_tab = channelIdx
	return channelIdx

func GetChannelName(channelIdx : int) -> String:
	for channelName in channelTabs:
		if channelTabs[channelName] == channelIdx:
			return channelName
	return "0"

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
					var channelIdx : int = tabContainer.get_current_tab()
					var channelName : String = ""
					if channelIdx < GUICommons.ChatChannel.DEFAULT_CHANNEL_COUNT:
						channelName = str(channelIdx)
					else:
						channelName = GetChannelName(channelIdx)
					Network.TriggerChat(channelName, newText)
		SetNewLineEnabled(false)

#
func OnTabCloseRequested(channelIdx : int):
	if channelIdx < GUICommons.ChatChannel.DEFAULT_CHANNEL_COUNT:
		return

	var channelName : String = GetChannelName(channelIdx)
	if channelName.is_empty():
		return

	var tabControl : Control = tabContainer.get_tab_control(channelIdx)
	if tabControl:
		tabContainer.remove_child(tabControl)
		tabControl.queue_free()

	channelTabs.erase(channelName)
	for channelKey in channelTabs:
		if channelTabs[channelKey] > channelIdx:
			channelTabs[channelKey] -= 1

func OnTabChanged(channelIdx : int):
	var tabBar = tabContainer.get_tab_bar()
	if channelIdx < GUICommons.ChatChannel.DEFAULT_CHANNEL_COUNT:
		tabBar.tab_close_display_policy = TabBar.CLOSE_BUTTON_SHOW_NEVER
		tabBar.drag_to_rearrange_enabled = false
	else:
		tabBar.tab_close_display_policy = TabBar.CLOSE_BUTTON_SHOW_ACTIVE_ONLY
		tabBar.drag_to_rearrange_enabled = true

#
func _ready():
	var tabBar : TabBar = tabContainer.get_tab_bar()
	tabBar.drag_to_rearrange_enabled = false
	tabBar.tab_close_display_policy = TabBar.CLOSE_BUTTON_SHOW_NEVER
	tabBar.tab_close_pressed.connect(OnTabCloseRequested)
	tabContainer.tab_changed.connect(OnTabChanged)

	for channelIdx in GUICommons.ChatChannel.DEFAULT_CHANNEL_COUNT:
		channelTabs[str(channelIdx)] = channelIdx

	AddLocalFeedback("Welcome to " + LauncherCommons.ProjectName)
	SetNewLineEnabled(false)

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

func _on_new_text_editing_toggled(toggled_on):
	Launcher.Action.Enable(!toggled_on)
