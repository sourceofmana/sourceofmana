extends NpcScript

const QUEST_ID = ProgressCommons.Quest.MINE_EXPLORATION

func OnStart():
	match GetQuest(QUEST_ID):
		ProgressCommons.MINE_EXPLORATION.DEFEATED:
			Mes("You are stronger than I thought.")
			Mes("We will meet again...")
		_:
			OnMeetXakelbael()

func OnQuit():
	super.OnQuit()
	if GetQuest(QUEST_ID) == ProgressCommons.MINE_EXPLORATION.DEFEATED:
		npc.ownScript.TriggerManaTree.call_deferred()
		npc.ownScript.RunAway.call_deferred()

func OnMeetXakelbael():
	Mes("I came here for the Kano. I did not expect to find a living Uru hiding in the dark. How does it survive?")
	Mes("Is it the last one or are there more?")
	Choice("What are you talking about?", OnBadMoment)
	Choice("Kano? Uru?", OnBadMoment)
	Choice("Who are you?", OnBadMoment)

func OnBadMoment():
	Mes("This is a bad time for you Tulimshar folk to intrude on this place.")
	Mes("I already dealt with one of you earlier, but you followed me too far, I won't be as forgiving with you.")
	Choice("What is this place?", OnNotSupposedToBeHere)
	Choice("Can you explain what's happening?", OnNotSupposedToBeHere)
	Choice("I don't even know who you are.", OnNotSupposedToBeHere)

func OnNotSupposedToBeHere():
	Mes("You are not supposed to be here. Neither am I, but that doesn't matter.")
	Mes("I have what I want.")
	Mes("I don't have time to satisfy your curiosity and I cannot let you leave this place.")
	Action(npc.ownScript.StartFight)
