extends NpcScript

#
func OnStart():
	Mes("Being stationed in this inner wall section is the best thing you could expect.")
	Mes("I can stay in the shade all day and rest while other guards keep the wildlife outside our walls.")
	Mes("All I have to do is to prevent people from bothering our queen while she works on her garden.")
	OnMainChoice()

# Main choice loop
func OnMainChoice():
	Choice("What's this large building?", OnCastle)
	Choice("What's to the west?", OnWest)
	Choice("What's to the south?", OnSouth)
	Choice("I have to go.", Farewell)

# Answers
func OnCastle():
	Mes("That's the Red Queen's castle.")
	Mes("You can request an audience to Her Majesty if you have something important to say but I wouldn't recommend to distract her from her gardens.")
	Mes("You can also find the second largest library from the continent, it almost matches the number of books from the Manayir tower!")
	OnMainChoice()

func OnWest():
	Mes("ARGH.")
	Mes("...Sorry. That region just irritates me.")
	Mes("It's dangerous. Lots of snakes, and that's the friendly part. Some native people live out there too, I don't want to deal with them, I heard they eat raw birds and dance with their feathers.")
	Mes("Stick to the paths if you have to go. Better yet, don't.")
	OnMainChoice()

func OnSouth():
	Mes("You can find our old cactus fields and habitation outside these walls, they are completely uninhabited.")
	Mes("The sandstorm ate all of it and forced us to barricade ourselves at the end of the valley.")
	Mes("That's not ideal as that sandstorm keeps getting bigger year after year.")
	OnMainChoice()
