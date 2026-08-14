extends NpcScript

#
func OnStart():
	Mes("Welcome aboard, or close enough.")
	Mes("I'm the captain of La Johanne, the vessel docked right behind me.")
	Mes("We are currently enjoying a well earned break far from cold weathers, as we've spent the last few weeks up north in the Kaizei region.")
	MainChoices()

func MainChoices():
	Choice("Can you take me somewhere by sea?", OnSailOffer)
	Choice("Tell me about yourself.", OnAbout)
	Choice("Safe travels, Captain.", Farewell)

func OnSailOffer():
	Mes("We are sailing towards Candor soon, but in the meantime we can go for a short trip wherever you want.")
	Mes("Our ship is sturdy and fast. We've travelled almost every shore on Aemil. Even as far as Thermin one time!")
	Mes("When you're ready to go, head to La Johanne's helm. There we can discuss where exactly you want to go.")
	Mes("It's been a while since I've ferried someone out to sea. We usually handle cargo, not people.")
	Choice("Where can you take me?", OnDestinations)
	Choice("Let me think about it.", MainChoices)

func OnDestinations():
	Mes("Candor to the north, the Manayir coast west from here, or all the way to Artis on the north-east.")
	Mes("For any other destination we'd need to prepare for a little longer.")
	Mes("I wouldn't want to be paying Esperia's harbour fees without good reason! Or Hurnscald for that matter.")
	MainChoices()

func OnAbout():
	Mes("I started out as carpenter in the port of Artis. I didn't have much at the time, but I was good at my job.")
	Mes("I even taught some students at one point.")
	Mes("Eventually I made enough to buy my own ship. It was almost a wreck, but I worked on it day and night until it was ready to sail again.")
	Mes("I got some friends together: Gado, Julia and my old pal Magic Arpan. We had all worked together before at the port.")
	Mes("We named our ship La Johanne. After its previous captain. I know you're not supposed to rename a ship, but I did almost rebuild it after all.")
	Mes("Now we make our living going from coast to coast, ferrying goods back and forth. For a fair price too, I'd say.")
	Choice("Do you miss Artis?", OnMissOldLife)
	Choice("Tell me about your crew.", OnCrew)
	Choice("Back to it.", MainChoices)

func OnMissOldLife():
	Mes("The greatest city in the world, if you ask me. The atmosphere, the people, the wine...")
	Mes("I do miss it, but we get to go back often, even if it's not for long. Lots of goods come in and out of Artis.")
	Mes("I miss my students though. Maybe one day I'll go back to teaching. Who knows?")
	MainChoices()

func OnCrew():
	Mes("I had known some of them for a long time. Gado was my first mate for a time.  Julia was my cook.")
	Mes("Problem was, Gado likes to argue and he's a great cook. Julia likes her peace... and she's terrible in the kitchen! So, I swapped them around.")
	Mes("Magic Arpan... how could I not have him on board? We've been good friends for years. He's a charming guy. Literally, he can charm you with magic!")
	Mes("All the others I picked up over time. People whose attitude I like. Everyone on board is with me for a reason.")
	Mes("They're all useful and important... except maybe for Silvio. He's just here to drink and flirt with Julia, that old drunk!")
	MainChoices()

func Farewell():
	Chat("Goodbye for now! Come back whenever you want to talk. I like good company.")
