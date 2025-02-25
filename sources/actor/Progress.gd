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

var questMutex : Mutex				= null
var bestiaryMutex : Mutex			= null
var probaSum : float				= 0.0

# Quest progress
func SetQuest(questID : int, state : int):
	questMutex.lock()
	quests[questID] = state
	questMutex.unlock()

func GetQuest(questID : int) -> int:
	var state : int = ProgressCommons.UnknownProgress
	if questID in quests:
		questMutex.lock()
		state = quests[questID]
		questMutex.unlock()
	return state

# Bestiary progress
func AddBestiary(entityID : int, killedCount : int = 1):
	bestiaryMutex.lock()
	if entityID in bestiary:
		bestiary[entityID] += killedCount
	else:
		bestiary[entityID] = killedCount
	bestiaryMutex.unlock()

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

func RemoveSkill(cell : SkillCell):
	assert(cell != null, "Provided skill cell is null")
	if not cell:
		return

	var data : _SkillData = skills.get(cell.id, null)
	if data:
		probaSum -= data.proba
		skills.erase(cell.id)
		data.queue_free()

func IncreaseSkillLevel(cell : SkillCell):
	assert(cell != null, "Provided skill cell is null")
	if cell:
		var data : _SkillData = skills.get(cell, null)
		if data:
			data.level += 1

func DecreaseSkillLevel(cell : SkillCell):
	assert(cell != null, "Provided skill cell is null")
	if cell:
		var data : _SkillData = skills.get(cell, null)
		if data:
			data.level = max(0, data.level - 1)

#
func ExportProgress(charID : int):
	questMutex.lock()
	for entryID in quests:
		Launcher.SQL.SetQuest(charID, entryID, quests[entryID])
	questMutex.unlock()

	bestiaryMutex.lock()
	for entryID in bestiary:
		Launcher.SQL.SetBestiary(charID, entryID, bestiary[entryID])
	bestiaryMutex.unlock()

	for entryID in skills:
		var skill : _SkillData = skills[entryID]
		if skill:
			Launcher.SQL.SetSkill(charID, entryID, skill.level)

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
func _init(isManaged : bool):
	if isManaged:
		questMutex = Mutex.new()
		bestiaryMutex = Mutex.new()
