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
			inst.SetData(template)
			inst.SetKind(entityID, entityName)
	Launcher.Util.Assert(inst != null, "Could not create the client entity: " + entityID)
	return inst

func CreateAgent(entityType : String, entityID : String, entityName : String = "") -> BaseAgent:
	var inst : BaseAgent = BaseAgent.new()
	var template = FindEntityReference(entityID)
	if template and inst:
		inst.SetData(template)
		inst.SetKind(entityType, entityID, entityName)
	Launcher.Util.Assert(inst != null, "Could not create the agent entity: " + entityID)
	return inst
