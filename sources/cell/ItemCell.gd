extends BaseCell
class_name ItemCell

@export var slot : ActorCommons.Slot			= ActorCommons.Slot.NONE
@export var textures : Array[Texture2D]			= []
@export var shader : Resource					= null

#
func Use():
	if usable:
		super.Use()
	elif slot != ActorCommons.Slot.NONE and Launcher.Player and Launcher.Player.inventory:
		if Launcher.Player.inventory.equipments[slot] == self:
			Network.UnequipItem(id)
		else:
			Network.EquipItem(id)

#
func _init():
	super._init()
	textures.resize(ActorCommons.Gender.COUNT)
