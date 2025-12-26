extends Control

@onready var slots : Array[CellTile] = [
	$TouchScreenButton/CellSlot,
	$TouchScreenButton2/CellSlot2,
	$TouchScreenButton3/CellSlot3,
	$TouchScreenButton4/CellSlot4,
	$TouchScreenButton5/CellSlot5,
	$TouchScreenButton6/CellSlot6,
	$TouchScreenButton7/CellSlot7,
	$TouchScreenButton8/CellSlot8,
	$TouchScreenButton9/CellSlot9,
	$TouchScreenButton10/CellSlot10,
]

@onready var labels : Array[Label] = [
	$TouchScreenButton/ButtonLabel,
	$TouchScreenButton2/ButtonLabel,
	$TouchScreenButton3/ButtonLabel,
	$TouchScreenButton4/ButtonLabel,
	$TouchScreenButton5/ButtonLabel,
	$TouchScreenButton6/ButtonLabel,
	$TouchScreenButton7/ButtonLabel,
	$TouchScreenButton8/ButtonLabel,
	$TouchScreenButton9/ButtonLabel,
	$TouchScreenButton10/ButtonLabel,
]

var actionIdxOnHold : int = -1

#
func Trigger(idx : int):
	if actionIdxOnHold == idx:
		if idx >= 0 and idx < slots.size():
			slots[idx].UseCell()
			slots[idx].Hover(false)
		actionIdxOnHold = -1

func Hold(idx : int):
	slots[idx].Hover(true)
	actionIdxOnHold = idx

#
func _ready():
	if LauncherCommons.isMobile:
		for label in labels:
			label.set_visible(false)

func _input(event : InputEvent):
	if Launcher.Action.TryPressed(event, "gp_shortcut_1"):			Hold(0)
	elif Launcher.Action.TryPressed(event, "gp_shortcut_2"):		Hold(1)
	elif Launcher.Action.TryPressed(event, "gp_shortcut_3"):		Hold(2)
	elif Launcher.Action.TryPressed(event, "gp_shortcut_4"):		Hold(3)
	elif Launcher.Action.TryPressed(event, "gp_shortcut_5"):		Hold(4)
	elif Launcher.Action.TryPressed(event, "gp_shortcut_6"):		Hold(5)
	elif Launcher.Action.TryPressed(event, "gp_shortcut_7"):		Hold(6)
	elif Launcher.Action.TryPressed(event, "gp_shortcut_8"):		Hold(7)
	elif Launcher.Action.TryPressed(event, "gp_shortcut_9"):		Hold(8)
	elif Launcher.Action.TryPressed(event, "gp_shortcut_10"):		Hold(9)
	elif Launcher.Action.TryJustReleased(event, "gp_shortcut_1"):	Trigger(0)
	elif Launcher.Action.TryJustReleased(event, "gp_shortcut_2"):	Trigger(1)
	elif Launcher.Action.TryJustReleased(event, "gp_shortcut_3"):	Trigger(2)
	elif Launcher.Action.TryJustReleased(event, "gp_shortcut_4"):	Trigger(3)
	elif Launcher.Action.TryJustReleased(event, "gp_shortcut_5"):	Trigger(4)
	elif Launcher.Action.TryJustReleased(event, "gp_shortcut_6"):	Trigger(5)
	elif Launcher.Action.TryJustReleased(event, "gp_shortcut_7"):	Trigger(6)
	elif Launcher.Action.TryJustReleased(event, "gp_shortcut_8"):	Trigger(7)
	elif Launcher.Action.TryJustReleased(event, "gp_shortcut_9"):	Trigger(8)
	elif Launcher.Action.TryJustReleased(event, "gp_shortcut_10"):	Trigger(9)
