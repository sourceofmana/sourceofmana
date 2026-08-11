extends NpcScript

var artisFlourSackID : int			= DB.GetCellHash("Artis Flour Sack")

#
func OnStart():
	match GetQuest(ProgressCommons.Quest.GRAIN_IN_THE_SAND):
		ProgressCommons.GRAIN_IN_THE_SAND.STARTED:
			OnSearch()

func OnSearch():
	Mes("A deep blue wax seal stamped with the Artis crest. This is the one.")
	Mes("Inside, sacks of fine milled flour, just as Riskim described.")

	if not HasSpace(1):
		Mes("But your bag is too full to carry them.")
		return

	SetQuest(ProgressCommons.Quest.GRAIN_IN_THE_SAND, ProgressCommons.GRAIN_IN_THE_SAND.SEARCHED_CRATES)
	AddItem(artisFlourSackID)
