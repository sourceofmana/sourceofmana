extends Resource
class_name BaseCell

@export var id : int							= CellCommons.UnknownID
@export var name : String						= "Unknown"
@export var description : String				= ""
@export var icon : Texture2D					= null
@export var type : CellCommons.Type				= CellCommons.Type.ITEM
@export var weight : float						= 1.0
@export var stackable : bool					= false
@export var usable : bool						= false
@export var modifiers : CellModifier			= null

signal used

#
func _init():
	pass

func Use():
	if Network.Client and usable:
		match type:
			CellCommons.Type.ITEM:
				Network.UseItem(id)
			CellCommons.Type.EMOTE:
				Network.TriggerEmote(id)
			CellCommons.Type.SKILL:
				Launcher.Player.Cast(id)
			_:
				assert(false, "Cell type not recognized")
