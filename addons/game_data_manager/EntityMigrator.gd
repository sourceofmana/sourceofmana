@tool
extends Control

@onready var migrateButton : Button = $VBoxContainer/MigrateButton
@onready var statusLabel : Label = $VBoxContainer/StatusLabel
@onready var progressBar : ProgressBar = $VBoxContainer/ProgressBar
@onready var logText : TextEdit = $VBoxContainer/LogText

const ENTITIES_JSON_PATH : String = Path.DBRsc + "entities.json"

func _ready():
	if not GameDataUtil.is_part_of_edited_scene(self):
		CheckMigrationStatus()

func CheckMigrationStatus():
	if not FileAccess.file_exists(ENTITIES_JSON_PATH):
		statusLabel.text = "entities.json not found!"
		migrateButton.disabled = true
		return

	if not DirAccess.dir_exists_absolute(Path.EntityPst):
		statusLabel.text = "Ready to migrate entities from JSON to .tres files"
		migrateButton.disabled = false
	else:
		var count : int = CountTresFiles(Path.EntityPst)
		statusLabel.text = "Found %d entity .tres files. Click to re-migrate." % count
		migrateButton.disabled = false

func CountTresFiles(path : String) -> int:
	var files : PackedStringArray = FileSystem.ParseResources(path)
	return files.size()

func _on_migrate_pressed():
	logText.clear()
	migrateButton.disabled = true
	progressBar.value = 0

	if DB.ItemsDB.is_empty() or DB.SkillsDB.is_empty():
		DB.Init()

	var jsonContent : FileAccess = FileAccess.open(ENTITIES_JSON_PATH, FileAccess.READ)
	if not jsonContent:
		print("ERROR: Failed to open entities.json")
		statusLabel.text = "Migration failed!"
		migrateButton.disabled = false
		return

	var jsonParser : JSON = JSON.new()
	var parseResult : Error = jsonParser.parse(jsonContent.get_as_text())
	jsonContent.close()

	if parseResult != OK:
		print("ERROR: Failed to parse entities.json: " + jsonParser.get_error_message())
		statusLabel.text = "Migration failed!"
		migrateButton.disabled = false
		return

	var entitiesData : Variant = jsonParser.data
	if not entitiesData is Dictionary:
		print("ERROR: entities.json is not a dictionary")
		statusLabel.text = "Migration failed!"
		migrateButton.disabled = false
		return

	if not DirAccess.dir_exists_absolute(Path.EntityPst):
		DirAccess.make_dir_recursive_absolute(Path.EntityPst)

	var total : int = entitiesData.size()
	var current : int = 0
	var migrated : int = 0
	var failed : int = 0

	var entityMap : Dictionary = {}
	var parentEntities : Array[String] = []
	for key in entitiesData.keys():
		var entityJson : Dictionary = entitiesData[key]
		if not "Parent" in entityJson:
			var entity : EntityData = CreateEntityFromJson(entityJson, null)
			if entity:
				parentEntities.append(entityJson.Name)
				entityMap[entityJson.Name] = entity

				var filename : String = entityJson.Name + Path.RscExt
				var filepath : String = Path.EntityPst.path_join(filename)
				var saveError : Error = ResourceSaver.save(entity, filepath)
				if saveError == OK:
					migrated += 1
				else:
					print("✗ Failed to save parent: " + entityJson.Name)
					failed += 1
				current += 1

	for key in entitiesData.keys():
		var entityJson : Dictionary = entitiesData[key]

		if "Parent" in entityJson:
			var parentName : String = entityJson.Parent
			var parentEntity : EntityData = null

			var parentFilename : String = parentName + Path.RscExt
			var parentFilepath : String = Path.EntityPst.path_join(parentFilename)
			if FileAccess.file_exists(parentFilepath):
				parentEntity = load(parentFilepath)
				if not parentEntity:
					print("WARNING: Failed to load parent '%s' for entity '%s'" % [parentName, entityJson.get("Name", "Unknown")])
			else:
				print("WARNING: Parent file not found '%s' for entity '%s'" % [parentFilename, entityJson.get("Name", "Unknown")])

			var entity : EntityData = CreateEntityFromJson(entityJson, parentEntity)
			if entity:
				entityMap[entityJson.Name] = entity

	for entityName in entityMap.keys():
		if entityName in parentEntities:
			continue

		progressBar.value = (float(current) / float(total)) * 100.0

		var entity : EntityData = entityMap[entityName]
		var filename : String = entityName + Path.RscExt
		var filepath : String = Path.EntityPst.path_join(filename)

		var saveError : Error = ResourceSaver.save(entity, filepath)
		if saveError == OK:
			migrated += 1
		else:
			print("✗ Failed to save: " + entityName + " (Error: " + str(saveError) + ")")
			failed += 1
		current += 1

	progressBar.value = 100
	print("")
	print("Migration complete!")
	print("Migrated: %d | Failed: %d | Total: %d" % [migrated, failed, total])
	statusLabel.text = "Migration complete! Migrated %d entities." % migrated
	migrateButton.disabled = false

