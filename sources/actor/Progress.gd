extends Object
class_name ActorProgress

#
var bestiary : Dictionary			= {}
var quests : Dictionary				= {}

var questMutex : Mutex				= Mutex.new()
var bestiaryMutex : Mutex			= Mutex.new()

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
