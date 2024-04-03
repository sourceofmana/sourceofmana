extends Resource
class_name BaseCell

@export var name : String						= "Unknown"
@export var description : String				= ""
@export var icon : Texture2D					= null
@export var shader : Resource					= null
@export var type : CellCommons.Type				= CellCommons.Type.ITEM
@export var weight : float						= 1.0
@export var stackable : bool					= false
@export var usable : bool						= false
@export var effects : Dictionary				= {}

#
func Use():
	if Launcher.Network.Client and usable:
		match type:
			CellCommons.Type.ITEM:
				Launcher.Network.UseItem(name)
			CellCommons.Type.EMOTE:
				Launcher.Network.TriggerEmote(name)
			CellCommons.Type.SKILL:
				Launcher.Player.Cast(name)
			_:
				Util.Assert(false, "Cell type not recognized")
