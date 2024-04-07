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

func Trigger(idx : int):
	if idx < slots.size():
		slots[idx].UseCell()
