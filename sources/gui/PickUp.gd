extends Control

#
@export var modulateInScaler : float	 = 5.0
@export var modulateOutScaler : float	 = 5.0

@onready var container : HBoxContainer	= $HBoxContainer

var way : UICommons.Way					= UICommons.Way.KEEP
var timestampsMs : Array				= []

#
func AddLast(cell : BaseCell, count : int):
	if count > 0 and cell != null:
		visible = true
		way = UICommons.Way.SHOW
		timestampsMs.push_back(Time.get_ticks_msec())
		var tile : CellTile = UICommons.CellTilePreset.instantiate()
		tile.ready.connect(tile.AssignData.bind(cell, count))
		container.add_child.call_deferred(tile)

func RemoveOldest():
	var child : Control = container.get_child(0)
	if child:
		container.remove_child(child)

func RemoveAll():
	for child in container.get_children():
		if child:
			container.remove_child(child)
	timestampsMs.clear()

func TryClearOldest():
	if timestampsMs.size() > 0 and Time.get_ticks_msec() > timestampsMs[0] + UICommons.DelayPickUpNotification:
		# Do not clear the last item yet, it will be cleared once this window will be hidden.
		if timestampsMs.size() > 1:
			RemoveOldest()
		return true
	return false

#
func _physics_process(delta : float):
	match way:
		UICommons.Way.HIDE:
			if modulate.a > 0.0:
				modulate.a = clampf(modulate.a - delta * modulateOutScaler, 0.0, 1.0)
			else:
				RemoveAll()
				way = UICommons.Way.KEEP
				visible = false
		UICommons.Way.KEEP:
			if visible:
				if TryClearOldest():
					timestampsMs.pop_front()
				if timestampsMs.size() == 0:
					way = UICommons.Way.HIDE
		UICommons.Way.SHOW:
			if modulate.a < 1.0:
				modulate.a = clampf(modulate.a + delta * modulateInScaler, 0.0, 1.0)
			else:
				way = UICommons.Way.KEEP

func _ready():
	modulate.a = 0.0
	visible = false
