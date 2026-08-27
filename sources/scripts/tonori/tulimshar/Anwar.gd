extends NpcScript

# Quest
const QUEST_ID : int				= ProgressCommons.Quest.ANWAR_FIELD
const PESTICIDE_ID : int			= ProgressCommons.Quest.ANWAR_PESTICIDE

# Requirements
const MIN_LEVEL : int				= 3
const QUEST_BUGLEGS : int			= 24
const QUEST_SLIMES : int			= 12
const QUEST_STINGERS : int			= 6
const QUEST_POTIONS : int			= 1

# Rewards
const QUEST_DRINKS : int			= 6
const QUEST_PITAYAS : int			= 6
const QUEST_EXP : int				= 150
const PESTICIDE_EXP : int			= 100
const REPEAT_EXP : int				= QUEST_EXP + PESTICIDE_EXP

# Quest items
var bugLegID : int					= DB.GetCellHash("Bug Leg")
var maggotSlimeID : int				= DB.GetCellHash("Maggot Slime")
var stingerID : int					= DB.GetCellHash("Scorpion Stinger")
var cactusPotionID : int			= DB.GetCellHash("Cactus Potion")

# Reward items
var cactusDrinkID : int				= DB.GetCellHash("Cactus Drink")
var pitayaID : int					= DB.GetCellHash("Pitaya")

#
func OnStart():
	if own.stat and own.stat.level < MIN_LEVEL:
		Mes("The insects out there would make short work of you. Come back once you have grown into level %d." % MIN_LEVEL)
		return

	var questState : int = GetQuest(QUEST_ID)
	match questState:
		ProgressCommons.ANWAR_FIELD.INACTIVE:
			OnInactive()
		ProgressCommons.ANWAR_FIELD.STARTED:
			OnGathering()
		_:
			OnComplete()

# Helpers
func NeedsPotion() -> bool:
	return GetQuest(PESTICIDE_ID) == ProgressCommons.ANWAR_PESTICIDE.REWARDS_WITHDREW

func HasQuestParts() -> bool:
	return HasItem(bugLegID, QUEST_BUGLEGS) and HasItem(maggotSlimeID, QUEST_SLIMES) and HasItem(stingerID, QUEST_STINGERS)

func HasDelivery() -> bool:
	return HasQuestParts() and (not NeedsPotion() or HasItem(cactusPotionID, QUEST_POTIONS))

func HasRoomForRewards() -> bool:
	var items : Array = [[bugLegID, -QUEST_BUGLEGS], [maggotSlimeID, -QUEST_SLIMES], [stingerID, -QUEST_STINGERS], [cactusDrinkID, QUEST_DRINKS], [pitayaID, QUEST_PITAYAS]]
	if NeedsPotion():
		items.append([cactusPotionID, -QUEST_POTIONS])
	return HasItemsSpace(items)

func CanDeliverToday() -> bool:
	return npc.ownScript == null or npc.ownScript.CanTurnInDaily(own.get_rid().get_id())

func GetRequirementText() -> String:
	if NeedsPotion():
		return "%d Bug Legs, %d Maggot Slimes, %d Scorpion Stingers and a Cactus Potion" % [QUEST_BUGLEGS, QUEST_SLIMES, QUEST_STINGERS]
	return "%d Bug Legs, %d Maggot Slimes and %d Scorpion Stingers" % [QUEST_BUGLEGS, QUEST_SLIMES, QUEST_STINGERS]

# Quest states
func OnInactive():
	Narrate("A farmer is looking over his field. He seems to be thinking about something.")
	Mes("Have you noticed that all we grow here is cactus?")
	Mes("It is a difficult crop. Tonori farmers spent a long time turning it into something this useful.")
	Mes("My worry is that the dry air brought by the sandstorm will ruin our next harvest.")
	Mes("The benefit of having giant insects is that we can use their parts for fertiliser!")
	Mes("Bring me %s and I will have enough to mix for myself and for the other farmers." % GetRequirementText())
	Choice("I'll gather them.", OnAccept)
	Choice("Not today.", OnDecline)

func OnGathering():
	if not HasDelivery():
		OnKeepLooking()
		return

	if not HasRoomForRewards():
		OnBagFull()
		return

	OnTurnIn()
	Action(OnCompleteContinue)

func OnKeepLooking():
	Mes("Not enough yet. I need %s for a full batch." % GetRequirementText())
	Mes("You can get these from scorpions or maggots. There are some in the city, but you'll find even more outside the city walls.")

func OnBagFull():
	Mes("You are carrying too much already. Set something down and come back, I have no way to hand you the harvest otherwise.")

func OnComplete():
	Mes("Welcome back. The cactus is growing strong for now!")
	CompleteChoice()

