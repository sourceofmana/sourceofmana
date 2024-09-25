extends NpcScript

# Required items
var dorianKeyID : int				= DB.GetCellHash("Dorian's Key")
var gabrielKeyID : int				= DB.GetCellHash("Gabriel's Key")
var marvinKeyID : int				= DB.GetCellHash("Marvin's Key")

const mapName : StringName			= "Splatyna's Chamber"
const mapPosition : Vector2			= Vector2(1500, 2190)

#
func OnStart():
	match GetQuest(ProgressCommons.QUEST_SPLATYNA_OFFERING):
		ProgressCommons.STATE_SPLATYNA.INACTIVE: Inactive()
		_: AskChoice()

func AskChoice():
	if HasItem(dorianKeyID) and HasItem(gabrielKeyID) and HasItem(marvinKeyID):
		Mes("You notice three different key locks, what would you like to do?")
		Choice("Open them", TryOpen)
		Choice("Leave")
	else:
		Chat("You need three different keys to unlock this passage.")

func TryOpen():
	# Check and remove items to open the chest
	if GetQuest(ProgressCommons.QUEST_SPLATYNA_OFFERING) != ProgressCommons.STATE_SPLATYNA.INACTIVE:
		if HasItem(dorianKeyID) and HasItem(gabrielKeyID) and HasItem(marvinKeyID):
			if RemoveItem(dorianKeyID) and RemoveItem(gabrielKeyID) and RemoveItem(marvinKeyID):
				Warp(mapName, mapPosition)
		else:
			Chat("You need three different keys to unlock this passage.")

func Inactive():
	Chat("Three locks are blocking this passage.")
