extends NpcScript

#
func OnStart():
	Mes("Hi! I'm Watchman Nathan.")
	Mes("I'm normally guarding the port of Tulimshar, but today I have the honour of GETTING ABSOLUTELY BAKED TO A CRISP OUT HERE.")
	Mes("Sorry. My bad.")
	Mes("The Sun is getting to me.")

	Choice("Is this the entrance to the Sandstorm Mines?", OnEntrance)

func OnEntrance():
	Mes("It is indeed! I can see why this place was abandoned.")
	Mes("I have sand in my teeth from the storm. I can only imagine what the miners who used to work here went though, walking here every day.")
	Mes("Now those people inside will have to deal with this.")
	Mes("I just hope I can go back to guarding the port. If they station me here permanently I might just go feed myself to a goblin.")

	Choice("I'm actually supposed to join them.", OnJoinThem)

func OnJoinThem():
	Mes("Really? You don't look like a miner. Where is your pickaxe?")

	Choice("I'm not here to mine, just scout the place.", OnJustScouting)

func OnJustScouting():
	Mes("Ah, I see.")
	Mes("Well, sorry for keeping you. It gets boring standing out here all alone.")
	Mes("Come on, go inside. They must be waiting for you.")

	Choice("Thanks Nathan. Have a nice day!", OnNiceDay)
	Choice("Don't burn out there.", Farewell)

func OnNiceDay():
	Chat("I'll have a great day when I can get back to staring at the sea! See you later.")