func CreateEntityFromJson(json : Dictionary, parent : EntityData) -> EntityData:
	var entity : EntityData = EntityData.new()

	if parent:
		entity._parent = parent

	if "Name" in json:
		entity._name = json.Name
		entity._id = json.Name.hash()

	if "SpritePreset" in json:
		var value : String = json.SpritePreset
		if not parent or parent._spritePreset != value:
			entity._spritePreset = value

	if "Collision" in json:
		var value : String = json.Collision
		if not parent or parent._collision != value:
			entity._collision = value

	if "Radius" in json:
		var value : int = clampi(str(json.Radius).to_int(), 0, 64)
		if not parent or parent._radius != value:
			entity._radius = value

	if "DisplayName" in json:
		var value : bool = json.DisplayName
		if not parent or parent._displayName != value:
			entity._displayName = value

	if "Direction" in json:
		var value : ActorCommons.Direction = ActorCommons.Direction.get(json.Direction, ActorCommons.Direction.UNKNOWN)
		if not parent or parent._direction != value:
			entity._direction = value

	if "State" in json:
		var value : ActorCommons.State = ActorCommons.State.get(json.State, ActorCommons.State.UNKNOWN)
		if not parent or parent._state != value:
			entity._state = value

	if "Behaviour" in json:
		var value : int = AICommons.GetBehaviourFlags(json.Behaviour)
		if not parent or parent._behaviour != value:
			entity._behaviour = value

	if "Stat" in json:
		var stats : Dictionary = json.Stat
		for statStr in stats:
			var value : Variant = stats[statStr]
			if statStr in ["race", "hairstyle", "haircolor", "skintone"] and value is int and value == 0:
				continue
			var parentValue : Variant = parent._stats.get(statStr) if parent else null
			if not parent or parentValue != value:
				entity._stats[statStr] = value

	if "Equipment" in json:
		var equipmentList : Array = json.Equipment
		if equipmentList is Array:
			for itemName in equipmentList:
				var itemId : int = itemName.hash()
				if DB.ItemsDB.has(itemId):
					var itemCell : ItemCell = DB.ItemsDB[itemId]
					if itemCell and itemCell.slot != ActorCommons.Slot.NONE:
						while entity._equipment.size() <= itemCell.slot:
							entity._equipment.push_back(null)
						entity._equipment[itemCell.slot] = itemCell

	if "Texture" in json:
		var value : String = json.Texture
		if not parent or parent._customTexture != value:
			entity._customTexture = value

	if "Material" in json:
		var materialName : String = json.Material
		var paletteId : int = materialName.hash()
		if DB.PalettesDB[DB.Palette.SKIN].has(paletteId):
			var paletteData : FileData = DB.GetPalette(DB.Palette.SKIN, paletteId)
			if not parent or parent._customMaterial != paletteData:
				entity._customMaterial = paletteData

	if "SkillSet" in json:
		var skillSetData : Dictionary = json.SkillSet
		if skillSetData is Dictionary and not skillSetData.is_empty():
			entity._skillSet = PackedInt64Array()
			entity._skillProba = {}

			for skillName in skillSetData:
				var skillId : int = skillName.hash()
				if DB.SkillsDB.has(skillId):
					entity._skillSet.append(skillId)
					entity._skillProba[skillId] = float(skillSetData[skillName])
				else:
					print("  WARNING: Skill '%s' (ID: %d) not found in DB for entity '%s'" % [skillName, skillId, entity._name])

	if "Drops" in json:
		var drops : Dictionary = json.Drops
		if drops is Dictionary and not drops.is_empty():
			entity._drops = PackedInt64Array()
			entity._dropsProba = {}

			for itemName in drops:
				var itemId : int = itemName.hash()
				if DB.ItemsDB.has(itemId):
					entity._drops.append(itemId)
					entity._dropsProba[itemId] = float(drops[itemName])
				else:
					print("  WARNING: Item '%s' (ID: %d) not found in DB for entity '%s'" % [itemName, itemId, entity._name])

	if "Spawns" in json:
		var spawns : Dictionary = json.Spawns
		for spawnName in spawns:
			entity._spawns[spawnName.hash()] = int(spawns[spawnName])

	if "QuestFilter" in json:
		print("  WARNING: QuestFilter not migrated for " + entity._name + " (requires manual setup)")

	return entity

func print(message : String):
	logText.text += message + "\n"
	print(message)
