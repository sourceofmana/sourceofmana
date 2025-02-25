extends Object
class_name ActorProgress

#
class _SkillData:
	var proba : float						= 1.0
	var level : int							= 1

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

func FillQuests(data : Dictionary) -> void:
	quests.clear()
	questMutex.lock()
	for questID in data:
		quests[questID] = data[questID]
	questMutex.unlock()

# Bestiary progress
func AddBestiary(entityID : int):
	bestiaryMutex.lock()
	if entityID in bestiary:
		bestiary[entityID] += 1
	else:
		bestiary[entityID] = 1
	bestiaryMutex.unlock()

func GetBestiary(monsterID : String) -> int:
	var count : int = 0
	if monsterID in bestiary:
		bestiaryMutex.lock()
		count = bestiary[monsterID]
		bestiaryMutex.unlock()
	return count

func FillBestiary(data : Dictionary):
	bestiary.clear()
	bestiaryMutex.lock()
	for entityID in data:
		bestiary[entityID] = data[entityID]
	bestiaryMutex.unlock()

#
func HasSkill(cell : SkillCell, level : int = 1) -> bool:
	assert(cell != null, "Provided skill cell is null")
	var data : _SkillData = skills.get(cell, null)
	return data and data.level >= level

func AddSkill(cell : SkillCell, proba : float, level : int = 1):
	assert(cell != null, "Provided skill cell is null")
	if cell and not skills.has(cell):
		var data : _SkillData = _SkillData.new()
		data.level = level
		data.proba = proba
		skills[cell] = data
	probaSum += proba

func RemoveSkill(cell : SkillCell):
	assert(cell != null, "Provided skill cell is null")
	if cell:
		var data : _SkillData = skills.get(cell, null)
		if data:
			probaSum -= data.proba
			skills.erase(cell)
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
			data.level -= 1

#
func _init(isManaged : bool):
	if isManaged:
		questMutex = Mutex.new()
		bestiaryMutex = Mutex.new()
