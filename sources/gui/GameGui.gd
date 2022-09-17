extends Node

@onready var weightStat		= $FloatingWindows/Inventory/VBoxContainer/Weight/BgTex/Weight

#
func ToggleControl(control : Control):
	if control:
		control.set_visible(!control.is_visible())
		control.SetFloatingWindowToTop()

func UpdatePlayerInfo():
	if Launcher.Entities.activePlayer:
		assert(weightStat, "Stat inventory weight bar is missing")
		if weightStat:
			weightStat.SetStat(Launcher.Entities.activePlayer.stat.weight, Launcher.Entities.activePlayer.stat.maxWeight)

#
func _ready():
	get_tree().set_auto_accept_quit(false)

func _process(_delta):
	UpdatePlayerInfo()

	if Input.is_action_just_pressed(Actions.ACTION_UI_QUIT_GAME): ToggleControl($FloatingWindows/Quit)
	if Input.is_action_just_pressed(Actions.ACTION_UI_INVENTORY): ToggleControl($FloatingWindows/Inventory)
	if Input.is_action_just_pressed(Actions.ACTION_UI_MINIMAP): ToggleControl($FloatingWindows/Minimap)
	if Input.is_action_just_pressed(Actions.ACTION_UI_CHAT): ToggleControl($FloatingWindows/Chat)

func _notification(notif):
	if notif == Node.NOTIFICATION_WM_CLOSE_REQUEST:
		ToggleControl($FloatingWindows/Quit)
	elif notif == Node.NOTIFICATION_WM_MOUSE_EXIT:
		if has_node("FloatingWindows"):
			get_node("FloatingWindows").ClearWindowsModifier()
