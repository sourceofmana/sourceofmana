extends Resource
class_name BaseItem


@export_category("Item Metadata")
@export var name : String
@export_multiline var description : String

@export var icon : Texture2D
# later: @export var dyeCMDShaderSteps : 

@export_category("Item Properties")
@export var stackable : bool
# weight in grams
@export var weight : float = 1


func use():
	Launcher.Util.PrintLog("Item use is not yet implemented")
