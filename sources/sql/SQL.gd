extends ServiceBase

#
var db : Object						= null
var backups : SQLBackups			= null
var queryMutex : Mutex				= Mutex.new()

# Migrations
func HasVersion() -> bool:
	var result = Query("SELECT name FROM sqlite_master WHERE type=\"table\" AND name=\"migration\"")
	return not result.is_empty()

func GetVersion() -> int:
	if HasVersion():
		var result = Query("SELECT version FROM migration LIMIT 1;")
		if not result.is_empty():
			return result[0].get("version", 0)
	return 0

func SetVersion(version : int):
	Query("UPDATE migration SET version = %d;" % version)

func ApplyMigrations():
	var currentVersion : int = GetVersion()
	var patches : PackedStringArray = FileSystem.ParseSQL(Path.MigrationRsc)
	var patchCount : int = patches.size()
	if patchCount == currentVersion:
		return

	while patchCount > currentVersion:
		ApplyMigration(patches[currentVersion])
		currentVersion += 1
	SetVersion(currentVersion)

func ApplyMigration(migrationFile : String):
	var migration : String = FileAccess.get_file_as_string(migrationFile)
	Query(migration)

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

func ValidateAuthPassword(username : String, triedPassword : String) -> Peers.AccountData:
	var results : Array[Dictionary] = QueryBindings("SELECT account_id, password, password_salt, permission FROM account WHERE username = ?;", [username])
	assert(results.size() <= 1, "Duplicated account row")
	if not results.is_empty():
		var salt = results[0].get("password_salt", null)
		var correctPassword = results[0].get("password", null)
		var accountID = results[0].get("account_id", null)
		if salt and correctPassword and accountID and salt is String and correctPassword is String and accountID is int:
			var hashedTriedPassword : String = Hasher.HashPassword(triedPassword, salt)
			if hashedTriedPassword == correctPassword:
				var permission = results[0].get("permission", null)
				if not permission:
					permission = ActorCommons.Permission.NONE
				return Peers.AccountData.new(accountID, permission)
	return null

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

func GetCharacters(accountID : int) -> PackedInt64Array:
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
	return {} if results.is_empty() else results[0]

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
	return NetworkCommons.PeerUnknownID if results.is_empty() else results[0]["char_id"]

func GetCharacter(charID : int) -> Dictionary:
	var results : Array[Dictionary] = db.select_rows("character", "char_id = %d" % charID, ["*"])
	assert(results.size() <= 1, "Duplicated character row %d" % charID)
	return {} if results.is_empty() else results[0]

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
	return {} if results.is_empty() else results[0]

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
	return {} if results.is_empty() else results[0]

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
	return {} if results.is_empty() else results[0]

func UpdateStat(charID : int, stats : ActorStats) -> bool:
	if stats == null:
		return false

	var data : Dictionary = {
		"level" = stats.level,
		"experience" = stats.experience,
		"gp" = stats.gp,
		"health" = max(1, stats.health),
		"mana" = stats.mana,
		"stamina" = stats.stamina,
		"karma" = stats.karma
	}
	return db.update_rows("stat", "char_id = %d" % charID, data)

# Inventory
func GetItem(charID : int, itemID : int, customfield : String, storageType : int = 0) -> Dictionary:
	var results : Array[Dictionary] = QueryBindings("SELECT * FROM item WHERE item_id = ? AND char_id = ? AND storage = ? AND customfield = ?;", [itemID, charID, storageType, customfield])
	assert(results.size() <= 1, "Duplicated item %d on character %d with storage %d" % [itemID, charID, storageType])
	return {} if results.is_empty() else results[0]

