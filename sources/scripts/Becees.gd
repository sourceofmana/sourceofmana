extends NpcScript

#
func OnStart():
	Mes("Hello there.")
	Mes("What do you want?")
	# Choice Context
	Choice("Choice 1", OnChoice1)
	Choice("Choice 2", OnChoice2)
	Choice("Nothing", Farewell)

func OnChoice1():
	Mes("OK for choice 1!")

func OnChoice2():
	Mes("OK for choice 2!")
