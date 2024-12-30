extends ServiceBase

#
var db : SQLite						= null
var backups : SQLBackups			= null
var queryMutex : Mutex				= Mutex.new()

# Accounts
func AddAccount(username : String, password : String, email : String) -> bool:
	var results : Array = db.select_rows("account", "username = %s" % username, ["account_id"])
	if results.size() == 0:
		var accountData : Dictionary = {
			"username" : username,
			"password" : password,
			"email" : email,
			"created_timestamp" : SQLCommons.Timestamp()
		}
		return db.insert_row("account", accountData)
	return false

func RemoveAccount(accountID : int) -> bool:
	return db.delete_rows("account", "account_id = %d" % accountID)

func Login(username : String, password : String) -> int:
	var results : Array[Dictionary] = QueryBindings("SELECT account_id FROM account WHERE username = ? AND password = ?;", [username, password])
	assert(results.size() <= 1, "Duplicated account row")
	return results[0]["account_id"] if results.size() > 0 else NetworkCommons.RidUnknown

# Characters
func AddCharacter(accountID : int, nickname : String, traits : Dictionary, attributes : Dictionary) -> bool:
	var charData : Dictionary = {
		"account_id": accountID,
		"nickname": nickname,
		"created_timestamp": SQLCommons.Timestamp()
	}
	var ret : bool = db.insert_row("character", charData)
	if ret:
		var charID : int = GetCharacterID(accountID, nickname)
		ret = ret and db.update_rows("trait", "char_id = %d" % charID, traits)
		ret = ret and db.update_rows("attribute", "char_id = %d" % charID, attributes)
	return ret

func RemoveCharacter(player : BaseAgent) -> bool:
	if player:
		return db.delete_rows("character", "char_id = %d" % player.charID)
	return false

func GetCharacters(accountID : int) -> Array[int]:
	var charIDs : Array[int] = []
	for result in db.select_rows("character", "account_id = %d" % accountID, ["char_id"]):
		charIDs.append(result["char_id"])
	return charIDs

func GetCharacterInfo(charID : int) -> Dictionary:
	var results : Array[Dictionary] = Query("SELECT * \
FROM character \
INNER JOIN stat ON character.char_id = stat.char_id \
INNER JOIN trait ON character.char_id = trait.char_id \
INNER JOIN attribute ON character.char_id = attribute.char_id \
WHERE character.char_id = %d;" % charID)
	assert(results.size() == 1, "Character information tables are missing")
	return results[0] if results.size() > 0 else {}

func CharacterLogout(player : PlayerAgent) -> bool:
	var success : bool = true
	success = success && UpdateAttribute(player.charID, player.stat)
	success = success && UpdateTrait(player.charID, player.stat)
	success = success && UpdateStat(player.charID, player.stat)
	success = success && UpdateCharacter(player)
	return success

# Character
func GetCharacterID(accountID : int, nickname : String) -> int:
	var results : Array[Dictionary] = QueryBindings("SELECT char_id FROM character WHERE account_id = ? AND nickname = ?;", [accountID, nickname])
	assert(results.size() <= 1, "Duplicated character row for account %d and nickname %s" % [accountID, nickname])
	return results[0]["char_id"] if results.size() > 0 else NetworkCommons.RidUnknown

func GetCharacter(charID : int) -> Dictionary:
	var results : Array[Dictionary] = db.select_rows("character", "char_id = %d" % charID, ["*"])
	assert(results.size() <= 1, "Duplicated character row %d" % charID)
	return results[0] if results.size() > 0 else {}

func UpdateCharacter(player : PlayerAgent) -> bool:
	if player == null:
		return false

	var map : WorldMap = WorldAgent.GetMapFromAgent(player)
	var newTimestamp : int = SQLCommons.Timestamp()
	var data : Dictionary = GetCharacter(player.charID)

	data["total_time"] = SQLCommons.GetOrAddValue(data, "total_time", 0) + newTimestamp - SQLCommons.GetOrAddValue(data, "last_timestamp", newTimestamp)
	data["last_timestamp"] = newTimestamp

	if map != null and not map.HasFlags(WorldMap.Flags.NO_REJOIN):
		data["pos_x"] = player.position.x
		data["pos_y"] = player.position.y
		data["pos_map"] = map.name

	if player.respawnDestination != null:
		data["respawn_x"] = player.respawnDestination.pos.x
		data["respawn_y"] = player.respawnDestination.pos.y
		data["respawn_map"] = player.respawnDestination.map

	return db.update_rows("character", "char_id = %d;" % player.charID, data)

# Stats
func GetAttribute(charID : int) -> Dictionary:
	var results : Array[Dictionary] = db.select_rows("attribute", "char_id = %d" % charID, ["*"])
	assert(results.size() == 1, "Character attribute row is missing")
	return results[0] if results.size() > 0 else {}

