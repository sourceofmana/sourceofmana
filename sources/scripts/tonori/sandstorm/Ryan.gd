extends NpcScript

const QUEST_ID = ProgressCommons.Quest.MINE_EXPLORATION

#
func OnStart():
	match GetQuest(QUEST_ID):
		ProgressCommons.MINE_EXPLORATION.FIND_NICKOS:
			OnRemindObjective()
		ProgressCommons.MINE_EXPLORATION.REWARDS_WITHDREW:
			OnFarewell()
		_:
			OnFirstEncounter()

#
func OnFirstEncounter():
	Mes("Who are you?")
	Choice("I was sent by Watchman Ekinu to help with scouting these mines.", OnPresentation)

func OnPresentation():
	Mes("He sent YOU? I told that sand brained idiot to send NEW RECRUITS.")
	Mes("Not some random desert wanderer.")
	Mes("You'll probably be running away at the first sight of a scorpion, won't you?")
	if GetBestiary("Scorpion".hash()) > 0:
		Choice("Actually, I have walked all the way here and fought off a few scorpions already.", OnHarshWelcome)
	else:
		Choice("I didn't come all this way to leave that quickly.", OnHarshWelcome)

func OnHarshWelcome():
	Mes("Right... whatever. Stop talking.")
	Mes("Your voice is annoying. The last thing I need is to hear it echo through this cave.")
	Mes("As you can see I already have some sorry beggars here who are desperate enough to dig through the dirt and see if there's any valuable metals left in this miserable place.")
	Choice("What am I supposed to do then?", OnExplainWhatToDo)

func OnExplainWhatToDo():
	Mes("I'm getting to it!")
	Mes("I have sent one of these idiots to scout ahead, but it seems that he got lost.")
	Mes("His name is Nickos. He hasn't been back for a while.")
	Mes("Look for him.")
	Mes("Bring him back if he's alive. If he's dead, then you will probably die as well and we will know there's danger down there.")
	Mes("How does that sound?")
	Choice("Awful, but I'll do it.", OnStartQuest)

func OnStartQuest():
	Mes("Good. I wasn't going to give you a choice anyway.")
	Mes("Go! Don't wait for me to kiss you goodbye.")
	SetQuest(QUEST_ID, ProgressCommons.MINE_EXPLORATION.FIND_NICKOS)

func OnRemindObjective():
	Mes("His name is Nickos. He hasn't been back for a while.")
	Mes("Look for him.")
	Mes("Bring him back if he's alive. If he's dead, then you will probably die as well and we will know there's danger down there.")

func OnFarewell():
	var responses : PackedStringArray = [
		"Good. Now stop standing here.",
		"About time. I thought you'd gotten lost too.",
		"Don't expect a medal.",
		"Go find something useful to do.",
		"You're still wasting my time.",
	]
	Chat(responses[randi() % responses.size()])
