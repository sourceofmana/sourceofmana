extends Resource
class_name BaseItem

@export var name : String
@export var description : String
@export var stackable : bool

@export var icon : Texture2D
# later: @export var dyeCMDShaderSteps : 

# weight in grams
@export var weight : float = 1


func use():
	print("use is not implemented")
