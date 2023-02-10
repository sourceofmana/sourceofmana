extends Node

# Entity
func FindEntityReference(entityID : String) -> Object:
	var ref : Object = null
	for entityDB in Launcher.DB.EntitiesDB:
		if entityDB == entityID || Launcher.DB.EntitiesDB[entityDB]._name == entityID:
			ref = Launcher.DB.EntitiesDB[entityDB]
			break
	return ref

func CreateEntity(entityType : String, entityID : String, entityName : String = "") -> BaseEntity:
	var inst : BaseEntity = null
	var template = FindEntityReference(entityID)
	if template:
		inst = Launcher.FileSystem.LoadEntity(entityType)
		if inst:
			inst.applyEntityData(template)
			inst.SetName(entityID, entityName)
	Launcher.Util.Assert(inst != null, "Could not create the entity: " + entityID)
	return inst
