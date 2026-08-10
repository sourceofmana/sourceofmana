extends NpcScript

#
const QUEST_ID : int = ProgressCommons.Quest.MINE_EXPLORATION

#
func OnStart():
	if not own or not own.progress:
		return

	var questState : int = own.progress.GetQuest(ProgressCommons.Quest.MINE_EXPLORATION)
	if questState < ProgressCommons.MINE_EXPLORATION.STRANGER_SPOTTED or questState == ProgressCommons.CompletedProgress:
		return

	Narrate("You notice a crack in the cave wall. A faint blue light seems to come from the other side.")
	Narrate("It looks like you can squeeze through.")
	Narrate("A calm voice fills your head.")
	Mes("I don't feel the same dark presence that I felt with the first one who came through here. Please come forward.")
	Mes("For the first time in thousands of years, I will be needing someone's help.")
	WarpInstance(npc.ownScript.mapName, Vector2(npc.ownScript.mapPos))
