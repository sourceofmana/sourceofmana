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
	Mes("My water is all gone! I don't know how I will get back to Tulimshar now.")
	Mes("A few days ago I decided to confront the desert and explore this area.")
	Mes("The cave here has an underground pond of very fresh and pure water.")
	Mes("People used to come here to collect water, but a few years ago the place became infested with snakes.")
	Mes("I thought I could fight the snakes back, but I did not expect to find this many!")
	Mes("I tried to reach the pond but the snakes keep attacking and I spill all the water that I collect.")
	Mes("Do you think you could give it a try? I am so tired. I will need at least one full jug to journey back to the city.
	Mes("These are not venomous snakes, but they are aggressive and there are so many...")
	Choice("I can give it a try.", OnAccept)
	Choice("Not today.", OnDecline)

func OnCheckProgress():
	var rid : int = own.get_rid().get_id()
	if WaterPondGlobal.biteCounters.get(rid, 0) == 0:
		OnInProgress()
	else:
		OnDeliverWater()

func OnInProgress():
	Mes("The pond is deep inside the cave. The best way to find it is to get lost, you'll see it eventually.")
	Mes("Fill my jug if you find it and bring it back here.")
	Mes("But watch out, you will lose some water along the way if one of those snakes bites you!")

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
	Mes("We will keep relying on the much safer wells inside the city. I guess this water belongs to the snakes now.")

func OnComplete():
	Mes("Thank you for getting me that water. Maybe now I can relax a bit and take my time on the way back.")
	Mes("These days in the desert were my happiest but I think it's time for me to go back to civilization now.")

func OnDecline():
	Mes("I understand. Come back if you change your mind.")

# Transitions
func OnAccept():
	SetQuest(WaterPondGlobal.QUEST_ID, ProgressCommons.SNAKE_PIT_BITING_THIRST.STARTED)
	Mes("Here is the jug. The water source is deep inside the cave.")
	Mes("Here is an important tip for you: to find it, I remember I first went north then east...")
	Mes("Then south? Or maybe I went further to the east then north again...")
	Mes("Truth be told, all I remember are the snakes and their sharp bites. Thankfully this kind doesn't have venom.")
	Mes("Good luck out there, I'd still recommend for you to not go there all alone.")
	Mes("If you could find someone else to help, I'm sure it would be easier to fight back the snakes and collect more water.")
