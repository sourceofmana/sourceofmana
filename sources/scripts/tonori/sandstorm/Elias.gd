extends NpcScript

#
func OnStart():
	Mes("If you follow the western pass right there you'll leave Tulimshar Valley and venture into the Zuni Mesas.")
	Mes("Do you know where you're going?")
	Choice("I am looking for the Sandstorm Mines.", OnMines)
	Choice("I am looking for Tulimshar.", OnTulimshar)

func OnMines():
	LookAtNpc("To Mines")
	Mes("If you follow this road you will be walking further away from the Sandstorm Mines.")
	ResetCamera()
	Mes("You should head back west and aim for the southern side of this valley.")

func OnTulimshar():
	LookAtNpc("To Tulimshar")
	Mes("You can follow that path to the north up to the city wall.")
	ResetCamera()
	Mes("You can't miss it, the city wall is almost visible from there!")