func UpdateAttribute(charID : int, stats : ActorStats) -> bool:
	if stats == null:
		return false

	var data : Dictionary = {
		"strength" = stats.strength,
		"vitality" = stats.vitality,
		"agility" = stats.agility,
		"endurance" = stats.endurance,
		"concentration" = stats.concentration
	}
	return db.update_rows("attribute", "char_id = %d" % charID, data)

func GetTrait(charID : int) -> Dictionary:
	var results : Array[Dictionary] = db.select_rows("trait", "char_id = %d" % charID, ["*"])
	assert(results.size() == 1, "Character trait row is missing")
	return results[0] if results.size() > 0 else {}

func UpdateTrait(charID : int, stats : ActorStats) -> bool:
	if stats == null:
		return false

	var data : Dictionary = {
		"hairstyle" = stats.hairstyle,
		"haircolor" = stats.haircolor,
		"race" = stats.race,
		"skin" = stats.skin,
		"gender" = stats.gender,
		"shape" = stats.currentShape,
		"spirit" = stats.spirit
	}
	return db.update_rows("trait", "char_id = %d" % charID, data)

func GetStat(charID : int) -> Dictionary:
	var results : Array[Dictionary] = db.select_rows("stat", "char_id = %d" % charID, ["*"])
	assert(results.size() == 1, "Character stat row is missing")
	return results[0] if results.size() > 0 else {}

func UpdateStat(charID : int, stats : ActorStats) -> bool:
	if stats == null:
		return false

	var data : Dictionary = {
		"level" = stats.level,
		"experience" = stats.experience,
		"gp" = stats.gp,
		"health" = stats.health,
		"mana" = stats.mana,
		"stamina" = stats.stamina,
		"karma" = stats.karma
	}
	return db.update_rows("stat", "char_id = %d" % charID, data)

# Inventory
func GetItem(charID : int, itemID : int, storageType : int = 0) -> Dictionary:
	var results : Array[Dictionary] = db.select_rows("item", "item_id = %d AND char_id = %d AND storage = %d" % [itemID, charID, storageType], ["*"])
	assert(results.size() <= 1, "Duplicated item %d on character %d with storage %d" % [itemID, charID, storageType])
	return {} if results.is_empty() else results[0]

func AddItem(charID : int, itemID : int, itemCount : int = 1, storageType : int = 0) -> bool:
	var data : Dictionary = GetItem(charID, itemID, storageType)
	# Increment item count
	if not data.is_empty():
		data["count"] += 1
		return db.update_rows("item", "item_id = %d AND char_id = %d AND storage = %d" % [itemID, charID, storageType], data)

	# Insert new item
	data = {
		"item_id": itemID,
		"char_id": charID,
		"count": itemCount,
		"storage": storageType
	}
	return db.insert_row("item", data)

func RemoveItem(charID : int, itemID : int, storageType : int = 0) -> bool:
	var data : Dictionary = GetItem(charID, itemID, storageType)
	var condition : String = "item_id = %d AND char_id = %d AND storage = %d" % [itemID, charID, storageType]
	if not data.is_empty():
		# Decrement item count
		if data["count"] >= 2:
			data["count"] -= 1
			return db.update_row("item", condition, data)
		# Remove item
		return db.delete_row("item", condition)
	return false

func GetStorage(charID : int, storageType) -> Array[Dictionary]:
	return db.select_rows("item", "char_id = %d AND storage = %d" % [charID, storageType], ["*"])

# Equipment
func GetEquipment(charID : int) -> Dictionary:
	var results : Array[Dictionary] = db.select_rows("equipment", "char_id = %d" % charID, ["*"])
	assert(results.size() <= 1, "Duplicated equipment on character %d" % charID)
	return results[0] if results.size() > 0 else {}

func UpdateEquipment(player : PlayerAgent) -> bool:
	var data : Dictionary = {
		"weapon": 0,
		"shield": 0,
		"ammunition": 0,
		"arms": 0,
		"chest": 0,
		"face": 0,
		"feet": 0,
		"head": 0,
		"legs": 0,
		"accessory1": 0,
		"accessory2": 0
	}
	return db.update_rows("equipment", "char_id = %d" % player.charID, data)

# Skill
func GetSkill(charID : int, skillID : int) -> Dictionary:
	var results : Array[Dictionary] = db.select_rows("skill", "char_id = %d AND skill_id = %d" % [charID, skillID], ["*"])
	assert(results.size() <= 1, "Duplicated skill %d on character %d" % [skillID, charID])
	return results[0] if results.size() > 0 else {}

func SetSkill(charID : int, skillID : int, value : int) -> bool:
	var data : Dictionary = GetSkill(charID, skillID)
	# Update value
	if not data.is_empty():
		data["level"] = value
		return db.update_row("skill", "skill_id = %d AND char_id = %d" % [skillID, charID], data)
	# Add value
	return db.insert_row("skill", data)

func GetSkills(charID : int) -> Array[Dictionary]:
	return db.select_rows("skill", "char_id = %d" % [charID], ["*"])

