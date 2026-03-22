@tool
extends BaseCell
class_name ItemCell

@export var slot : ActorCommons.Slot			= ActorCommons.Slot.NONE
@export var textures : Array[Texture2D]			= []
@export var shader : Resource					= null
@export var customfield : String				= ""
@export var animationOverrides : AnimationLibrary	= null
@export var spriteHframes : int				= 0
@export var spriteVframes : int				= 0

#
func Use():
	if usable:
		super.Use()
	elif slot >= ActorCommons.Slot.FIRST_EQUIPMENT and slot < ActorCommons.Slot.LAST_EQUIPMENT and Launcher.Player and Launcher.Player.inventory:
		var equipmentCell : ItemCell = Launcher.Player.inventory.equipment[slot]
		if CellCommons.IsSameCell(self, equipmentCell):
			Network.UnequipItem(id, customfield)
		else:
			Network.EquipItem(id, customfield)

#
func _init():
	super._init()
	if slot >= ActorCommons.Slot.FIRST_EQUIPMENT and slot < ActorCommons.Slot.LAST_EQUIPMENT:
		textures.resize(ActorCommons.Gender.COUNT)
