extends Node

#
var Trait : Node			= null
var playerEntity : Node2D	= null

#
func _init():
	Trait = Launcher.FileSystem.LoadSource("entity/Trait.gd")
