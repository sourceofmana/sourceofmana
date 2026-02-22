extends NpcScript

#
func OnStart():
	Mes("Would you like to change your hair style or color today?")
	Choice("I want to try another style", OnHairstyle)
	Choice("A new color", OnHaircolor)
	Choice("None", OnQuit)

func OnHairstyle():
	var hairstyles : Array[FileData] = DB.HairstylesDB.values()
	var count : int = hairstyles.size() -1
	var randomValue : int = -1
	while randomValue == -1 or randomValue == own.stat.hairstyle:
		randomValue = hairstyles[randi_range(0, count)]._id
	own.stat.hairstyle = randomValue

	Choice("Another style", OnHairstyle)
	Choice("Perfect!", OnQuit)


func OnHaircolor():
	var haircolors : Array = DB.PalettesDB[DB.Palette.HAIR].values()
	var count : int = haircolors.size() - 1
	var randomValue : int = -1
	while randomValue == -1 or randomValue == own.stat.haircolor:
		randomValue = haircolors[randi_range(0, count)]._id
	own.stat.haircolor = randomValue

	Choice("Another color", OnHaircolor)
	Choice("Perfect!", OnQuit)
