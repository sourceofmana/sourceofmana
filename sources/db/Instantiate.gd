extends Node

# Entity
func FindEntityReference(entityID : String) -> Object:
	var ref : Object = null
	for entityDB in Launcher.DB.EntitiesDB:
		if entityDB == entityID || Launcher.DB.EntitiesDB[entityDB]._name == entityID:
			ref = Launcher.DB.EntitiesDB[entityDB]
			break
	return ref

func CreateGenericEntity(entityInstance : CharacterBody2D, entityType : String, entityID : String, entityName : String = ""):
	var template = FindEntityReference(entityID)
	Launcher.Util.Assert(template and entityInstance, "Could not create the entity: %s" % entityID)
	if template and entityInstance:
		entityInstance.SetData(template)
		entityInstance.SetKind(entityType, entityID, entityName)

func CreateEntity(entityType : String, entityID : String, entityName : String = "") -> BaseEntity:
	var entityInstance : BaseEntity = Launcher.FileSystem.LoadEntity(entityType)
	CreateGenericEntity(entityInstance, entityType, entityID, entityName)
	return entityInstance

func CreateAgent(entityType : String, entityID : String, entityName : String = "") -> BaseAgent:
	var entityInstance : BaseAgent = BaseAgent.new()
	CreateGenericEntity(entityInstance, entityType, entityID, entityName)
	return entityInstance
