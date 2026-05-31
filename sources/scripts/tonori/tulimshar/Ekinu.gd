extends NpcScript

#
func OnStart():
	var questState : int = GetQuest(ProgressCommons.Quest.TUTORIAL)
	if questState < ProgressCommons.TUTORIAL.ELANORE_DONE:
		OnSendToElanore()
	elif questState < ProgressCommons.TUTORIAL.KAEL_DONE:
		OnSendToKael()
	elif questState < ProgressCommons.TUTORIAL.EKINU_DONE:
		OnKaelReport()
	else:
		OnComplete()

#
func OnSendToElanore():
	Mes("You are already up?")
	LookAtNpc("Elanore")
	Mes("Be sure to talk to Elanore, she took care of you while you were passed out after we found you.")
	ResetCamera()

func OnSendToKael():
	Mes("Have you seen the maggots we have to deal with?")
	Mes("Disgusting creatures. They say that in the past they used to be smaller.")
	Mes("Our cactus farmers are the most affected by them. The recent increase in the maggots' population has caused a lot of damage to their crops.")
	LookAtNpc("Kael")
	Mes("Watchman Kael is stationed east of here, by one of the cactus farms.")
	ResetCamera()
	Mes("If you want to be useful and repay the debt you owe us you should help Kael clear out some maggots.")

# Kael's report
func OnKaelReport():
	Mes("Did you take care of those maggots?")
	Choice("Yes, Kael said I did well. He thinks I could help with your expedition.", OnExpedition)

func OnExpedition():
	Mes("Mmh... He's right.")
	Mes("We do need one more fighter and I was worried about taking too many guards away from their posts here in the city.")
	Mes("You're going to be heading South, towards the Sandstorm Mines.")
	Mes("They're called that for a reason, you know? That area of the desert is prone to strong winds and the swirling sands tend to make it difficult to get to.")
	Choice("Why are you heading that way?", OnWhyExpedition)
	Choice("What should I do?", OnJobExplanation)

func OnWhyExpedition():
	Mes("The mines used to be a rich source of Iron Ore, very lucrative business for the Red Queen since the whole area is her private property.")
	Mes("They've been abandoned for a few years now as the sandstorm intensified, that area got more dangerous to traverse and miners were dying either to the sand storms or to the angry creatures that wander the desert.")
	Mes("It seems that our hopeless royalty is running low on funds now. She has ordered the mines to be reopened at all costs.")
	Mes("As usual she didn't even consider the danger it poses to the people she wants to send there to work.")
	Choice("What should I do?", OnJobExplanation)

func OnJobExplanation():
	Mes("Your job will be to scout the area and make sure the old cave system is clear of major dangers. If all is well, we will start bringing in miners and restart the whole operation.")

	if GetQuest(ProgressCommons.Quest.TUTORIAL) < ProgressCommons.TUTORIAL.EKINU_DONE:
		var shortSwordID : int = DB.GetCellHash("Short Sword")
		var desertGogglesID : int = DB.GetCellHash("Desert Goggles")
		Mes("But before you go, you can't leave without any protection.")
		Mes("Take these. You will need it out there!")
		SetQuest(ProgressCommons.Quest.TUTORIAL, ProgressCommons.TUTORIAL.EKINU_DONE)
		AddItem(shortSwordID)
		AddItem(desertGogglesID)
		AddExp(50)

		Mes("That should be enough to protect yourself")
		Mes("But if you are in danger, remember to run away, there is no pride in being dead.")

		TeachSkill(DB.GetCellHash("Run"))
		DisplayActions(["gp_run"])
		Narrate("Hold Run to sprint and cover ground faster or flee a battle.")
		Narrate("Sprinting drains stamina, so use it when you need it.")

		Mes("You should be all set now.")
		LookAtNpc("Gilgames")
		Mes("But one more thing. Before you leave the city, have a word with Gilgames over there. He is guarding the gate and is always willing to speak with new recruits.")
		ResetCamera()

	Mes("Some other guards have already gone ahead. Ask Watchman Dausen outside of the gates and he will tell you where to go.")
	if GetQuest(ProgressCommons.Quest.MINE_EXPLORATION) < ProgressCommons.MINE_EXPLORATION.STARTED:
		SetQuest(ProgressCommons.Quest.MINE_EXPLORATION, ProgressCommons.MINE_EXPLORATION.STARTED)

	OnMainChoice()

# Main choice loop
func OnMainChoice():
	if GetQuest(ProgressCommons.Quest.MINE_EXPLORATION) == ProgressCommons.MINE_EXPLORATION.STARTED:
		Choice("What should I do again?", OnJobExplanation)
	Choice("What can you tell me about the Red Queen?", OnRedQueen)
	Choice("What happens if I'm in danger?", OnStrangerDanger)
	Choice("Alright, let's get moving.", Farewell)

# Attack and flee
func OnStrangerDanger():
	Mes("First things first, strikes first.")
	Mes("If your opponent is no match, run for your life. There is no pride in being dead.")
	DisplayActions(["gp_target"])
	DisplayActions(["gp_interact"])
	DisplayActions(["gp_run"])
	Narrate("Hold Run to sprint and cover ground faster or flee a battle.")
	Narrate("Sprinting drains stamina, so use it when you need it.")
	OnMainChoice()

# Red Queen chain
func OnRedQueen():
	Mes("The \"Red Queen\", more formally known as Queen Karolina I, is the useless ruler of this city.")
	Mes("In fact, she claims to be Queen of Tonori. As if she could control anything beyond the city walls.")
	Mes("She claims to descend from the Platinum Dynasty, rulers of Tulimshar thousands of years ago. In reality we all know her father was a cactus farmer and she's only Queen because he was a very clever man.")
	Choice("It seems that you really dislike her.", OnDislikeQueen)
	Choice("Her father was a cactus farmer?", OnRedQueenFather)

func OnRedQueenFather():
	Mes("Yes. He managed to convince the old dying king that he was his bastard son.")
	Mes("The old man had no other kids and took a liking to him. Before dying he named him his heir. He was actually a very smart man and a good leader so the palace folk just went with it.")
	Mes("Now he's dead too and his useless daughter is making up stories about her supposed royal bloodline. The truth is that nobody likes her and she needs an excuse so that they let her keep wearing that crown.")
	Choice("It seems that you really dislike her.", OnDislikeQueen)

func OnDislikeQueen():
	Mes("That's an understatement!")
	Mes("I'd like to see her half-buried in the sands with scorpions poking at her corpse.")
	Mes("Don't go around saying I told you that, though.")
	Mes("She's a cold-hearted, uncaring and selfish person. She spends all her time tending to her garden within the Royal Palace.")
	Mes("She cares more for that silly garden of hers than she does for the lives of any of us.")
	Choice("We should get going before she gets angry then!", OnMainChoice)

# Expedition started
func Farewell():
	if randi() % 2:
		Chat("Stay sharp.")
	else:
		Chat("Come back in one piece.")

func OnComplete():
	var questState : int = GetQuest(ProgressCommons.Quest.MINE_EXPLORATION)
	if questState == ProgressCommons.MINE_EXPLORATION.STARTED:
		Mes("Report back to Watchman Dausen outside of the gates when you're ready to head out.")
	else:
		Mes("You've been lucky we found you before a goblin does but it's great to see you are doing better now.")

	OnMainChoice()
