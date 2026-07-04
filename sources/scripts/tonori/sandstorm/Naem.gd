extends NpcScript

const QUEST_ID = ProgressCommons.Quest.SANDSTORM_NAEM_HELMET

#
func OnStart():
	Mes("My grandad used to work in this mine. When I was younger he would tell me about it.")
	Mes("It goes down deep. I wonder how far they want us to go; and I wonder if anything lives down there now.")
	Mes("What do you think?")
	Choice("I don't know, but I'll find out.", OnWillFindOut)

func OnWillFindOut():
	if GetQuest(QUEST_ID) == ProgressCommons.SANDSTORM_NAEM_HELMET.GIVEN:
		OnFarewell()
		return

	Mes("I'm not venturing much further if I can help it. Here, I have a spare helmet.")
	SetQuest(QUEST_ID, ProgressCommons.SANDSTORM_NAEM_HELMET.GIVEN)
	AddItem(DB.GetCellHash("Miner Helmet"))
	Mes("There's an artisan in Tulimshar who makes these from palm fibers and a cactus-derived resin. Strong stuff. The quenchiest.")
	Choice("What?", OnNevermind)

func OnNevermind():
	Mes("Never mind. Good luck down there!")

func OnFarewell():
	Chat("Good luck down there!")
