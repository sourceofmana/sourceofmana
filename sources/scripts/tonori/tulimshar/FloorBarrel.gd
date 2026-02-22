extends NpcScript

#
func OnStart():
	match GetQuest(ProgressCommons.Quest.GRAIN_IN_THE_SAND):
		ProgressCommons.GRAIN_IN_THE_SAND.STARTED:
			OnSearch()

func OnSearch():
	SetQuest(ProgressCommons.Quest.GRAIN_IN_THE_SAND, ProgressCommons.GRAIN_IN_THE_SAND.SEARCHED_CRATES)
	Mes("A deep blue wax seal stamped with the Artis crest. This is the one.")
	Mes("Inside, sacks of fine milled flour, just as Riskim described.")
