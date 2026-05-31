extends NpcScript

const QUEST_ID = ProgressCommons.Quest.SANDSTORM_NATHAN_WATER

#
func OnStart():
	Mes("Hi! I'm Watchman Nathan.")
	Mes("I'm normally guarding the port of Tulimshar, but today I have the honour of GETTING ABSOLUTELY BAKED TO A CRISP OUT HERE.")
	Mes("Sorry. My bad.")
	Mes("The Sun is getting to me.")

	var questState : ProgressCommons.SANDSTORM_NATHAN_WATER = GetQuest(QUEST_ID) as ProgressCommons.SANDSTORM_NATHAN_WATER
	Choice("Is this the entrance to the Sandstorm Mines?", OnEntrance)
	match questState:
		ProgressCommons.SANDSTORM_NATHAN_WATER.STARTED:
			Choice("About that bottle of water.", OnWaitingWater)
		ProgressCommons.SANDSTORM_NATHAN_WATER.REWARDS_WITHDREW:
			Choice("How are you feeling today?", OnComplete)
	Choice("Nethermind, I thought you were a sandman.", Farewell)

func Farewell():
	Express("I got sand everywhere... EVERYWHERE.")

# Default dialogue flow
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
	if GetQuest(QUEST_ID) == ProgressCommons.SANDSTORM_NATHAN_WATER.INACTIVE:
		Choice("Is there anything I can do to make your job here easier?", OnJobEasier)

func OnNiceDay():
	Express("I'll have a great day when I can get back to staring at the sea! See you later.")

# Water quest
func OnJobEasier():
	Mes("Well, since you're asking... I could use some extra water!")
	Mes("I'm going to be honest with you. It's not even for drinking. I have that with me.")
	Mes("I just want to pour it on my face so I feel less cooked by this heat.")
	Mes("Is that a silly request?")

	Choice("Not at all. I understand what it's like to overheat in this land.", AcceptQuest)
	Choice("Yes, actually. I have more important things to do.", RefuseQuest)

func RefuseQuest():
	Mes("Oh... I understand. No problem. Forget I even asked.")
	Mes("I guess this is why they put me out here... I must be so annoying.")
	Action(Farewell)

func AcceptQuest():
	Mes("I knew you'd understand. Hydration is important! I'll be waiting for you, friend.")
	Think("Nathan thinks to himself")
	Mes("Not that I can go anywhere, even if I wanted to...")
	SetQuest(QUEST_ID, ProgressCommons.SANDSTORM_NATHAN_WATER.STARTED)
	if HasItem(DB.GetCellHash("Water Bottle")):
		Choice("I have one with me.", OnDeliverWater)
	Choice("I'll try to find you that!", Farewell)

func OnWaitingWater():
	Mes("Oh that's you! Sorry I didn't recognize you with all of this sand.")
	Mes("Did you manage to find a bottle of water?")
	if HasItem(DB.GetCellHash("Water Bottle")):
		Choice("I have it.", OnDeliverWater)
	Choice("Not yet, I'll keep looking.", Farewell)

func OnDeliverWater():
	var waterBottleHash : int = DB.GetCellHash("Water Bottle")
	if HasItem(waterBottleHash):
		RemoveItem(waterBottleHash)
		SetQuest(QUEST_ID, ProgressCommons.SANDSTORM_NATHAN_WATER.REWARDS_WITHDREW)
		Mes("Thank you, friend! It's good to have some relief, finally!")
		Think("Nathan quickly pours all the water you have brought him all over himself.")
		Think("You watch as the water you carefully carried all the way here runs down his body and soaks into the sand below.")
		AddExp(50)
		AddGP(100)
		Action(OnComplete)
	else:
		Action(Farewell)

func OnComplete():
	Mes("That was exactly what I needed. You have no idea.")
	Mes("Now I just need someone to bring me another one...")
	Express("I'm joking. Mostly.")