func AddItem(charID : int, itemID : int, customfield : String, itemCount : int = 1, storageType : int = 0) -> bool:
	var data : Dictionary = GetItem(charID, itemID, customfield, storageType)
	# Increment item count
	if not data.is_empty():
		return ExecuteBindings("UPDATE item SET count = ? WHERE item_id = ? AND char_id = ? AND storage = ? AND customfield = ?;", [data["count"] + 1, itemID, charID, storageType, customfield])

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
	if not data.is_empty():
		# Decrement item count
		if data["count"] > itemCount:
			return ExecuteBindings("UPDATE item SET count = ? WHERE item_id = ? AND char_id = ? AND storage = ? AND customfield = ?;", [data["count"] - itemCount, itemID, charID, storageType, customfield])
		# Remove item
		elif data["count"] == itemCount:
			return ExecuteBindings("DELETE FROM item WHERE item_id = ? AND char_id = ? AND storage = ? AND customfield = ?;", [itemID, charID, storageType, customfield])
	return false

func GetStorage(charID : int, storageType : int = 0) -> Array[Dictionary]:
	return db.select_rows("item", "char_id = %d AND storage = %d" % [charID, storageType], ["*"])

# Equipment
func GetEquipment(charID : int) -> Dictionary:
	var results : Array[Dictionary] = db.select_rows("equipment", "char_id = %d" % charID, ["*"])
	assert(results.size() <= 1, "Duplicated equipment on character %d" % charID)
	return {} if results.is_empty() else results[0]

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

	if not results.is_empty():
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

	if not results.is_empty():
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

	if not results.is_empty():
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

# Auth Token
func AddAuthToken(accountID : int, tokenHash : String, ipAddress : String) -> bool:
	ExecuteBindings("DELETE FROM auth_token WHERE account_id = ? AND ip_address = ?;", [accountID, ipAddress])
	var now : int = SQLCommons.Timestamp()
	var data : Dictionary = {
		"token_hash": tokenHash,
		"account_id": accountID,
		"ip_address": ipAddress,
		"created_timestamp": now,
		"expires_timestamp": now + NetworkCommons.TokenExpirySec,
	}
	return db.insert_row("auth_token", data)

func ValidateAuthToken(accountID : int, tokenHash : String, ipAddress : String) -> Peers.AccountData:
	var results : Array[Dictionary] = QueryBindings("SELECT auth_token.account_id, auth_token.expires_timestamp, account.permission FROM auth_token INNER JOIN account ON auth_token.account_id = account.account_id WHERE auth_token.account_id = ? AND auth_token.token_hash = ? AND auth_token.ip_address = ?;", [accountID, tokenHash, ipAddress])
	if not results.is_empty():
		if results[0].get("expires_timestamp", 0) <= SQLCommons.Timestamp():
			RemoveAuthToken(accountID, tokenHash)
			return null
		var permission : Variant = results[0].get("permission", null)
		if not permission:
			permission = ActorCommons.Permission.NONE
		return Peers.AccountData.new(accountID, permission)
	return null

func RefreshAuthToken(accountID : int, ipAddress : String) -> bool:
	return ExecuteBindings("UPDATE auth_token SET expires_timestamp = ? WHERE account_id = ? AND ip_address = ?;", [SQLCommons.Timestamp() + NetworkCommons.TokenExpirySec, accountID, ipAddress])

func RemoveAuthToken(accountID : int, tokenHash : String) -> bool:
	return ExecuteBindings("DELETE FROM auth_token WHERE account_id = ? AND token_hash = ?;", [accountID, tokenHash])

func CleanExpiredTokens():
	db.delete_rows("auth_token", "expires_timestamp <= %d" % SQLCommons.Timestamp())

func GetAccountEmail(accountID : int) -> String:
	var results : Array[Dictionary] = QueryBindings("SELECT email FROM account WHERE account_id = ?;", [accountID])
	if not results.is_empty():
		var email : Variant = results[0].get("email", null)
		if email is String:
			return email
	return ""

func CheckAccountPassword(accountID : int, triedPassword : String) -> bool:
	var results : Array[Dictionary] = QueryBindings("SELECT password, password_salt FROM account WHERE account_id = ?;", [accountID])
	if results.is_empty():
		return false
	return Hasher.HashPassword(triedPassword, results[0]["password_salt"]) == results[0]["password"]

