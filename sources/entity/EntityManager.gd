extends Node

var Trait : Node			= null

var activePlayer			= null
var otherPlayers : Array	= []
var monsters : Array		= []
var npcs : Array			= []

func _post_ready():
	Trait = Launcher.FileSystem.LoadSource("entity/Trait.gd")
