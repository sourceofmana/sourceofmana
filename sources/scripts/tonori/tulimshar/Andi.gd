extends NpcScript

#
func OnStart():
	match randi_range(0, 3):
		0: SeenClay()
		1: GoingToSea()
		2: Chat("Oh, I really like that stone!")
		3: Chat("Beware of hiding pirates, they are dangerous.")

func SeenClay():
	Mes("Have you seen my clay?")
	Mes("I bet the guards took it to play with on their own.")

func GoingToSea():
	Mes("One day, I'm going to the sea to explore the world.")
	Mes("I heard there's a city to the north with cold, white sand.")
