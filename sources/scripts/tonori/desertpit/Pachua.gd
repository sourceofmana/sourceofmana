extends NpcScript

#
const COST_GP : int = 10000
const SNAKE_SKIN_AMOUNT : int = 10

#
func OnStart():
	Mes("For generations my tribe has been crafting special clothes out of different materials.")
	Mes("Maybe if you bring me the right ones I could make something for you.")
	Choice("What can you make?", OnShowRecipe)
	Choice("Where is your tribe?", OnAskTribe)
	Choice("What happened to this land?", OnAskLand)
	Choice("Maybe later.", OnFarewell)

func OnShowRecipe():
	Mes("I don't have all my tools here, let me think... Does a pair of jean chaps interest you?")
	Mes("For that I would need a regular Jeans Shorts and about 10 Snake Skins as those tends to tear when we manipulate them.")
	Mes("Do we have a deal?")
	Choice("Yes, that's fine.", OnAttemptCraft)
	Choice("On second thought, maybe later.", OnNoDeal)

func OnAttemptCraft():
	var shortsID : int = DB.GetCellHash("Shorts")
	var snakeSkinID : int = DB.GetCellHash("Snake Skin")
	var chapsID : int = DB.GetCellHash("Jean Chaps")

	if not HasItem(shortsID):
		Mes("Oh dear, it seems you don't have any jeans shorts.")
		return
	if not HasItem(snakeSkinID, SNAKE_SKIN_AMOUNT):
		Mes("Oh dear, it seems you don't have enough snake skins.")
		return

	RemoveItem(shortsID)
	RemoveItem(snakeSkinID, SNAKE_SKIN_AMOUNT)
	AddItem(chapsID)
	Mes("Here you are!")
	Mes("Come back any time.")

func OnAskTribe():
	Mes("We are living in the desert cliff, west from here. The road is not open to outsiders.")
	Mes("I come out here to trade. That is as far as most strangers get.")

func OnAskLand():
	Mes("The kingdom pulled out of this land a long time ago. Said it was not worth keeping.")
	Mes("My people were here before them and we are still here today. We trade with Tulimshar when we need to but otherwise we prefer to keep our distances.")

func OnNoDeal():
	Mes("Alright, but you won't get a better deal anywhere else!")

func OnFarewell():
	Chat("Come back when you're ready.")
