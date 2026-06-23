extends NpcScript

const QUEST_ID = ProgressCommons.Quest.MINE_EXPLORATION
const DESERT_SEED_ID = ProgressCommons.Quest.DESERT_SEED

#
func OnStart():
	var state : ProgressCommons.MINE_EXPLORATION = GetQuest(QUEST_ID) as ProgressCommons.MINE_EXPLORATION
	if state <= ProgressCommons.MINE_EXPLORATION.STARTED:
		OnFirstEncounter()
	elif state <= ProgressCommons.MINE_EXPLORATION.DEFEATED:
		OnRemindObjective()
	elif state == ProgressCommons.MINE_EXPLORATION.MANA_TREE_MET:
		OnWarnAboutMines()
	else:
		OnFarewell()

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

func OnWarnAboutMines():
	Mes("You're still alive.")
	Mes("I was starting to think you'd gotten lost too. What happened down there?")
	Choice("The lower level is completely flooded.", OnLieFlooded)
	Choice("Fire-breathing scorpions. Dozens of them.", OnLieScorpions)
	Choice("I saw a goblin nest.", OnLieGoblins)
	Choice("There was a Mana Tree.", OnLieManaTree)

func OnLieFlooded():
	Mes("Flooded.")
	Mes("We haven't had rain in months. How does a cave flood?")
	Mes("...Doesn't matter. Those tunnels were already unstable. I'll keep the crew out.")
	Action(OnAskAboutNickos)

func OnLieScorpions():
	Mes("Fire-breathing.")
	Mes("I've seen scorpions down there big enough to swallow a man whole. I'll take your word for the rest.")
	Mes("No one goes back down.")
	Action(OnAskAboutNickos)

func OnLieGoblins():
	Mes("Goblins.")
	Mes("In MY mine.")
	Mes("Do you have any idea what it would cost to clear that out.")
	Mes("No. No one goes down there. End of story.")
	Action(OnAskAboutNickos)

func OnLieManaTree():
	Mes("A Mana Tree. In a desert mine.")
	Mes("What's next, you'll tell me the scorpions were breathing fire?")
	Mes("I don't know what you found down there and I'm starting to think I don't want to.")
	Mes("No one goes back down.")
	Action(OnAskAboutNickos)

func OnAskAboutNickos():
	Mes("Speaking of which. What about Nickos? Did you find him?")
	Choice("He's alive. Shaken up, but resting.", OnNickosAlive)
	Choice("I found his remains.", OnNickosDead)

func OnNickosAlive():
	Mes("No surprise, I've seen him get scared by a fly or even his own shadow in the desert.")
	Mes("He'd better not make a habit of wasting my time...")
	SetQuest(QUEST_ID, ProgressCommons.MINE_EXPLORATION.REWARDS_WITHDREW)
	AddGP(1000)
	OnFarewell()

func OnNickosDead():
	Mes("...")
	Mes("Right.")
	Mes("He knew the risks. Everyone who does this job knows that.")
	Mes("...")
	Mes("I'll send word to his family.")
	Mes("His pay was his own to collect. Consider it yours for the report.")
	SetQuest(QUEST_ID, ProgressCommons.MINE_EXPLORATION.REWARDS_WITHDREW)
	AddGP(2000)
	OnFarewell()

func OnFarewell():
	var responses : PackedStringArray = [
		"Good. Now stop standing here.",
		"About time. I thought you'd gotten lost too.",
		"Don't expect a medal.",
		"Go find something useful to do.",
		"You're still wasting my time.",
	]
	Chat(responses[randi() % responses.size()])
