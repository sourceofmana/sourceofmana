extends NpcScript

# Quest
const QUEST_ID : int				= ProgressCommons.Quest.TULIMSHAR_GLASSMAKING

# Recipe

const SET_INGREDIENT : int			= 4
const QUEST_SETS : int				= 3
const QUEST_INGREDIENT : int			= SET_INGREDIENT * QUEST_SETS
const QUEST_REWARD : int			= QUEST_SETS
const QUEST_EXP : int				= 100
const TRADE_MAX : int				= 20

# Quest items
var saltID : int					= DB.GetCellHash("Salt")
var boneID : int					= DB.GetCellHash("Bone")
var sulphurID : int					= DB.GetCellHash("Sulphur Powder")

# Reward items
var bottleID : int					= DB.GetCellHash("Bottle")

#
func OnStart():
	var questState : int = GetQuest(QUEST_ID)
	match questState:
		ProgressCommons.TULIMSHAR_GLASSMAKING.INACTIVE:
			OnInactive()
		ProgressCommons.TULIMSHAR_GLASSMAKING.REWARDS_WITHDREW:
			OnComplete()
		_:
			OnGathering()

# Helpers
func HasSets(setCount : int) -> bool:
	return HasItem(saltID, setCount * SET_INGREDIENT) and HasItem(boneID, setCount * SET_INGREDIENT) and HasItem(sulphurID, setCount * SET_INGREDIENT)

func GetTradeCount() -> int:
	var tradeCount : int = 0
	while tradeCount < TRADE_MAX and HasSets(tradeCount + 1):
		tradeCount += 1
	return tradeCount

func HasRoomFor(setCount : int, bottleCount : int) -> bool:
	return HasItemsSpace([[saltID, -setCount * SET_INGREDIENT], [boneID, -setCount * SET_INGREDIENT], [sulphurID, -setCount * SET_INGREDIENT], [bottleID, bottleCount]])

func TakeMaterials(setCount : int):
	RemoveItem(saltID, setCount * SET_INGREDIENT)
	RemoveItem(boneID, setCount * SET_INGREDIENT)
	RemoveItem(sulphurID, setCount * SET_INGREDIENT)

# Quest states
func OnInactive():
	Mes("Hey! Are you new to the city? I don't think I've seen you before. My name is Eridu. I'm a glassmaker.")
	Mes("My family has always made glass. People find it useful to carry liquids out in this climate. That's why we mainly make bottles.")
	Mes("We make our glass from the sand of Tonori. We also use salt, bones and sulphur powder.")
	Mes("The sand is everywhere, as you can see, but the other components are harder to come by.")

	QuestChoice()

func QuestChoice(previousChoice : int = -1):
	Choice("I could get those things for you.", OnAccept)
	if previousChoice != 1:
		Choice("Why those three ingredients?", OnAskRecipe)
	if previousChoice != 2:
		Choice("Where can I find these things?", OnAskWhere)
	Choice("Not right now.", OnDecline)

func OnGathering():
	if not HasSets(QUEST_SETS):
		OnKeepLooking()
		return

	if not HasRoomFor(QUEST_SETS, QUEST_REWARD):
		Mes("You seem to be carrying a lot of stuff. Maybe get rid of some of that and come back.")
		return

	TakeMaterials(QUEST_SETS)
	SetQuest(QUEST_ID, ProgressCommons.TULIMSHAR_GLASSMAKING.REWARDS_WITHDREW)

	Mes("Salt, bones, sulphur. You seem to have everything!")
	Mes("I'll get to making some new bottles right away.")
	Mes("Meanwhile, I used up my last resources to make these. Take them.")

	AddItem(bottleID, QUEST_REWARD)
	AddExp(QUEST_EXP)

	Mes("%d bottles. Don't break them, they're fine Eridu glass!" % QUEST_REWARD)
	Think("Eridu laughs.")
	Mes("Bring me more materials any time. %d of each, and I will blow some more glass for you." % SET_INGREDIENT)

