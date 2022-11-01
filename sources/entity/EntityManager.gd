extends Node
class_name EntityManager

#
var Trait : Node			= null
var playerEntity : Entity	= null

#
func _init():
	Trait = Launcher.FileSystem.LoadSource("entity/Trait.gd")
