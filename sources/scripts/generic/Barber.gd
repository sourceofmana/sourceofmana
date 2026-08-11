extends NpcScript

#
func OnStart():
	Mes("Would you like to change your hair style or color today?")
	Choice("I want to try another style", OnHairstyle)
	Choice("A new color", OnHaircolor)
	Choice("None", OnQuit)

func OnHairstyle():
	var hairstyles : Array[HairstyleData] = DB.HairstylesDB.values()
	var count : int = hairstyles.size() -1
	var randIdx : int = randi_range(0, count)

	var newStyleIdx : int = hairstyles[randIdx]._id
	if newStyleIdx == own.stat.haircolor:
		randIdx = (randIdx + 1) % (count + 1)
		newStyleIdx = hairstyles[randIdx]._id
	own.stat.SetHairstyle(newStyleIdx)

	Choice("Another style", OnHairstyle)
	Choice("Perfect!", OnQuit)

func OnHaircolor():
	var haircolors : Array = DB.PalettesDB[DB.Palette.HAIR].values()
	var count : int = haircolors.size() - 1
	var randIdx : int = randi_range(0, count)

	var newColorIdx : int = haircolors[randIdx]._id
	if newColorIdx == own.stat.haircolor:
		randIdx = (randIdx + 1) % (count + 1)
		newColorIdx = haircolors[randIdx]._id
	own.stat.SetHaircolor(newColorIdx)

	Choice("Another color", OnHaircolor)
	Choice("Perfect!", OnQuit)
