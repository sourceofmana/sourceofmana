extends NpcScript

# Quest
const QUEST_ID : int				= ProgressCommons.Quest.VINCENT_BUGLEG

# Requirement
const QUEST_LEGS : int				= 8

# Rewards
const QUEST_CANDY : int				= 1
const QUEST_BOTTLE : int			= 1
const QUEST_EXP : int				= 25

# Quest items
var bugLegID : int					= DB.GetCellHash("Bug Leg")

# Reward items
var candyID : int					= DB.GetCellHash("Cactus Sour Candy")
var bottleID : int					= DB.GetCellHash("Bottle")

#
func OnStart():
	var questState : int = GetQuest(QUEST_ID)
	match questState:
		ProgressCommons.VINCENT_BUGLEG.INACTIVE:
			OnInactive()
		ProgressCommons.VINCENT_BUGLEG.STARTED:
			OnGathering()
		_:
			OnComplete()

# Helpers
func HasRoomForRewards() -> bool:
	return HasItemsSpace([[bugLegID, -QUEST_LEGS], [candyID, QUEST_CANDY], [bottleID, QUEST_BOTTLE]])

# Quest states
func OnInactive():
	Narrate("The child is holding a clay figurine. It looks like a legless scorpion.")
	Mes("I'm making an action figure. I'm almost done with it. It will look like one of those scary scorpions.")

	match randi_range(0, 3):
		0: Mes("I just need %d more bug legs to finish my action figure!" % QUEST_LEGS)
		1: Mes("This scorpion action figure is awesome! I just need to attach %d bug legs." % QUEST_LEGS)
		2: Mes("This will be a great action figure! A must have! All I need is a few parts...")
		_: Mes("Can you get me %d bug legs? I need them to complete my scorpion figure." % QUEST_LEGS)

	Mes("Will you help me find %d bug legs?" % QUEST_LEGS)
	Choice("Yes.", OnAccept)
	Choice("No.", Farewell)

func OnGathering():
	if not HasItem(bugLegID, QUEST_LEGS):
		OnKeepLooking()
		return

	if not HasRoomForRewards():
		Mes("Your bag is really full! I can't give you anything if you can't carry it.")
		return

	Mes("Excellent! Finally I can complete the model. Thank you so so much!")

	RemoveItem(bugLegID, QUEST_LEGS)
	SetQuest(QUEST_ID, ProgressCommons.VINCENT_BUGLEG.REWARDS_WITHDREW)

	Mes("Mhm... I don't really have any money...")
	Think("Vincent thinks to himself and runs through his pockets.")

	Mes("I suppose you can have this candy. I haven't licked it. I promise!")
	AddItem(candyID, QUEST_CANDY)

	Mes("And this bottle too. I did drink the cactus juice that was in there, though.")
	AddItem(bottleID, QUEST_BOTTLE)

	AddExp(QUEST_EXP)

func OnKeepLooking():
	Mes("Please help me collect %d bug legs! I need them to complete my action figure." % QUEST_LEGS)

func OnComplete():
	Mes("Andi said it was the coolest scorpion figure he ever saw! Thanks for getting me those bug legs.")

# Transitions to next states
func OnAccept():
	SetQuest(QUEST_ID, ProgressCommons.VINCENT_BUGLEG.STARTED)

	match randi_range(0, 3):
		0: Mes("Thank you! My scorpion will look so scary!")
		1: Mes("Thanks! I just need to think of a good way to attach them now...")
		2: Mes("I can't wait! I want to show it to Andi when it's done.")
		_: Mes("Using real insect legs will look better, don't you think?")

	Mes("Now I just need those %d bug legs." % QUEST_LEGS)
