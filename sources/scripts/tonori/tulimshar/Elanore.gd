extends NpcScript

#
func OnStart():
	var questState : int = GetQuest(ProgressCommons.Quest.TUTORIAL)
	match questState:
		ProgressCommons.TUTORIAL.INACTIVE:
			OnFirstMeeting()
		ProgressCommons.TUTORIAL.INTRO_ITEMS_GIVEN:
			OnFeelingChoice()
		ProgressCommons.TUTORIAL.POTION_GIVEN:
			OnFeelingBetter()
		ProgressCommons.TUTORIAL.CLOTHES_GIVEN:
			OnExplainUI()
		ProgressCommons.TUTORIAL.UI_EXPLAINED:
			Mes("Is there something else on your mind?")
			OnMainChoice()
		_:
			Mes("Welcome back. What can I do for you?")
			OnMainChoice()

# First meeting
func OnFirstMeeting():
	var waterBottleID : int = DB.GetCellHash("Water Bottle")
	var cactusSourCandyID : int = DB.GetCellHash("Cactus Sour Candy")

	Mes("Hello, welcome to Tulimshar!")
	Mes("You made it to the gates just in time. The guards found you on the ground, barely within sight.")
	Mes("My name is Elanore. How are you feeling? You'll need to drink this water and please eat this as well, it will make you feel better.")
	SetQuest(ProgressCommons.Quest.TUTORIAL, ProgressCommons.TUTORIAL.INTRO_ITEMS_GIVEN)
	AddItem(waterBottleID)
	AddItem(cactusSourCandyID)
	OnFeelingChoice()

func OnFeelingChoice():
	Choice("I am feeling better now, thank you.", OnFeelingBetter)
	Choice("I am still feeling a bit weak...", OnFeelingWeak)

func OnFeelingWeak():
	var cactusDrinkID : int = DB.GetCellHash("Cactus Drink")

	Mes("Oh... Okay. Here, take one of these. Beyond that, you're going to need to take some time, darling.")
	SetQuest(ProgressCommons.Quest.TUTORIAL, ProgressCommons.TUTORIAL.POTION_GIVEN)
	AddItem(cactusDrinkID)
	OnFeelingBetter()

func OnFeelingBetter():
	Mes("What were you doing wandering in the desert? It's been dangerous lately, you shouldn't go out there alone.")
	Choice("Mercenary soldier trying to gain local fame.", OnGiveStarterClothes)
	Choice("Looking to start trades with natives of the region.", OnGiveStarterClothes)
	Choice("Scholar seeking knowledge on Mana and magic.", OnGiveStarterClothes)
	Choice("Sailor looking to explore new opportunities on and off land.", OnGiveStarterClothes)

func OnGiveStarterClothes():
	var cottonShirtID : int = DB.GetCellHash("Cotton Shirt")
	var linenShortsID : int = DB.GetCellHash("Shorts")

	Mes("Well, it's good to have you here. The city needs capable people to help keep it safe.")
	Mes("Recently the desert has gotten more dangerous. A group of fanatics obsessed with Kaore has been hiding in the mountains to the east. They have been launching assaults on travellers and once during a major battle they came close to breaching the city wall.")
	Mes("Anyway, here are some basic clothes to replace the rags we found you in.")
	SetQuest(ProgressCommons.Quest.TUTORIAL, ProgressCommons.TUTORIAL.CLOTHES_GIVEN)
	AddItem(cottonShirtID, 1, "Used")
	AddItem(linenShortsID, 1, "Used")
	OnExplainUI()

func OnExplainUI():
	Mes("Before I let you go, allow me to walk you through a few things that will help keep you alive out there.")
	Highlight(UICommons.UITarget.STAT)
	Narrate("These are your vital resources. Keep an eye on them at all times.")
	Highlight(UICommons.UITarget.HEALTHBAR)
	Narrate("Your health bar shows how much damage you can take before falling.")
	Highlight(UICommons.UITarget.MANABAR)
	Narrate("Your mana powers your skills, without it, many abilities become unavailable.")
	Highlight(UICommons.UITarget.STAMINABAR)
	Narrate("Stamina governs how long you can sprint and perform physical actions before tiring.")
	Highlight(UICommons.UITarget.MENU)
	Narrate("The menu gives you access to your inventory, skills, quests, settings and more. Use it to manage everything you carry and know.")
	Highlight(UICommons.UITarget.ACTION_BAR)
	Narrate("The action bar lets you slot skills and items for quick access. Drag what you need most onto it as in combat, every second counts.")
	ClearHighlight()
	SetQuest(ProgressCommons.Quest.TUTORIAL, ProgressCommons.TUTORIAL.UI_EXPLAINED)
	Action(OnMainChoice)

