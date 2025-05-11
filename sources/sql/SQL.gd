extends ServiceBase

#
var db : Object						= null
var backups : SQLBackups			= null
var queryMutex : Mutex				= Mutex.new()

# Accounts
func AddAccount(username : String, password : String, email : String) -> bool:
	var salt : String = Hasher.GenerateSalt()
	var hashedPassword : String = Hasher.HashPassword(password, salt)

	var accountData : Dictionary = {
		"username" : username,
		"password_salt" : salt,
		"password" : hashedPassword,
		"email" : email,
		"created_timestamp" : SQLCommons.Timestamp()
	}
	return db.insert_row("account", accountData)

func RemoveAccount(accountID : int) -> bool:
	return db.delete_rows("account", "account_id = %d" % accountID)

func HasAccount(username : String) -> bool:
	return not QueryBindings("SELECT account_id FROM account WHERE username = ?;", [username]).is_empty()

func Login(username : String, triedPassword : String) -> int:
	var results : Array[Dictionary] = QueryBindings("SELECT account_id, password, password_salt FROM account WHERE username = ?;", [username])
	assert(results.size() <= 1, "Duplicated account row")
	if not results.is_empty():
		var salt = results[0].get("password_salt", null)
		var correctPassword = results[0].get("password", null)
		var accountID = results[0].get("account_id", null)
		if salt and correctPassword and accountID and salt is String and correctPassword is String and accountID is int:
			var hashedTriedPassword : String = Hasher.HashPassword(triedPassword, salt)
			if hashedTriedPassword == correctPassword:
				return accountID
	return NetworkCommons.PeerUnknownID

func UpdateAccount(accountID : int) -> bool:
	var newTimestamp : int = SQLCommons.Timestamp()
	var data : Dictionary = {
		"last_timestamp": newTimestamp
	}
	return db.update_rows("account", "account_id = %d;" % accountID, data)

# Characters
func AddCharacter(accountID : int, nickname : String, stats : Dictionary, traits : Dictionary, attributes : Dictionary) -> bool:
	var charData : Dictionary = {
		"account_id": accountID,
		"nickname": nickname,
		"created_timestamp": SQLCommons.Timestamp()
	}
	var ret : bool = db.insert_row("character", charData)
	if ret:
		var charID : int = GetCharacterID(accountID, nickname)
		ret = ret and db.update_rows("stat", "char_id = %d" % charID, stats)
		ret = ret and db.update_rows("trait", "char_id = %d" % charID, traits)
		ret = ret and db.update_rows("attribute", "char_id = %d" % charID, attributes)
	return ret

func RemoveCharacter(charID : int) -> bool:
	if charID != NetworkCommons.PeerUnknownID:
		return db.delete_rows("character", "char_id = %d" % charID)
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

func RefreshCharacter(player : PlayerAgent) -> bool:
	var charID : int = Peers.GetCharacter(player.peerID)
	if charID == NetworkCommons.PeerUnknownID:
		return false

	var success : bool = charID != NetworkCommons.PeerUnknownID
	success = success and UpdateAttribute(charID, player.stat)
	success = success and UpdateTrait(charID, player.stat)
	success = success and UpdateStat(charID, player.stat)
	success = success and UpdateCharacter(player)
	success = success and UpdateProgress(charID, player.progress)

	return success

func HasCharacter(nickname : String) -> bool:
	return not QueryBindings("SELECT char_id FROM character WHERE nickname = ?;", [nickname]).is_empty()

func CharacterLogin(charID : int) -> bool:
	var newTimestamp : int = SQLCommons.Timestamp()
	var data : Dictionary = {
		"last_timestamp": newTimestamp
	}
	return db.update_rows("character", "char_id = %d;" % charID, data)

# Character
func GetCharacterID(accountID : int, nickname : String) -> int:
	var results : Array[Dictionary] = QueryBindings("SELECT char_id FROM character WHERE account_id = ? AND nickname = ?;", [accountID, nickname])
	assert(results.size() <= 1, "Duplicated character row for account %d and nickname '%s'" % [accountID, nickname])
	return results[0]["char_id"] if results.size() > 0 else NetworkCommons.PeerUnknownID

