extends Node

var Trait : Node			= null

var activePlayer : Node2D	= null
var otherPlayers : Array	= []
var monsters : Array		= []
var npcs : Array			= []

#
func Create(entity : Object) -> Node2D:
	var instanciatedEntity = null
	if entity:
		instanciatedEntity = Launcher.FileSystem.LoadScene("presets/Entity")
		if entity._ethnicity or entity._gender:
			instanciatedEntity.sprite = Launcher.FileSystem.LoadPreset("sprites/" + entity._ethnicity + entity._gender)
			instanciatedEntity.add_child(instanciatedEntity.sprite)
		if entity._animation:
			instanciatedEntity.animation = Launcher.FileSystem.LoadPreset("animations/" + entity._animation)
			var canFetchAnimTree = instanciatedEntity.animation != null && instanciatedEntity.animation.has_node("AnimationTree")
			Launcher.Util.Assert(canFetchAnimTree, "No AnimationTree found")
			if canFetchAnimTree:
				instanciatedEntity.animationTree = instanciatedEntity.animation.get_node("AnimationTree")
			instanciatedEntity.add_child(instanciatedEntity.animation)
		if entity._navigationAgent:
			instanciatedEntity.agent = Launcher.FileSystem.LoadPreset("navigations/" + entity._navigationAgent)
			instanciatedEntity.add_child(instanciatedEntity.agent)
		if entity._camera:
			instanciatedEntity.camera = Launcher.FileSystem.LoadPreset("cameras/" + entity._camera)
			instanciatedEntity.add_child(instanciatedEntity.camera)
		if entity._collision:
			instanciatedEntity.collision = Launcher.FileSystem.LoadPreset("collisions/" + entity._collision)
			instanciatedEntity.add_child(instanciatedEntity.collision)

	return instanciatedEntity

func Spawn(entityID) -> Node2D:
	var instanciatedEntity = null
	for entityDB in Launcher.DB.EntitiesDB:
		var entityRef = Launcher.DB.EntitiesDB[entityDB]
		if entityDB == entityID || entityRef._name == entityID:
			instanciatedEntity = Create(entityRef)

	Launcher.Util.Assert(instanciatedEntity != null, "Could not create the entity: " + entityID)
	return instanciatedEntity

#
func _init():
	Trait = Launcher.FileSystem.LoadSource("entity/Trait.gd")
