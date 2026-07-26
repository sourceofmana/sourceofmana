extends NpcScript

# Quest items
var artisFlourSackID : int			= DB.GetCellHash("Artis Flour Sack")

# Reward items
var croissantID : int				= DB.GetCellHash("Croissant")
var cactusSourCandyID : int			= DB.GetCellHash("Cactus Sour Candy")

#
func OnStart():
	var questState : int = GetQuest(ProgressCommons.Quest.GRAIN_IN_THE_SAND)
	match questState:
		ProgressCommons.GRAIN_IN_THE_SAND.INACTIVE:
			OnInactive()
		ProgressCommons.GRAIN_IN_THE_SAND.SEARCHED_CRATES:
			OnReward()
		ProgressCommons.GRAIN_IN_THE_SAND.REWARDS_WITHDREW:
			OnComplete()
		_:
			OnKeepLooking()

# Quest states
func OnInactive():
	Mes("Ah, welcome! I'm afraid the shelves are empty at the moment.")
	Mes("Tulimshar doesn't have any good farmland. As you can see around you, we're in a desert. Nothing grows out here but cactus.")
	Mes("I have my flour shipped in from Artis to keep my bakery running. My Sandstorm Bread has fed this city for many years.")
	Mes("A delivery arrived at the docks this morning, but walking back and forth in this heat is exhausting.")
	Mes("If I go myself, I'll be too tired to bake anything today.")
	Mes("The barrels from the Artis bakery are marked by a blue wax seal. Could you bring me the flour bags that are inside?")

	QuestChoice()

func QuestChoice(previousChoice : int = -1):
	Choice("I'll check the docks for you.", OnAccept)
	if previousChoice != 1:
		Choice("What's Sandstorm Bread?", OnAskBread)
	if previousChoice != 2:
		Choice("Does anything grow out here?", OnAskDesert)
	Choice("Maybe later.", OnDecline)

func OnKeepLooking():
	Mes("Any luck at the docks? Look for barrels marked with a blue seal.")
	Mes("I'll have the ovens hot and ready.")

func OnComplete():
	Mes("Even in this heat, a warm loaf of bread is hard to pass on.")
	CompleteChoice()

func CompleteChoice(previousChoice : int = -1):
	if previousChoice != 0:
		Choice("Tell me about Artis.", OnAskArtis)
	if previousChoice != 1:
		Choice("How does Tulimshar survive?", OnAskCity)
	if previousChoice != 2:
		Choice("What's Sandstorm Bread?", OnAskBread)
	if previousChoice != 3:
		Choice("Does anything grow out here?", OnAskDesert)
	if previousChoice != -1:
		Choice("Take care.", OnFarewell)

# Optional dialogue
func OnAskBread():
	Mes("My signature recipe! Flour from Artis, cactus juice instead of regular water and a pinch of desert salt.")
	Mes("The crust holds through sandstorms and still tastes fresh the next morning. That's how it earned the name.")
	if IsQuestCompleted(ProgressCommons.Quest.GRAIN_IN_THE_SAND):
		CompleteChoice(2)
	else:
		QuestChoice(1)

func OnAskDesert():
	Mes("Cactus, mostly. Hardy plants, and we make good use of them. Candy, drinks, even medicine.")
	Mes("But grain? Tonori has never been the place to grow grain. Without the trade ships, this city would go hungry.")
	if IsQuestCompleted(ProgressCommons.Quest.GRAIN_IN_THE_SAND):
		CompleteChoice(3)
	else:
		QuestChoice(2)

func OnAskArtis():
	Mes("Great port city across the ocean, on the Aurora coast. Rich farmland, skilled artisans.")
	Mes(" My sister lives there. She bakes the most delicious cookies! The flour I get is shipped from her bakery.")
	Mes("The merchant ships from Artis keep half of Tulimshar's market stocked. Without them, we'd have little more than cactus to eat.")
	CompleteChoice(0)

func OnAskCity():
	Mes("Trading. It has always been Tulimshar's greatest skill. How else does a city like this thrive in a windy desert valley?")
	Mes("We sit at the crossroads of three continents. Everything passes through Tulimshar's port sooner or later.")
	Mes("It also keeps us fed, but for a business like mine it means always waiting on the next ship to come in.")
	CompleteChoice(1)

func OnFarewell():
	Mes("Stop by anytime. There's always a fresh loaf waiting.")

# Transitions to next states
func OnAccept():
	SetQuest(ProgressCommons.Quest.GRAIN_IN_THE_SAND, ProgressCommons.GRAIN_IN_THE_SAND.STARTED)

	Mes("Much appreciated, friend.")
	Mes("Look for the deep blue seal. You can't miss it.")

func OnDecline():
	Mes("No trouble. The ovens will wait, then.")

func OnReward():
	if not HasItem(artisFlourSackID):
		Mes("Have you checked the docks? The flour sacks should be inside the barrel with the blue seal.")
		return

	if not HasItemsSpace([[artisFlourSackID, -1], [cactusSourCandyID, 5], [croissantID, 5]]):
		Mes("You found them! But it looks like your bag is too full for me to give you anything in return.")
		Mes("Free up some space and come back.")
		return

	RemoveItem(artisFlourSackID)
	SetQuest(ProgressCommons.Quest.GRAIN_IN_THE_SAND, ProgressCommons.GRAIN_IN_THE_SAND.REWARDS_WITHDREW)

	Mes("You found them! Wonderful.")
	Mes("With this flour, Tulimshar will have fresh Sandstorm Bread by sundown.")

	AddItem(cactusSourCandyID, 5)
	AddItem(croissantID, 5)
	AddKarma(1)
	AddExp(30)

	Mes("Here, take some of my best. Croissants and cactus candy. One is a family recipe and the other one I invented myself!")