# Bestiary
func GetBestiary(charID : int, mobID : int) -> Dictionary:
	var results : Array[Dictionary] = db.select_rows("bestiary", "char_id = %d AND mob_id = %d" % [charID, mobID], ["*"])
	assert(results.size() <= 1, "Duplicated bestiary row for %d on character %d" % [mobID, charID])
	return results[0] if results.size() > 0 else {}

func SetBestiary(charID : int, mobID : int, value : int) -> bool:
	var data : Dictionary = GetBestiary(charID, mobID)
	# Update value
	if not data.is_empty():
		data["killed_count"] = value
		return db.update_row("bestiary", "mob_id = %d AND char_id = %d" % [mobID, charID], data)
	# Add value
	return db.insert_row("bestiary", data)

func GetBestiaries(charID : int) -> Array[Dictionary]:
	return db.select_rows("bestiary", "char_id = %d" % [charID], ["*"])

# Quest
func GetQuest(charID : int, questID : int) -> Dictionary:
	var results : Array[Dictionary] = db.select_rows("quest", "char_id = %d AND quest_id = %d" % [charID, questID], ["*"])
	assert(results.size() <= 1, "Duplicated quest row for %d on character %d" % [questID, charID])
	return results[0] if results.size() > 0 else {}

func SetQuest(charID : int, questID : int, value : int) -> bool:
	var data : Dictionary = GetQuest(charID, questID)
	# Update value
	if not data.is_empty():
		data["state"] = value
		return db.update_row("quest", "quest_id = %d AND char_id = %d" % [questID, charID], data)
	# Add value
	return db.insert_row("item", data)

func GetQuests(charID : int) -> Array[Dictionary]:
	return db.select_rows("quest", "char_id = %d" % [charID], ["*"])

# Commons
func Query(query : String) -> Array[Dictionary]:
	var data : Array[Dictionary] = []
	queryMutex.lock()
	if db.query(query):
		data = db.query_result
	queryMutex.unlock()
	return data

func QueryBindings(query : String, params : Array) -> Array[Dictionary]:
	var data : Array[Dictionary] = []
	queryMutex.lock()
	if db.query_with_bindings(query, params):
		data = db.query_result
	queryMutex.unlock()
	return data

#
func _post_launch():
	if not FileSystem.FileExists(Path.Local + SQLCommons.CurrentDBName):
		if not FileSystem.CopySQLDatabase(SQLCommons.TemplatePath, SQLCommons.CurrentDBName):
			return

	db = SQLite.new()
	db.path = Path.Local + SQLCommons.CurrentDBName
	db.verbosity_level = SQLite.VERBOSE if Launcher.Debug else SQLite.NORMAL

	if not db.open_db():
		assert(false, "Failed to open database: "+ db.error_message)
	else:
		if not Launcher.Debug:
			backups = SQLBackups.new()
			backups.Start()

	isInitialized = true

func Destroy():
	if backups:
		backups.Stop()
	if db:
		db.close_db()

func UnitTest():
	# Clear previous data
	db.delete_rows("account", "")
	db.delete_rows("attribute", "")
	db.delete_rows("bestiary", "")
	db.delete_rows("character", "")
	db.delete_rows("equipment", "")
	db.delete_rows("item", "")
	db.delete_rows("quest", "")
	db.delete_rows("skill", "")
	db.delete_rows("sqlite_sequence", "")
	db.delete_rows("stat", "")
	db.delete_rows("trait", "")

	# Add account and login into it
	assert(AddAccount("Admin", "password", "q@q.q") == true, "Could not create the test account")
	var accountID : int = Login("Admin", "password")
	assert(accountID != -1, "Could not login to the test account")
	if accountID == -1:
		return

	# Fill in some characters into this account and retrieve the full char list from this account
	var charIDs : Array[int] = GetCharacters(accountID)
	assert(charIDs.size() == 0, "Character list for the test account is not empty upon creation")
	assert(AddCharacter(accountID, "Admin", {}, {}) == true, "Could not create a test character")
	assert(AddCharacter(accountID, "Admin2", {}, {}) == true, "Could not create a second test character")
	charIDs = GetCharacters(accountID)
	assert(charIDs.size() == 2, "Missing characters on the test account")
	if charIDs.size() != 2:
		return

	# Get a specific character
	var charID : int = charIDs[0]
	var character : Dictionary = GetCharacter(charID)
	assert(character.size() > 0, "Missing character information")
	var characterInfo : Dictionary = GetCharacterInfo(charID)
	assert(characterInfo.size() > 0, "Missing character information")

	# Instantiate a player out of the character information
	var playerData : EntityData = Instantiate.FindEntityReference(Launcher.World.defaultSpawn.name)
	if not playerData:
		return
	var player : BaseAgent = Instantiate.CreateAgent(Launcher.World.defaultSpawn, playerData, character["nickname"])
	if player == null:
		return
	player.charID = charID

	# Log out the player, remove it from the database and remove the account as well
	assert(CharacterLogout(player) == true, "Could not logout from the character")
	assert(RemoveCharacter(player) == true, "Could not delete the test character")
	assert(RemoveAccount(accountID) == true, "Could not delete the test account")
	player.queue_free()
