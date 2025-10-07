extends NpcScript

#
func OnStart():
	match randi_range(0, 2):
		0: TicTacToe()
		1: Mes("I can't draw round circles, so I just draw squares instead. But Andi keeps making fun of me.")
		2: Mes("I saw a pirate crew playing tic-tac-toe against some guards the other day.")

func TicTacToe():
	Mes("Do you know how to play tic-tac-toe?")
	Choice("Sure", TicTacYes)
	Choice("No", TicTacNo)

func TicTacYes():
	Chat("Grab a clay and draw with me!")

func TicTacNo():
	Chat("Cool! Then I can beat you easily!")
