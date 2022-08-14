extends Node

var Trait : Node			= null

var activePlayer : Node2D	= null
var otherPlayers : Array	= []
var monsters : Array		= []
var npcs : Array			= []

func _post_ready():
	Trait = Launcher.FileSystem.LoadSource("entity/Trait.gd")
