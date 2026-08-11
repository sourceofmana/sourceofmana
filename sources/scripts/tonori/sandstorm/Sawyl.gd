extends NpcScript

#
func OnStart():
	Mes("If you follow this road the the east you'll be leaving the Tulimshar Valley and heading towards the Manayir Coast.")
	Mes("Are you lost?")
	DisplayChoices()

func DisplayChoices(hideChoice : int = -1):
	if hideChoice != 1:
		Choice("I am looking for the Sandstorm Mines.", OnMines)
	if hideChoice != 2:
		Choice("What can you tell me about this valley?", OnValley)
	if hideChoice != 3:
		Choice("What can you tell me about the Manayir Coast?", OnManayir)
	if hideChoice != 4:
		Choice("Thank you for your time.", Farewell)

func OnMines():
	LookAtNpc("To Mines")
	Mes("You'll find them directly south of here.")
	ResetCamera()
	Mes("They've been abandonded for a long time, but I just saw a group of people heading in that direction earlier.")
	Mes("Looked like Tulimshar folks. I wonder what they're up to...")
	DisplayChoices()

func OnValley():
	Mes("Tulimshar Valley is a low-lying protected area where the city of Tulimshar hides from the open Tonori Desert.")
	Mes("The city walls close off the city between the valley and the open sea.")
	Mes("Apart from the sand storm that blows through the valley, this area is relatively safe compared to farther parts of Tonori where all sorts of dangers hide among the hot sands.")
	DisplayChoices()

func OnManayir():
	Mes("It's a quiet area of Tonori close to the sea. It probably has the mildest climate out of any area in this desert.")
	Mes("The most notable feature is the peninsula that extends from the beach.")
	Mes("We call it Nawah in our language. It's where the Manayir Order makes their home.")

	Choice("Manyir Order?", OnManayirOrder)
	DisplayChoices(3)

func OnManayirOrder():
	Mes("They are a powerful organisation of wise mages and experts of Mana. They have been around for a very long time, almost as long as my people.")
	Mes("Our old tales talk of how they used to rule Tulimshar in ancient times. Now they mostly keep to themselves.")
	Mes("We trade with them occasionally and we have always shared our knowledge and admiration of The Spirit - Mana - with them.")
	DisplayChoices()
