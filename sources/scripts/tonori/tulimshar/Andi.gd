extends NpcScript

#
func OnStart():
	match randi_range(0, 5):
		0: SeenClay()
		1: GoingToSea()
		2: Circles()
		3: Chat("Oh, I really like that stone!")
		4: Chat("Beware of hiding pirates, they are dangerous.")
		5: Chat("Don't wipe away the chalk, please!")

func SeenClay():
	Mes("Have you seen my chalk?")
	Mes("I bet the guards took it to play with on their own.")

func GoingToSea():
	Mes("One day, I'm going to the sea to explore the world.")
	Mes("I heard there's a city to the north with cold, white sand.")

func Circles():
	Mes("Can you draw a perfect circle? I can! My dad taught me.")
	Mes("Wie can't draw circles. When she tries they look like fat squares.")
	Mes("They look so funny, but she doesn't like when I laugh at them, so she always wants to be the X.")
	Mes("I started calling her "the wild X".")
