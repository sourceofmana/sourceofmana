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
#		instanciatedEntity.equipment[E_HAIRSTYLE] = entity._hairstyle
		instanciatedEntity.sprite = Launcher.FileSystem.LoadPreset("sprites/" + entity._ethnicity + entity._gender)
		instanciatedEntity.animation = Launcher.FileSystem.LoadPreset("animations/" + entity._animation)
		instanciatedEntity.animationTree = Launcher.FileSystem.LoadPreset("animations/trees/" + entity._animationTree)
		instanciatedEntity.agent = Launcher.FileSystem.LoadPreset("navigations/" + entity._navigationAgent)
		instanciatedEntity.camera = Launcher.FileSystem.LoadPreset("cameras/" + entity._camera)
		instanciatedEntity.collision = Launcher.FileSystem.LoadPreset("collisions/" + entity._collision)

		instanciatedEntity.add_child(instanciatedEntity.sprite)
		instanciatedEntity.add_child(instanciatedEntity.animation)
		instanciatedEntity.add_child(instanciatedEntity.animationTree)
		instanciatedEntity.add_child(instanciatedEntity.agent)
		instanciatedEntity.add_child(instanciatedEntity.camera)
		instanciatedEntity.add_child(instanciatedEntity.collision)

	return instanciatedEntity

func Spawn(entityID) -> Node2D:
	var instanciatedEntity = null
	for entityDB in Launcher.DB.EntitiesDB:
		var entityRef = Launcher.DB.EntitiesDB[entityDB]
		if entityDB == entityID || entityRef._name == entityID:
			instanciatedEntity = Create(entityRef)

	assert(instanciatedEntity != null, "Could not create the entity: " + entityID)
	return instanciatedEntity

#
func _post_ready():
	Trait = Launcher.FileSystem.LoadSource("entity/Trait.gd")