func OnKeepLooking():
	Mes("Still short, by my eye. %d of each material. Anything less and the mix won't work." % QUEST_INGREDIENT)
	Mes("Take your time. The furnace is not going anywhere and neither am I.")

func OnComplete():
	Mes("Back for some glass? Good to see you.")
	CompleteChoice()

func CompleteChoice(previousChoice : int = -1):
	if GetTradeCount() > 0:
		Choice("I brought more material.", OnTrade)
	elif previousChoice != 0:
		Choice("What do you need for another bottle?", OnTradeReminder)
	if previousChoice != 1:
		Choice("Why those three ingredients?", OnAskRecipe)
	if previousChoice != 2:
		Choice("Where would I find them?", OnAskWhere)
	if previousChoice != -1:
		Choice("Keep well, Eridu.", OnFarewell)

# Optional dialogue
func OnAskRecipe():
	Mes("Sand is the glass. We melt it and then we cool down the resulting liquid.")
	Mes("I have plenty of that, as you can see.")
	Mes("We use salt to bring down the melting temperature, so that it's not too hot for our clay pots. ")
	Mes("Then, we add calcium. That's the bones, crushed into a powder. This is essential so that the glass does not melt when in contact with water.")
	Mes("Finally, sulphur clears the bubbles and takes the green out.")
	Mes("Get the balance wrong and your glass will be weak. Or worse, ugly.")
	if IsQuestCompleted(QUEST_ID):
		CompleteChoice(1)
	else:
		QuestChoice(1)

func OnAskWhere():

	Mes("Slimes often have high concentration of salts. Sometimes salt crystals form inside them. It's not easier than letting sea water dry, but it can be faster.")
	Mes("Sulphur is trickier. The fire goblins out by the sandstorm carry it. I think that their body makes it. Maybe to produce their fire?")
	Mes("Bones will need to come from the reanimated corpses that wander certain areas. I've heard they're created by Kaore. Certainly better than digging into graves.")
	if IsQuestCompleted(QUEST_ID):
		CompleteChoice(2)
	else:
		QuestChoice(2)

func OnFarewell():
	Mes("Mind the heat on your way out.")

# Transitions to next states
func OnAccept():
	SetQuest(QUEST_ID, ProgressCommons.TULIMSHAR_GLASSMAKING.STARTED)

	Mes("Good. You have everything.")
	Mes("Bring them here and I will put %d bottles in your hands before they have finished cooling." % QUEST_REWARD)

func OnDecline():
	Mes("Suit yourself. The furnace keeps burning either way.")

# Repeatable exchange
func OnTradeReminder():
	Mes("It takes %d Salt, %d Bone and %d Sulphur Powder for one bottle. Twice that and you get two. It's simple, really." % [SET_INGREDIENT, SET_INGREDIENT, SET_INGREDIENT])
	CompleteChoice(0)

func OnTrade():
	var tradeCount : int = GetTradeCount()
	if tradeCount <= 0:
		OnTradeReminder()
		return

	Mes("Let me weigh what you have brought...")
	Choice("Just the one bottle.", OnExchange.bind(1))
	if tradeCount > 1:
		Choice("All of it, %d bottles." % tradeCount, OnExchange.bind(tradeCount))
	Choice("On second thought, I'll hold on to it.", OnComplete)

func OnExchange(bottleCount : int):
	if bottleCount <= 0 or not HasSets(bottleCount):
		OnTradeReminder()
		return

	if not HasRoomFor(bottleCount, bottleCount):
		Mes("Your bag is fit to burst. How are you going to put glass in there? Go empty some stuff out!")
		Action(OnComplete)
		return

	TakeMaterials(bottleCount)
	AddItem(bottleID, bottleCount)

	if bottleCount > 1:
		Mes("%d bottles. Try not to break them!" % bottleCount)
	else:
		Mes("One bottle. Don't go and break it now!")

	Action(OnComplete)
