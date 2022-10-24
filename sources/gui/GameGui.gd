extends Node

@onready var windows : Control					= $FloatingWindows
@onready var weightStat : Control				= $FloatingWindows/Inventory/VBoxContainer/Weight/BgTex/Weight
@onready var itemInventory : GridContainer		= $FloatingWindows/Inventory/VBoxContainer/ItemContainer/Grid
@onready var emoteList : GridContainer			= $FloatingWindows/Emote/ItemContainer/Grid
@onready var chatContainer : Container			= $FloatingWindows/Chat/VBoxContainer

#
func CloseWindow():
	var control : Control = GetCurrentWindow()
	if control && control.has_method("CanBlockActions") && control.CanBlockActions():
		CloseCurrentWindow()
	else:
		ToggleControl($FloatingWindows/Quit)

func GetCurrentWindow():
	if windows && windows.get_child_count() > 0:
		return windows.get_child(windows.get_child_count() - 1)

func CloseCurrentWindow():
	var control : Control = GetCurrentWindow()
	if control:
		ToggleControl(control)

func ToggleControl(control : Control):
	if control:
		control.ToggleControl()

func ToggleChatNewLine(control : Control):
	if control:
		if control.is_visible() == false:
			ToggleControl(control)
		if chatContainer:
			chatContainer.SetNewLineEnabled(!chatContainer.isNewLineEnabled())

func UpdatePlayerInfo():
	if Launcher.Entities.playerEntity:
		assert(weightStat, "Stat inventory weight bar is missing")
		if weightStat:
			weightStat.SetStat(Launcher.Entities.playerEntity.stat.weight, Launcher.Entities.playerEntity.stat.maxWeight)

func PlayerSpawned():
	if Launcher.Entities.playerEntity:
		assert(itemInventory, "Item inventory container is missing")
		if itemInventory:
			itemInventory.FillGridContainer(Launcher.Entities.playerEntity.inventory.items)

	assert(emoteList, "Emote grid container is missing")
	if emoteList:
		emoteList.FillGridContainer(Launcher.DB.EmotesDB)

#
func _ready():
	Launcher.FSM.enter_game.connect(PlayerSpawned)
	get_tree().set_auto_accept_quit(false)

func _process(_delta):
	UpdatePlayerInfo()

	if Launcher.Action.IsActionJustPressed("ui_close", true): CloseWindow()
	if Launcher.Action.IsActionJustPressed("ui_inventory"): ToggleControl($FloatingWindows/Inventory)
	if Launcher.Action.IsActionJustPressed("ui_minimap"): ToggleControl($FloatingWindows/Minimap)
	if Launcher.Action.IsActionJustPressed("ui_chat"): ToggleControl($FloatingWindows/Chat)
	if Launcher.Action.IsActionJustPressed("ui_chat_newline") : ToggleChatNewLine($FloatingWindows/Chat)

func _notification(notif):
	if notif == Node.NOTIFICATION_WM_CLOSE_REQUEST:
		ToggleControl($FloatingWindows/Quit)
	elif notif == Node.NOTIFICATION_WM_MOUSE_EXIT:
		if has_node("FloatingWindows"):
			get_node("FloatingWindows").ClearWindowsModifier()
