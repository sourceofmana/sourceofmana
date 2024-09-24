extends Resource
class_name BaseCell

@export var id : int							= -1
@export var name : String						= "Unknown"
@export var description : String				= ""
@export var icon : Texture2D					= null
@export var shader : Resource					= null
@export var type : CellCommons.Type				= CellCommons.Type.ITEM
@export var weight : float						= 1.0
@export var stackable : bool					= false
@export var usable : bool						= false
@export var effects : Dictionary				= {}

signal used

#
func Use():
	if Launcher.Network.Client and usable:
		match type:
			CellCommons.Type.ITEM:
				Launcher.Network.UseItem(id)
			CellCommons.Type.EMOTE:
				Launcher.Network.TriggerEmote(id)
			CellCommons.Type.SKILL:
				Launcher.Player.Cast(id)
			_:
				assert(false, "Cell type not recognized")
