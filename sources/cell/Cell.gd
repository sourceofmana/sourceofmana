extends Resource
class_name Cell

@export var name : String
@export var description : String
@export var icon : Texture2D
@export var dyeCMD : PackedColorArray

@export_category("Item Properties")
@export var stackable : bool
@export var weight : float = 1.0
@export var usable : bool


func use():
	pass
