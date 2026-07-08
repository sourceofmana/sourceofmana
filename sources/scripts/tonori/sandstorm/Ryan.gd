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
	Choice("Okay... why did I agree to this...", OnStartQuest)

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
	Choice("The lower level is completely flooded. There is no chance of getting through.", OnLieFlooded)
	Choice("There are fire-breathing scorpions! Hundreds! They might get angry if we disturb them.", OnLieScorpions)
	Choice("There are goblin nests everywhere! We could lose a lot of people clearing them out.", OnLieGoblins)
	Choice("There was a magical tree. It talked to me!", OnLieManaTree) 

func OnLieFlooded():
	Mes("Flooded?")
	Mes("I wonder where the water came from.")
	Mes("There is a well just outside of here, maybe there was underground water nearby.")
	Mes("We should not mess with flooded caves. The tunnels could collapse and trap us all inside. I'll report back that the mine is too far gone.")
	Action(OnAskAboutNickos)

func OnLieScorpions():
	Mes("Fire-breathing? I have never seen that before.")
	Mes("I've seen scorpions down there big enough to swallow a man whole. I guess it wouldn't be so unthinkable for them to breathe fire.")
	Mes("Maybe we should avoid this place. It doesn't seem like we'll find much of use anyway.")
	Action(OnAskAboutNickos)

func OnLieGoblins():
	Mes("G...goblins? Are... are you sure?")
	Mes("I'm... I'm not scared! If that's what you were wondering. I AM NOT SCARED OF GOBLINS!")
	Mes("You know what? We should just leave this place. Yes, let's just go.")
	Mes("It's way too dangerous down here. It's not worth the risk just to look for forgotten ores.")
	Action(OnAskAboutNickos)

func OnLieManaTree():
	Mes("A tree. A magical tree. A magical TALKING tree.")
	Mes("What's next, you'll tell me the scorpions were breathing fire? Did a goblin sing you a song?")
	Mes("You've lost your mind. Whatever happened down there made you stupid!")
	Mes("Maybe this is one of those haunted caves. I'm starting to think we shouldn't go down at all.")
	Action(OnAskAboutNickos)

func OnAskAboutNickos():
	Mes("Speaking of which. What about Nickos? Did you find him?")
	Choice("He's alive. Shaken up, but resting.", OnNickosAlive)
	Choice("I found his remains.", OnNickosDead)

func OnNickosAlive():
	Mes("No surprise, I've seen him get scared by at the sight of a maggot walking towards him.")
	Mes("He'd better not waste my time up here and get back quickly, or I may just leave him.")
	SetQuest(QUEST_ID, ProgressCommons.MINE_EXPLORATION.REWARDS_WITHDREW)
	AddGP(1000)
	OnFarewell()

func OnNickosDead():
	Mes("...")
	Mes("Right.")
	Mes("He knew the risks. Everyone who does this job knows that.")
	Mes("...")
	Mes("We're not going to get his body. Don't even suggest it.")
	Mes("If I lose anyone else I'll never be allowed to lead anyone outside the city walls again.")
	Mes("His pay was his own to collect. Consider it yours for the report.")
	Mes("At least now I'm sure we won't be going down there. First person I send died. Not a good sign.")
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
