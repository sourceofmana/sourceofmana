extends NpcScript

func OnStart():
	match GetQuest(WaterPondGlobal.QUEST_ID):
		ProgressCommons.SNAKE_PIT_BITING_THIRST.STARTED:
			Mes("This water is filthy! You do not think this is the pond Mauro had in mind.")