func UpdateAccountPassword(accountID : int, newPassword : String) -> bool:
	var salt : String = Hasher.GenerateSalt()
	var hashedPassword : String = Hasher.HashPassword(newPassword, salt)
	return ExecuteBindings("UPDATE account SET password = ?, password_salt = ? WHERE account_id = ?;", [hashedPassword, salt, accountID])

func RemoveAllAuthTokens(accountID : int) -> bool:
	return ExecuteBindings("DELETE FROM auth_token WHERE account_id = ?;", [accountID])

# Ban
func BanAccount(accountID : int, unbanTimestamp : int, reason : String = "") -> bool:
	var results : Array[Dictionary] = db.select_rows("ban", "account_id = %d" % accountID, ["*"])
	var data : Dictionary = {
		"account_id": accountID,
		"banned_timestamp": SQLCommons.Timestamp(),
		"unban_timestamp": unbanTimestamp,
		"reason": reason,
	}
	if not results.is_empty():
		return db.update_rows("ban", "account_id = %d" % accountID, data)
	return db.insert_row("ban", data)

func UnbanAccount(accountID : int) -> bool:
	return db.delete_rows("ban", "account_id = %d" % accountID)

func LoadBans() -> Dictionary[int, int]:
	var bans : Dictionary[int, int] = {}
	var now : int = SQLCommons.Timestamp()
	var results : Array[Dictionary] = Query("SELECT account_id, unban_timestamp FROM ban WHERE unban_timestamp > %d;" % now)
	for row in results:
		bans[row["account_id"]] = row["unban_timestamp"]
	return bans

func GetAccountID(username : String) -> int:
	var results : Array[Dictionary] = QueryBindings("SELECT account_id FROM account WHERE username = ?;", [username])
	if not results.is_empty():
		return results[0].get("account_id", NetworkCommons.PeerUnknownID)
	return NetworkCommons.PeerUnknownID

func SetPermission(accountID : int, permission : int) -> bool:
	var data : Dictionary = { "permission": permission }
	return db.update_rows("account", "account_id = %d" % accountID, data)

func GetBanList(filter : String = "") -> Array[Dictionary]:
	var now : int = SQLCommons.Timestamp()
	if filter.is_empty():
		return Query("SELECT ban.account_id, account.username, ban.unban_timestamp, ban.reason FROM ban INNER JOIN account ON ban.account_id = account.account_id WHERE ban.unban_timestamp > %d;" % now)
	return QueryBindings("SELECT ban.account_id, account.username, ban.unban_timestamp, ban.reason FROM ban INNER JOIN account ON ban.account_id = account.account_id WHERE ban.unban_timestamp > ? AND account.username LIKE ?;", [now, "%" + filter + "%"])

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

func ExecuteBindings(query : String, params : Array) -> bool:
	queryMutex.lock()
	var ret : bool = db.query_with_bindings(query, params)
	queryMutex.unlock()
	return ret

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
	db.verbosity_level = SQLite.VERBOSE if OS.is_debug_build() else SQLite.NORMAL

	if not db.open_db():
		assert(false, "Failed to open database: "+ db.error_message)
	else:
		if not Launcher.Debug:
			backups = SQLBackups.new()

	ApplyMigrations()
	Peers.bannedAccounts = LoadBans()
	CleanExpiredTokens()

	isInitialized = true

func Destroy():
	if backups:
		backups.Stop()
	if db:
		db.close_db()

func Wipe():
	db.delete_rows("account", "")
	db.delete_rows("attribute", "")
	db.delete_rows("auth_token", "")
	db.delete_rows("ban", "")
	db.delete_rows("bestiary", "")
	db.delete_rows("character", "")
	db.delete_rows("equipment", "")
	db.delete_rows("item", "")
	db.delete_rows("quest", "")
	db.delete_rows("skill", "")
	db.delete_rows("sqlite_sequence", "")
	db.delete_rows("stat", "")
	db.delete_rows("trait", "")
