extends NpcScript

#
func OnStart():
	Mes("What do you need help with?")
	OnMainChoice()

# Main choice loop
func OnMainChoice():
	Choice("Where is the port?", OnPort)
	Choice("What's along the coast?", OnEast)
	Choice("I have to go.", Farewell)

# Answers
func OnPort():
	Mes("Head north. You'll get there.")
	Mes("The port is where most goods come in from outside Tonori.")
	Mes("It's usually busy, I wouldn't mess with sailors while they work if I were you.")
	Mes("Personally, I'd rather stay near the castle than deal with that crowd.")
	OnMainChoice()

func OnEast():
	Mes("Long stretch of beach to the east. If you like sand, you'll love it. Not everyone likes sand though...")
	Mes("Northeast of here there's a large lighthouse. It overlooks the whole ocean from up there.")
	Mes("Hard to miss, useful landmark.")
	Mes("If you keep going east you will find Manayir Island, just further along the beach.")

	OnMainChoice()
