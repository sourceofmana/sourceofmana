extends NpcScript

const PEYOTE_REQUIRED : int = 5
const MAGGOT_REQUIRED : int = 5
const FIELD_POSITION : Vector2 = Vector2(2912, 1312)

#
func OnStart():
	var questState : int = GetQuest(ProgressCommons.Quest.TUTORIAL)
	if questState == ProgressCommons.TUTORIAL.KAEL_DONE:
		OnComplete()
	elif questState == ProgressCommons.TUTORIAL.KAEL_MET:
		OnCheckProgress()
	else:
		OnFirstMeeting()

# Initial encounter
func OnFirstMeeting():
	Mes("Hello, are you the one they pulled off the sand? Glad to see you walking about. I need your help.")
	Mes("The maggots love feeding on the cactus. Even though these maggots are unusually large, their mouths are still small and agile enough to eat their way around any spikes.")
	Mes("Once they breach the outside they simply burrow into the plant and eat it from the inside. It's a horrible sight.")
	Choice("Why are these maggots so monstrous?", OnKaoreExplanation)
	Choice("That sounds terrifying.", OnWildFauna)
	Choice("That sounds so cool!", OnWildFauna)

func OnKaoreExplanation():
	Mes("They say they weren't always like this. I'm not old enough to remember, no one is anymore.")
	Mes("Back before the Age of Kaore, hundreds of years ago, some creatures of this world were not as... Strange as they are today.")
	Mes("The Age of Kaore changed them. This type of maggot grew very large and very plentiful. Other creatures were changed in worse ways.")
	Mes("They say that squirrels used to be as intelligent as people, but they simply lost all that over time.")
	Mes("Anyway, enough chatting. I need you to get in this field and clean away this mess!")
	Choice("Yes, I'll get to work!", OnFieldCleanUp)
	Choice("What do you mean? What has been happening out in the desert?", OnDesertExplanation)

func OnWildFauna():
	Mes("Regardless, they need to be culled.")
	Mes("Whatever has been happening out in the desert has affected the maggots of the city as well.")
	Mes("Even worse, it seems cacti are also affected.")
	Mes("Some of them are jumping around and doing silly faces while splashing nearby crops! You need to help me deal with this.")
	Choice("Alright. I'll get to work, then.", OnFieldCleanUp)
	Choice("What do you mean? What has been happening out in the desert?", OnDesertExplanation)

func OnDesertExplanation():
	Mes("Kaore is affecting all sorts of creatures.")
	Mes("It's this evil force that twists living things into... I don't know... Worse versions of themselves? I suppose. More aggressive.")
	Mes("Until it takes a full hold on them, then they become sort of undead too. It's really a nasty curse.")
	Mes("The mages over at the tower... The Manayir. They've issued the warning that Kaore is currently concentrating in dangerous patterns throughout Tonori.")
	Choice("Alright alright, it's time to kill these things. Let's do it.", OnFieldCleanUp)
	Choice("Who are the Manayir?", OnManayir)

func OnManayir():
	Mes("They're some ancient order that studies Mana and does who-knows-what-else with it, up in that tower to the west of the city.")
	Mes("They're the ones who issue warnings about Kaore.")
	Mes("The Manayir Order are the ones who announced the end of the Age of Kaore about 27 years ago.")
	Mes("Ever since then they've been updating the people of Tulimshar about the flow of energies.")
	Mes("It's much like weather, different concentrations of Mana and Kaore are everchanging and can affect all living things in the area.")
	Choice("Alright alright, it's time to kill these things. Let's do it.", OnFieldCleanUp)
	Choice("What's the Age of Kaore?", OnAgeOfKaore)

func OnAgeOfKaore():
	Mes("I'm too young to remember, but until a few decades ago life was much more difficult for everyone.")
	Mes("Kaore had become more plentiful than Mana and for a few hundred years people struggled a lot more than today with mutated and even undead creatures.")
	Mes("We complain about maggots and peyotes, but really we have it easy compared to what my parents lived through.")
	Choice("Alright alright, it's time to kill these things. Let's do it.", OnFieldCleanUp)

# Task assignment
func OnFieldCleanUp():
	DisplayActions(["gp_interact", "gp_target", "gp_sit"])
	TeachSkill(DB.GetCellHash("Melee"))
	Narrate("You have learned the Melee skill. Press Interact near an enemy to automatically target and attack it.")
	Narrate("You can also use the Target action to cycle target one manually.")
	Narrate("Each hit costs stamina. Run out and your attacks will have less effect.")
	Narrate("Siting down helps stamina regeneration.")
	Mes("Start with the peyotes in that field just north from here.")
	LookAtPosition(FIELD_POSITION)
	Mes("They're kaore-infused cacti, harmless to us but useless for farming now.")
	Mes("They just taunt people by jumping around and splashing crops near them...")
	ResetCamera()
	Mes("Getting ride of 5 peyotes and 5 maggots should suffice to keep our crops safe for the day.")
	HighlightUI(UICommons.UITarget.PROGRESS)
	Narrate("The progress window will group all your on-going quests and monster encounters.")
	HighlightUI(UICommons.UITarget.NONE)
	Narrate("You can see the number of monsters you got rid within the Manapedia tab of the menu bar.")
	SetQuest(ProgressCommons.Quest.TUTORIAL, ProgressCommons.TUTORIAL.KAEL_MET)

# Progress check
func OnCheckProgress():
	var peyoteKills : int = GetBestiary("Peyote".hash())
	var maggotKills : int = GetBestiary("Maggot".hash())
	if peyoteKills >= PEYOTE_REQUIRED and maggotKills >= MAGGOT_REQUIRED:
		OnTaskComplete()
	elif peyoteKills < PEYOTE_REQUIRED:
		Mes("Not done yet. I still need you to clear out %d more peyote from the field." % (PEYOTE_REQUIRED - peyoteKills))
	else:
		Mes("Good work on the peyotes. Still need you to deal with %d more maggots though." % (MAGGOT_REQUIRED - maggotKills))

# Task completion
func OnTaskComplete():
	Mes("Impressive work!")
	Mes("You took care of that very quickly and way better than I expected.")
	Mes("You should report back to Watchman Ekinu. Tell him I was happy with your work here.")
	Mes("We're going on a small expedition into the desert soon and you might be the right type of person to help us out.")
	SetQuest(ProgressCommons.Quest.TUTORIAL, ProgressCommons.TUTORIAL.KAEL_DONE)
	AddExp(50)

func OnComplete():
	Mes("Report back to Watchman Ekinu when you're ready.")
	Mes("He'll know what to do next.")
