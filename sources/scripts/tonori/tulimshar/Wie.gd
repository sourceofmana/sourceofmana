extends NpcScript

#
func OnStart():
	var globalScript : TicTacToeGlobal = (npc.ownScript as TicTacToeGlobal)
	match globalScript.startStep:
		TicTacToeGlobal.State.NONE:
			if steps.is_empty():
				match randi_range(0, 2):
					0: Mes("Do you want to play tic-tac-toe? I drew the board myself!")
					1:
						Mes("I can't draw round circles, so I just draw squares instead. But Andi keeps making fun of me.")
						Mes("Wanna play tic-tac-toe?")
					2:
						Mes("I saw a pirate crew playing tic-tac-toe against some guards the other day.")
						Mes("Wanna play?")
			else:
				Mes("Do you want to play tic-tac-toe?")
			Choice("Play against you", StartPvE)
			Choice("Play against someone else", StartPvP)
			Choice("How do you play?", ShowRules)
			Choice("Maybe later", Decline)
		TicTacToeGlobal.State.X:
			if globalScript.playerX != own:
				Mes("Hey, someone's already waiting to play! You should go against them!")
				Choice("I'll play them!", StartPvP)
				Choice("How do you play?", ShowRules)
				Choice("Maybe later", Decline)
			else:
				Mes("Nobody showed up yet... Wanna keep waiting?")
				Choice("I'll wait a bit more", WaitPvP)
				Choice("How do you play?", ShowRules)
				Choice("I have to go", CancelPvP)
		TicTacToeGlobal.State.O:
			var isPlaying : bool = globalScript.playerX == own or globalScript.playerO == own
			if isPlaying:
				Mes("Hey, no cheating! Go play your game!")
			else:
				Mes("Shhh, they're playing! You can watch though.")
			Choice("Ok ok", OnQuit)
			Choice("How do you play?", ShowRules)
			if isPlaying:
				Choice("I have to go", CancelPvP)

func ShowRules():
	Mes("So you pick a square and put your mark on it, then the other person goes.")
	Mes("If you get three in a row you win! Like across, up and down, or the diagonal ones.")
	Mes("And if the whole board fills up and nobody won, it's a tie. Those are boring though.")
	OnStart()

func Decline():
	Chat("Okaaay... Come back if you change your mind!")

# Player vs NPC
func StartPvE():
	var globalScript : TicTacToeGlobal = (npc.ownScript as TicTacToeGlobal)
	if globalScript.startStep == TicTacToeGlobal.State.NONE and globalScript.StartPvE(own):
		Mes("You're X! Pick a square, go go go!")
	else:
		Mes("Hang on, someone's already playing! Wait your turn.")

# Player vs Player
func StartPvP():
	var globalScript : TicTacToeGlobal = (npc.ownScript as TicTacToeGlobal)
	match globalScript.StartPvP(own):
		TicTacToeGlobal.State.X:
			Mes("Now we wait for someone to show up...")
			return
		TicTacToeGlobal.State.O:
			Mes("Yay, you're both here! Have fun!")
			return
		TicTacToeGlobal.State.NONE:
			Mes("Nuh-uh, the board's taken right now!")

func WaitPvP():
	if (npc.ownScript as TicTacToeGlobal).playerX == own:
		Chat("I'm sure someone will come soon... Probably!")

func CancelPvP():
	var globalScript : TicTacToeGlobal = (npc.ownScript as TicTacToeGlobal)
	if globalScript.playerX == own:
		globalScript.LeaveQueue(own)
		Chat("Aww, already? Fine...")
