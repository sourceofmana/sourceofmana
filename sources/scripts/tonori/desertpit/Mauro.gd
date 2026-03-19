extends NpcScript

#
func OnStart():
	match GetQuest(WaterPondGlobal.QUEST_ID):
		ProgressCommons.SNAKE_PIT_BITING_THIRST.INACTIVE:
			OnInactive()
		ProgressCommons.SNAKE_PIT_BITING_THIRST.STARTED:
			OnCheckProgress()
		ProgressCommons.SNAKE_PIT_BITING_THIRST.REWARDS_WITHDREW:
			OnComplete()
		_:
			OnInProgress()

# Quest states
func OnInactive():
	Mes("Ahh... I needed that water so badly.")
	Mes("About two weeks ago I decided I must confront the desert myself and explore this area.")
	Mes("But I'm now lost in that desert for nine and a half days and I drank all my supplies...")
	Mes("I tried to reach a water pond inside the cave but those snakes... Every time one bit me I'd spill half my jug and had to try again.")
	Mes("Do you think you could do better than me?")
	Choice("I can give it a try.", OnAccept)
	Choice("Not today.", OnDecline)

func OnCheckProgress():
	var rid : int = own.get_rid().get_id()
	if WaterPondGlobal.biteCounters.get(rid, 0) == 0:
		OnInProgress()
	else:
		OnDeliverWater()

func OnInProgress():
	Mes("A water zone is deep inside the cave, best way to find it is to get lost.")
	Mes("Fill my jug if you find it and bring it back here.")
	Mes("But watch out, you will loose some water along the way every time one of these snakes will bit you!")
	Mes("An empty jug is useless to me, so you will have to refill it to retry!")

func OnDeliverWater():
	WaterPondGlobal.StopJugTransport(own)
	ClearTracker()
	Mes("You made it! And with the water!")
	Mes("Here, take this. It's all I have left.")
	SetQuest(WaterPondGlobal.QUEST_ID, ProgressCommons.SNAKE_PIT_BITING_THIRST.REWARDS_WITHDREW)
	AddItem(DB.GetCellHash("Cactus Drink"), 10)
	AddExp(50)
	AddGP(1000)
	AddKarma(1)
	Mes("I will go back to Tulimshar now, this area is way too dangerous.")

func OnComplete():
	Mes("These days in the desert were my happiest but I think it's time for me to go back to civilization now.")

func OnDecline():
	Mes("I understand. Come back if you change your mind.")

# Transitions
func OnAccept():
	SetQuest(WaterPondGlobal.QUEST_ID, ProgressCommons.SNAKE_PIT_BITING_THIRST.STARTED)
	Mes("Here is the jug. The water source is deep inside the cave, here is an important tip for you:")
	Mes("To find the source I remember I first went north then east...")
	Mes("Then south? Or maybe I went further to the east then north again...")
	Mes("Thruth be told, all I remember are these damn snakes...")
	Mes("Good luck out there, I'd still recommend for you to not go there all alone.")
