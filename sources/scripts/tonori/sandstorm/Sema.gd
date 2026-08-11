extends NpcScript

#
func OnStart():
	if randi() % 2:
		Mes("This place doesn't feel right.")
		Mes("It has an eerie feel to it. Maybe it's just because it was abandoned for so long?")
		Mes("Or maybe it's why it was abandoned in the first place...")
	else:
		Mes("I heard some noises coming from further below. I really don't want to go there...")
