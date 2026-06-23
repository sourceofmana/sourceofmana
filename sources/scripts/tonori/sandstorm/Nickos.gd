extends NpcScript

const QUEST_ID = ProgressCommons.Quest.MINE_EXPLORATION

#
func OnStart():
	var state : ProgressCommons.MINE_EXPLORATION = GetQuest(QUEST_ID) as ProgressCommons.MINE_EXPLORATION
	if state <= ProgressCommons.MINE_EXPLORATION.STARTED:
		Mes("Help.")
	elif state <= ProgressCommons.MINE_EXPLORATION.FIND_NICKOS:
		OnMeetNickos()
	elif state <= ProgressCommons.MINE_EXPLORATION.DEFEATED:
		OnRemindStranger()
	else:
		OnComplete()

func OnMeetNickos():
	Mes("Who are you? Please, I need your help!")
	Choice("I was sent by Watchman Ryan to find you.", OnFoundNickos)

func OnFoundNickos():
	Mes("Oh. I thought that he would leave me to die.")
	Mes("He seemed to really not care what would happen to me down here when he sent me out alone.")
	Choice("What happened to you?", OnWhatHappened)

func OnWhatHappened():
	Mes("I was attacked by... Someone?")
	Mes("I didn't expect to find anyone down here, but there was a strange man wearing a dark robe.")
	Mes("He seemed to be inspecting the walls of the cave. I tried talking to him, but he immediately attacked me without saying anything.")
	Choice("Did you see where he went?", OnPursueStranger)
	Choice("Are you okay?", OnCheckNickos)

func OnCheckNickos():
	Mes("I will be. I need to catch my breath.")
	Mes("Do you have anything on you that could help?")
	var cactusPotionID : int = DB.GetCellHash("Cactus Potion")
	var cactusDrinkID : int = DB.GetCellHash("Cactus Drink")
	if HasItem(cactusPotionID):
		Choice("Yes. Try this. [x1 Cactus Potion]", OnCactusPotion)
	if HasItem(cactusDrinkID):
		Choice("Yes. Try this. [x1 Cactus Drink]", OnCactusDrink)
	Choice("No, I'm sorry. I have nothing.", OnNothingOnMe)

func OnCactusPotion():
	var id : int = DB.GetCellHash("Cactus Potion")
	if HasItem(id):
		RemoveItem(id)
		Action(OnUsedItem)
	else:
		Action(OnNothingOnMe)

func OnCactusDrink():
	var id : int = DB.GetCellHash("Cactus Drink")
	if HasItem(id):
		RemoveItem(id)
		Action(OnUsedItem)
	else:
		Action(OnNothingOnMe)

func OnUsedItem():
	Mes("Thank you! I feel much better. I'll rest here for a bit and then make my way out of this place.")
	Mes("Thanks for saving me! I was worried that the man would come back to finish me.")
	Choice("Did you see where he went?", OnPursueStranger)

func OnNothingOnMe():
	Mes("That's fine. I will just need to rest here a bit and then I'll be able to make my way out of this place.")
	Mes("I'm glad you found me. I was worried that the man would come back to finish me.")
	Choice("Did you see where he went?", OnPursueStranger)

func OnPursueStranger():
	Mes("He walked away following this corridor. The last time I heard him was below this ledge.")
	Mes("It sounded like he was walking in water. Then I heard crumbling rocks.")
	Mes("The next time I heard something it turned out to be you walking towards me.")
	SetQuest(QUEST_ID, ProgressCommons.MINE_EXPLORATION.STRANGER_SPOTTED)

func OnRemindStranger():
	Mes("It sounded like he was walking in water. Then I heard crumbling rocks.")
	Mes("There must be a crack in the walls somewhere below this ledge. That's where he disappeared.")

func OnComplete():
	Mes("I'm glad you found me. I was worried that the man would come back to finish me.")