func GetCharacter(charID : int) -> Dictionary:
	var results : Array[Dictionary] = db.select_rows("character", "char_id = %d" % charID, ["*"])
	assert(results.size() <= 1, "Duplicated character row %d" % charID)
	return results[0] if results.size() > 0 else {}

func UpdateCharacter(player : PlayerAgent) -> bool:
	if player == null:
		return false

	var charID : int = Peers.GetCharacter(player.peerID)
	if charID == NetworkCommons.PeerUnknownID:
		return false

	var map : WorldMap = WorldAgent.GetMapFromAgent(player)
	var newTimestamp : int = SQLCommons.Timestamp()
	var data : Dictionary = GetCharacter(charID)

	data["total_time"] = SQLCommons.GetOrAddValue(data, "total_time", 0) + newTimestamp - SQLCommons.GetOrAddValue(data, "last_timestamp", newTimestamp)
	data["last_timestamp"] = newTimestamp

	if map != null and not map.HasFlags(WorldMap.Flags.NO_REJOIN) and ActorCommons.IsAlive(player):
		data["pos_x"] = player.position.x
		data["pos_y"] = player.position.y
		data["pos_map"] = map.id
	else:
		data["pos_x"] = player.respawnDestination.pos.x
		data["pos_y"] = player.respawnDestination.pos.y
		data["pos_map"] = player.respawnDestination.mapID

	data["respawn_x"] = player.respawnDestination.pos.x
	data["respawn_y"] = player.respawnDestination.pos.y
	data["respawn_map"] = player.respawnDestination.mapID

	if player.exploreOrigin != null:
		data["explore_x"] = player.exploreOrigin.pos.x
		data["explore_y"] = player.exploreOrigin.pos.y

	return db.update_rows("character", "char_id = %d;" % charID, data)

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
		"skintone" = stats.skintone,
		"gender" = stats.gender,
		"shape" = stats.shape,
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
func GetItem(charID : int, itemID : int, customfield : String, storageType : int = 0) -> Dictionary:
	var results : Array[Dictionary] = db.select_rows("item", "item_id = %d AND char_id = %d AND storage = %d AND customfield = '%s'" % [itemID, charID, storageType, customfield], ["*"])
	assert(results.size() <= 1, "Duplicated item %d on character %d with storage %d" % [itemID, charID, storageType])
	return {} if results.is_empty() else results[0]

func AddItem(charID : int, itemID : int, customfield : String, itemCount : int = 1, storageType : int = 0) -> bool:
	var data : Dictionary = GetItem(charID, itemID, customfield, storageType)
	# Increment item count
	if not data.is_empty():
		data["count"] += 1
		return db.update_rows("item", "item_id = %d AND char_id = %d AND storage = %d AND customfield = '%s'" % [itemID, charID, storageType, customfield], data)

	# Insert new item
	data = {
		"item_id": itemID,
		"char_id": charID,
		"count": itemCount,
		"storage": storageType,
		"customfield": customfield
	}
	return db.insert_row("item", data)

func RemoveItem(charID : int, itemID : int, customfield : String, itemCount : int = 1, storageType : int = 0) -> bool:
	var data : Dictionary = GetItem(charID, itemID, customfield, storageType)
	var condition : String = "item_id = %d AND char_id = %d AND storage = %d AND customfield = '%s'" % [itemID, charID, storageType, customfield]
	if not data.is_empty():
		# Decrement item count
		if data["count"] > itemCount:
			data["count"] -= itemCount
			return db.update_rows("item", condition, data)
		# Remove item
		elif data["count"] == itemCount:
			return db.delete_rows("item", condition)
	return false

func GetStorage(charID : int, storageType : int = 0) -> Array[Dictionary]:
	return db.select_rows("item", "char_id = %d AND storage = %d" % [charID, storageType], ["*"])

