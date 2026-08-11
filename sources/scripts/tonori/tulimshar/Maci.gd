extends NpcScript

#
func OnStart():
	if own.stat and own.stat.level < 5:
		Mes("Oh, a new face! Welcome to Tulimshar.")
		Mes("Name's %s. I help people find their footing around here." % npc.nick)
		Mes("Insults are not welcomed here, just so you know. We look after each other in this city.")
	else:
		Mes("Need to know where something is? Ask away.")
	OnMainChoice()

# Main choice loop
func OnMainChoice():
	Choice("Tell me about the city.", OnCityOverview)
	Choice("How is it to live here?", OnLiveHere)
	Choice("I have to go.", Farewell)

# Answers
func OnCityOverview():
	Mes("Tulimshar sits in the valley that lies between our eastern and western hills.")
	Mes("The wall you see around us keeps the desert out from wildness and protects us from that southern sandstorm.")
	Mes("We mostly stay within that area, most people live and work in the central district which spreads between here and the port to the north.")
	Mes("That northern part is your best bet for anything you could need, markets, games, the lot.")
	OnMainChoice()

func OnLiveHere():
	Mes("The community is very close-knit.")
	Mes("We try to help each other and it's great to have people who care about each other's interests.")
	OnMainChoice()

# Farewell
func Farewell():
	Chat("Keep up the good work %s." % own.nick)
