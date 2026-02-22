extends NpcScript

#
func OnStart():
	match GetQuest(ProgressCommons.Quest.GRAIN_IN_THE_SAND):
		ProgressCommons.GRAIN_IN_THE_SAND.STARTED:
			Chat("A sealed barrel.")