# Equipment
func GetEquipment(charID : int) -> Dictionary:
	var results : Array[Dictionary] = db.select_rows("equipment", "char_id = %d" % charID, ["*"])
	assert(results.size() <= 1, "Duplicated equipment on character %d" % charID)
	return results[0] if results.size() > 0 else {}

func UpdateEquipment(charID : int, data : Dictionary) -> bool:
	return db.update_rows("equipment", "char_id = %d" % charID, data)

# Progress
func UpdateProgress(charID : int, progress : ActorProgress):
	progress.questMutex.lock()
	for entryID in progress.quests:
		Launcher.SQL.SetQuest(charID, entryID, progress.quests[entryID])
	progress.questMutex.unlock()

	progress.bestiaryMutex.lock()
	for entryID in progress.bestiary:
		Launcher.SQL.SetBestiary(charID, entryID, progress.bestiary[entryID])
	progress.bestiaryMutex.unlock()

	for entryID in progress.skills:
		Launcher.SQL.SetSkill(charID, entryID, progress.skills[entryID])

	return true

# Skill
func SetSkill(charID : int, skillID : int, value : int) -> bool:
	var results : Array[Dictionary] = db.select_rows("skill", "char_id = %d AND skill_id = %d" % [charID, skillID], ["*"])
	assert(results.size() <= 1, "Duplicated skill for %d on character %d" % [skillID, charID])

	if results.size() > 0:
		results[0]["level"] = value
		return db.update_rows("skill", "char_id = %d AND skill_id = %d" % [charID, skillID], results[0])

	var data : Dictionary = {
		"char_id": charID,
		"skill_id": skillID,
		"level": value,
	}
	return db.insert_row("skill", data)

func GetSkills(charID : int) -> Array[Dictionary]:
	return db.select_rows("skill", "char_id = %d" % [charID], ["*"])

# Bestiary
func SetBestiary(charID : int, mobID : int, value : int) -> bool:
	var results : Array[Dictionary] = db.select_rows("bestiary", "char_id = %d AND mob_id = %d" % [charID, mobID], ["*"])
	assert(results.size() <= 1, "Duplicated bestiary row for %d on character %d" % [mobID, charID])

	if results.size() > 0:
		results[0]["killed_count"] = value
		return db.update_rows("bestiary", "char_id = %d AND mob_id = %d" % [charID, mobID], results[0])

	var data : Dictionary = {
		"char_id": charID,
		"mob_id": mobID,
		"killed_count": value,
	}
	return db.insert_row("bestiary", data)

func GetBestiaries(charID : int) -> Array[Dictionary]:
	return db.select_rows("bestiary", "char_id = %d" % [charID], ["*"])

# Quest
func SetQuest(charID : int, questID : int, value : int) -> bool:
	var results : Array[Dictionary] = db.select_rows("quest", "char_id = %d AND quest_id = %d" % [charID, questID], ["*"])
	assert(results.size() <= 1, "Duplicated quest row for %d on character %d" % [questID, charID])

	if results.size() > 0:
		results[0]["state"] = value
		return db.update_rows("quest", "char_id = %d AND quest_id = %d" % [charID, questID], results[0])

	var data : Dictionary = {
		"char_id": charID,
		"quest_id": questID,
		"state": value,
	}
	return db.insert_row("quest", data)

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
	var dbPath : String = SQLCommons.GetDBPath()
	if not FileSystem.FileExists(dbPath) and not SQLCommons.CopyDatabase(dbPath):
		return

	if LauncherCommons.isWeb:
		db = DummySQL.new()
	else:
		db = SQLite.new()
	db.path = dbPath
	db.verbosity_level = SQLite.VERBOSE if Launcher.Debug else SQLite.NORMAL

	if not db.open_db():
		assert(false, "Failed to open database: "+ db.error_message)
	else:
		if not Launcher.Debug:
			backups = SQLBackups.new()

	isInitialized = true

func Destroy():
	if backups:
		backups.Stop()
	if db:
		db.close_db()

func Wipe():
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
