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

#
func Trigger(idx : int):
	if idx < slots.size():
		slots[idx].UseCell()

func _ready():
	if LauncherCommons.isMobile:
		for label in labels:
			label.set_visible(false)