# Main choice loop
func HasAllIngredients() -> bool:
	return HasItem(DB.GetCellHash("Maggot Slime"), 6) and HasItem(DB.GetCellHash("Water Bottle")) and HasItem(DB.GetCellHash("Cactus Drink"))

func OnMainChoice():
	var sideQuestState : int = GetQuest(ProgressCommons.Quest.ELANORE_POTION)
	if sideQuestState == ProgressCommons.ELANORE_POTION.STARTED and HasAllIngredients():
		Choice("I have your ingredients.", OnPotionQuestTurnIn)
	elif sideQuestState == ProgressCommons.ELANORE_POTION.STARTED:
		Choice("About those ingredients...", OnPotionQuestReminder)
	else:
		Choice("Can I help you with anything?", OnHelpWithPotions)
	Choice("What is Kaore?", OnExplainKaore)
	Choice("Who are you?", OnExplainSelf)
	if GetQuest(ProgressCommons.Quest.TUTORIAL) >= ProgressCommons.TUTORIAL.ELANORE_DONE:
		Choice("Thank you again but I have to leave", Farewell)

# Help with potions
func OnHelpWithPotions():
	Mes("Yes! I make lots of Healing Potions for our guards and the people of this city. They're quick remedies for most ailments and really help keep our people safer.")
	Mes("Healing Potions require knowledge to make and also some key ingredients. Maybe you could get back on your feet by helping me gather some of these ingredients?")
	Mes("I need six Maggot Slimes, one Water and one Cactus Drink. Bring those to me and I will make you a Cactus Potion in return.")
	SetQuest(ProgressCommons.Quest.ELANORE_POTION, ProgressCommons.ELANORE_POTION.STARTED)
	if GetQuest(ProgressCommons.Quest.TUTORIAL) < ProgressCommons.TUTORIAL.ELANORE_DONE:
		OnSendToKael()
	else:
		OnMainChoice()

func OnPotionQuestReminder():
	Mes("I still need six Maggot Slimes, one Water and one Cactus Drink. Come back when you have them.")
	OnMainChoice()

func OnPotionQuestTurnIn():
	Mes("Thank you for your help. I'll get to work on making new healing potions right away!")
	Mes("Helping the people out here is much better than being stuck in some tower or palace. More of the leaders of this city should think about that.")
	RemoveItem(DB.GetCellHash("Maggot Slime"), 6)
	RemoveItem(DB.GetCellHash("Water Bottle"))
	RemoveItem(DB.GetCellHash("Cactus Drink"))
	SetQuest(ProgressCommons.Quest.ELANORE_POTION, ProgressCommons.ELANORE_POTION.INACTIVE)
	AddItem(DB.GetCellHash("Cactus Potion"))
	OnMainChoice()

# What is Kaore
func OnExplainKaore():
	Mes("Mana is the life energy that connects us all. Kaore is a decayed form of Mana that corrupts life rather than invigorating it. There is much more to it, but that's the general idea.")
	LookAtNpc("Nina")
	Mes("If you want to know more, you'd better ask my apprentice, Nina. She is currently overseeing the city's Soul Menhir. You can learn a lot more from her.")
	ResetCamera()
	OnMainChoice()

# Who are you
func OnExplainSelf():
	Mes("My name is Elanore. I am the Kahwe of this city and the land that surrounds it. Those outside of our faith call us Druids. I represent the Kaumatua, an order devoted to the most ancient tradition in our world.")
	Mes("But don't you worry about that right now. We can chat more later. Right now I am just out here giving a hand with potions and receiving the injured from outside the walls.")
	OnMainChoice()

# Tutorial conclusion
func OnSendToKael():
	Mes("But I should not keep you here all day. You are new to the city and will want to find your footing.")
	Mes("Watchman Kael is currently in charge of the local patrol from within our wall, you should speak to him if you're looking for work.")
	LookAtNpc("Kael")
	Mes("He is standing northeast from here near some palm trees.")
	Mes("Just follow this wall to the corner and walk up.")
	ResetCamera()
	SetQuest(ProgressCommons.Quest.TUTORIAL, ProgressCommons.TUTORIAL.ELANORE_DONE)
