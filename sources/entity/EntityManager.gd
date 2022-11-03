extends Node
class_name EntityManager

#
var Trait : Node				= null
var playerEntity : BaseEntity	= null

#
func _init():
	Trait = Launcher.FileSystem.LoadSource("entity/components/Trait.gd")
