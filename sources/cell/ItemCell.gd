@tool
extends BaseCell
class_name ItemCell

@export var slot : ActorCommons.Slot			= ActorCommons.Slot.NONE
@export var textures : Array[Texture2D]			= []
@export var shader : Resource					= null
@export var customfield : String				= ""
@export var animationOverrides : AnimationLibrary	= null
@export var spriteHframes : int					= 0
@export var spriteVframes : int					= 0
@export var buyPrice : int						= 0
@export var sellPrice : int						= 0
@export_category("Attack")
@export var attackStyle : ActorCommons.AttackStyle	= ActorCommons.AttackStyle.ONE_HAND
@export var attackSkill : SkillCell				= null
@export var requiredSkillLevel : int			= 0
@export var projectilePreset : PackedScene		= null

#
func StripClient():
	super.StripClient()
	textures = []
	shader = null
	animationOverrides = null
	projectilePreset = null

func Use():
	if usable:
		super.Use()
	elif slot >= ActorCommons.Slot.FIRST_EQUIPMENT and slot < ActorCommons.Slot.LAST_EQUIPMENT and Launcher.Player and Launcher.Player.inventory:
		var equipmentCell : ItemCell = Launcher.Player.inventory.GetEquipmentCell(slot)
		if CellCommons.IsSameCell(self, equipmentCell):
			Network.UnequipItem(id, customfield)
		else:
			var itemIndex : int = Launcher.Player.inventory.FindItemIndex(self)
			Network.EquipItem(id, customfield, itemIndex)

#
func _init():
	super._init()
	if slot >= ActorCommons.Slot.FIRST_EQUIPMENT and slot < ActorCommons.Slot.LAST_EQUIPMENT:
		textures.resize(ActorCommons.Gender.COUNT)
