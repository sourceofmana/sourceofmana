extends BaseCell
class_name ItemCell

@export var slot : ActorCommons.Slot			= ActorCommons.Slot.NONE
@export var textures : Array[Texture2D]			= []
@export var shader : Resource					= null
@export var customfield : String				= ""

#
func Use():
	if usable:
		super.Use()
	elif slot != ActorCommons.Slot.NONE and Launcher.Player and Launcher.Player.inventory:
		if Launcher.Player.inventory.equipments[slot] == self:
			Network.UnequipItem(id, customfield)
		else:
			Network.EquipItem(id, customfield)

#
func _init():
	super._init()
	textures.resize(ActorCommons.Gender.COUNT)