func OnCompleteContinue():
	Mes("Anything else?")
	CompleteChoice()

func CompleteChoice():
	if CanDeliverToday():
		if HasDelivery():
			Choice("I brought another delivery.", OnDailyTurnIn)
		else:
			Choice("Do you need any more help with your cactus?", OnDailyReminder)
	else:
		Choice("Do you need another delivery?", OnCooldown)

	match GetQuest(PESTICIDE_ID):
		ProgressCommons.ANWAR_PESTICIDE.INACTIVE:
			Choice("How are your fields dealing with the Peyote?", OnPesticideOffer)
		ProgressCommons.ANWAR_PESTICIDE.SENT_TO_ELANORE:
			Choice("About Elanore...", OnPesticideReminder)
		ProgressCommons.ANWAR_PESTICIDE.ELANORE_EXPLAINED:
			if HasItem(cactusPotionID, QUEST_POTIONS):
				Choice("Elanore made this for your field.", OnPesticideTurnIn)
			else:
				Choice("About Elanore's potion...", OnPesticideReminder)

	Choice("Good harvest, Anwar.", OnFarewell)

# Deliveries
func OnTurnIn():
	var withPotion : bool = NeedsPotion()

	Mes("That is everything. Enough fertiliser for my rows and a few of my neighbours' as well.")

	RemoveItem(bugLegID, QUEST_BUGLEGS)
	RemoveItem(maggotSlimeID, QUEST_SLIMES)
	RemoveItem(stingerID, QUEST_STINGERS)

	if withPotion:
		RemoveItem(cactusPotionID, QUEST_POTIONS)
		Mes("And the potion goes straight into the barrel. That should keep the Kaore out of the crop for another season.")

	SetQuest(QUEST_ID, ProgressCommons.ANWAR_FIELD.REWARDS_WITHDREW)

	Mes("Take some of the harvest for your trouble.")
	AddItem(cactusDrinkID, QUEST_DRINKS)
	AddItem(pitayaID, QUEST_PITAYAS)
	AddExp(REPEAT_EXP if withPotion else QUEST_EXP)

	if npc.ownScript:
		Action(npc.ownScript.StartCooldown.bind(own.get_rid().get_id()))

	Mes("I can always use more to sell to the other farmers. Come back tomorrow with another load.")

func OnDailyTurnIn():
	if not HasDelivery():
		OnDailyReminder()
		return

	if not HasRoomForRewards():
		OnBagFull()
		Action(OnCompleteContinue)
		return

	OnTurnIn()
	Action(OnCompleteContinue)

func OnDailyReminder():
	Mes("Same as always. %s, and one load a day is all I can work through." % GetRequirementText())
	Action(OnCompleteContinue)

func OnCooldown():
	Mes("Not today. What you brought last is still in the mixing barrel. Come back tomorrow.")
	Action(OnCompleteContinue)

# Pesticide
func OnPesticideOffer():
	Mes("That is one problem that is beyond my abilities. The Kaore makes them grow into Peyote rather than regular cactus.")
	Mes("Elanore might have a solution. She knows a lot about these things. Ask her whether she has something that could help my field.")
	SetQuest(PESTICIDE_ID, ProgressCommons.ANWAR_PESTICIDE.SENT_TO_ELANORE)
	Action(OnCompleteContinue)

func OnPesticideReminder():
	if GetQuest(PESTICIDE_ID) == ProgressCommons.ANWAR_PESTICIDE.SENT_TO_ELANORE:
		Mes("Elanore stands near the south gate of the city, receiving whoever comes in from the desert. Ask her about my field.")
	else:
		Mes("If she has a solution for my problem, come bring it to me.")
	Action(OnCompleteContinue)

func OnPesticideTurnIn():
	if not HasItem(cactusPotionID, QUEST_POTIONS):
		OnPesticideReminder()
		return

	Mes("Ah, the Mana infused into this potion will ward off Kaore. I knew Elanore would have the solution. Let me work it into the fertiliser.")
	RemoveItem(cactusPotionID, QUEST_POTIONS)
	SetQuest(PESTICIDE_ID, ProgressCommons.ANWAR_PESTICIDE.REWARDS_WITHDREW)
	AddExp(PESTICIDE_EXP)

	Mes("The soil already looks better. I'll put one of these in every batch of fertiliser now, so bring a Cactus Potion along with the insect parts if you want to help me again.")
	Action(OnCompleteContinue)

# Transitions to next states
func OnAccept():
	SetQuest(QUEST_ID, ProgressCommons.ANWAR_FIELD.STARTED)
	Mes("Good. The scorpions and the maggots will have plenty of legs and other parts on them.")

func OnDecline():
	Mes("The field will still be here.")

func OnFarewell():
	Chat("Try not to step on any young plants!")
