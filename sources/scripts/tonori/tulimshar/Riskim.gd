extends NpcScript

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
	Mes("The desert swallowed Tulimshar's farmland long ago. Nothing grows out here but cactus.")
	Mes("I have my flour shipped in from Artis to keep baking. My Sandstorm Bread has fed this city through many a dry spell.")
	Mes("A delivery arrived at the docks this morning, but these old knees aren't up for the walk.")
	Mes("My crates bear a blue wax seal from Artis. Could you fetch them for me?")

	QuestChoice()

func QuestChoice(previousChoice : int = -1):
	Choice("I'll check the docks for you.", OnAccept)
	if previousChoice != 1:
		Choice("What's Sandstorm Bread?", OnAskBread)
	if previousChoice != 2:
		Choice("Does anything grow out here?", OnAskDesert)
	Choice("Maybe later.", OnDecline)

func OnKeepLooking():
	Mes("Any luck at the docks? Look for crates marked with a blue Artis seal.")
	Mes("I'll have the ovens hot and ready.")

func OnComplete():
	Mes("Good bread can make even the harshest desert feel like home.")
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
	Mes("My signature recipe! Flour from Artis, cactus honey, and a pinch of desert salt.")
	Mes("The crust holds through sandstorms and still tastes fresh the next morning. That's how it earned the name.")
	if IsQuestCompleted(ProgressCommons.Quest.GRAIN_IN_THE_SAND):
		CompleteChoice(2)
	else:
		QuestChoice(1)

func OnAskDesert():
	Mes("Cactus, mostly. Hardy plants, and we make good use of them. Candy, drinks, even medicine.")
	Mes("But grain? The sands took the last of the outer fields years ago. Without the trade ships, this city would go hungry.")
	if IsQuestCompleted(ProgressCommons.Quest.GRAIN_IN_THE_SAND):
		CompleteChoice(3)
	else:
		QuestChoice(2)

func OnAskArtis():
	Mes("Great port city across the ocean, on the Aurora coast. Rich farmland, skilled artisans.")
	Mes("Their merchant ships keep half of Tulimshar's market stocked. Without them, we'd have little more than cactus to eat.")
	CompleteChoice(0)

func OnAskCity():
	Mes("Trading. When the harvests failed, the city turned to commerce to survive.")
	Mes("We sit at the crossroads of three continents. Everything passes through Tulimshar's port sooner or later.")
	Mes("It keeps us fed, but it means we're always waiting on the next ship to come in.")
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
	Mes("You found them! Wonderful.")
	Mes("With this flour, Tulimshar will have fresh Sandstorm Bread by sundown.")

	SetQuest(ProgressCommons.Quest.GRAIN_IN_THE_SAND, ProgressCommons.GRAIN_IN_THE_SAND.REWARDS_WITHDREW)

	AddItem(cactusSourCandyID, 5)
	AddItem(croissantID, 5)
	AddKarma(1)
	AddExp(20)

	Mes("Here, take some of my best. Croissants and cactus candy, fresh from this morning.")
