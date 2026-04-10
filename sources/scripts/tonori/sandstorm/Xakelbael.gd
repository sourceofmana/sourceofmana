extends NpcScript

#
func OnStart():
	var questState : int = GetQuest(ProgressCommons.Quest.DESERT_DEEP_XAKELBAEL)
	if questState == ProgressCommons.DESERT_DEEP_XAKELBAEL.DEFEATED:
		Mes("You are stronger than I thought.")
		Mes("We will meet again...")
		Mes("This is not the last you have seen of me!")
	else:
		Mes("Who comes here?")
		Action(npc.ownScript.StartFight)

func OnQuit():
	super.OnQuit()
	var questState : int = GetQuest(ProgressCommons.Quest.DESERT_DEEP_XAKELBAEL)
	if questState == ProgressCommons.DESERT_DEEP_XAKELBAEL.DEFEATED:
		npc.ownScript.RunAway.call_deferred()
