extends Object
class_name ActorProgress

#
class _SkillData:
	var proba : float						= 0.0
	var level : int							= 0

#
var bestiary : Dictionary			= {}
var quests : Dictionary				= {}
var skills : Dictionary				= {}

var actor : Actor				= null

var questMutex : Mutex				= null
var bestiaryMutex : Mutex			= null
var probaSum : float				= 0.0

# Quest progress
func SetQuest(questID : int, state : int):
	questMutex.lock()
	quests[questID] = state
	questMutex.unlock()

	if actor is PlayerAgent and actor.rpcRID != NetworkCommons.RidUnknown:
		Network.UpdateQuest(questID, state, actor.rpcRID)

func GetQuest(questID : int) -> int:
	var state : int = ProgressCommons.UnknownProgress
	if questID in quests:
		questMutex.lock()
		state = quests[questID]
		questMutex.unlock()
	return state

# Bestiary progress
func AddBestiary(entityID : int, killedCount : int = 1):
	var totalCount : int = killedCount
	bestiaryMutex.lock()
	if entityID in bestiary:
		totalCount += bestiary[entityID]
	bestiary[entityID] = totalCount
	bestiaryMutex.unlock()

	if actor is PlayerAgent and actor.rpcRID != NetworkCommons.RidUnknown:
		Network.UpdateBestiary(entityID, totalCount, actor.rpcRID)

func GetBestiary(monsterID : String) -> int:
	var count : int = 0
	if monsterID in bestiary:
		bestiaryMutex.lock()
		count = bestiary[monsterID]
		bestiaryMutex.unlock()
	return count

#
func HasSkill(cell : SkillCell, level : int = 1) -> bool:
	assert(cell != null, "Provided skill cell is null")
	var data : _SkillData = skills.get(cell.id, null) if cell else null
	return data and data.level >= level

func AddSkill(cell : SkillCell, proba : float, level : int = 1):
	assert(cell != null, "Provided skill cell is null")
	if not cell:
		return

	if cell.id not in skills:
		skills[cell.id] = _SkillData.new()

	var data : _SkillData = skills[cell.id]
	probaSum -= data.proba
	data.level = level
	data.proba = proba
	probaSum += proba

	if actor is PlayerAgent and actor.rpcRID != NetworkCommons.RidUnknown:
		Network.UpdateSkill(cell.id, level, actor.rpcRID)

func GetSkill(cell : SkillCell) -> _SkillData:
	return skills.get(cell.id, null) if cell else null

func GetSkillProba(cell : SkillCell) -> float:
	var data : _SkillData = GetSkill(cell)
	return data.proba if data else 0.0

func GetSkillLevel(cell : SkillCell) -> int:
	var data : _SkillData = GetSkill(cell)
	return data.level if data else 0

func RemoveSkill(cell : SkillCell):
	assert(cell != null, "Provided skill cell is null")
	if not cell:
		return

	var data : _SkillData = skills.get(cell.id, null)
	if not data:
		return

	probaSum -= data.proba
	skills.erase(cell.id)
	data.queue_free()

	if actor is PlayerAgent and actor.rpcRID != NetworkCommons.RidUnknown:
		Network.UpdateSkill(cell.id, 0, actor.rpcRID)

#
func ImportProgress(charID : int):
	for entry in Launcher.SQL.GetSkills(charID):
		var skill : SkillCell = DB.GetSkill(entry.get("skill_id", DB.UnknownHash))
		if skill:
			AddSkill(skill, 1.0, entry.get("level", 1))
	for entry in Launcher.SQL.GetQuests(charID):
		SetQuest(entry.get("quest_id", DB.UnknownHash), entry.get("state", 0))
	for entry in Launcher.SQL.GetBestiaries(charID):
		AddBestiary(entry.get("mob_id", DB.UnknownHash), entry.get("killed_count", 0))

#
func _init(actorNode : Actor, isManaged : bool):
	if isManaged:
		actor = actorNode
		questMutex = Mutex.new()
		bestiaryMutex = Mutex.new()
