extends NpcScript

#
func OnStart():
	var questState : int = GetQuest(ProgressCommons.Quest.TUTORIAL)
	if questState == ProgressCommons.TUTORIAL.ELANORE_DONE:
		OnSendToKael()
	else:
		Mes("Good to see you up and about. Stay safe out there.")

func OnSendToKael():
	Mes("Have you seen the maggots we have to deal with?")
	Mes("Disgusting creatures. They say that in the past they used to be smaller.")
	Mes("Our cactus farmers are the most affected by them. The recent increase in the maggots' population has caused a lot of damage to their crops.")
	LookAtNpc("Kael")
	Mes("Watchman Kael is stationed east of here, by one of the cactus farms.")
	ResetCamera()
	Mes("If you want to be useful and repay the kindness of those guards who rescued you, you should help Kael clear out some maggots.")
