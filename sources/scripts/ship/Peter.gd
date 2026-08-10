extends NpcScript

const QUEST_ID : int = ProgressCommons.Quest.SHIP_PETER_BOUNTY
const MIN_LEVEL : int = 5

const HOLD_SPAWN_POS : Vector2 = Vector2(48 * 32, 28 * 32)
const HOLD_SPAWN_MAP : StringName = "Ship Hold"

#
func OnStart():
	if own.stat.level < MIN_LEVEL:
		Mes("You're too young to wander around here, finish school first then we'll talk.")
	elif npc.ownScript and npc.ownScript.IsInProgress(own):
		Mes("What are you doing up here? The job's below deck. Move it!")
	else:
		Mes("Aye? Make it quick, I'm busy.")
		match GetQuest(QUEST_ID):
			ProgressCommons.SHIP_PETER_BOUNTY.INACTIVE:
				OnFirstMeeting()
			ProgressCommons.SHIP_PETER_BOUNTY.ALL_DONE:
				OnDailyOffer()
			_:
				OnReturnVisit()

func OnFirstMeeting():
	Mes("Something's been chewing through our stores in the hold. I bet it's again some Rattos... I need someone to deal with them.")
	Choice("I could use the practice, I'm in.", OnAccept)
	Choice("Not my problem.", OnDecline)

func OnAccept():
	Mes("Here's the job.")
	OnExplainBounties()

func OnDecline():
	Chat("Suit yourself.")

func OnReturnVisit():
	Mes("Back again? Good. That hold hasn't cleaned itself.")
	OnExplainBounties()

func OnExplainBounties():
	match GetQuest(QUEST_ID):
		ProgressCommons.SHIP_PETER_BOUNTY.INACTIVE:
			Mes("Rattos found something to sink their teeth into. Clear them out and you'll be paid for it.")
			Choice("Consider it done.", AcceptBounty.bind(ProgressCommons.SHIP_PETER_BOUNTY.WAVE_ONE_DONE, "Ratto", 5))
		ProgressCommons.SHIP_PETER_BOUNTY.WAVE_ONE_DONE:
			Mes("I found a new nest, there are more of them down there now, and bolder too. Pay's better this time.")
			Choice("I'll finish what I started.", AcceptBounty.bind(ProgressCommons.SHIP_PETER_BOUNTY.WAVE_TWO_DONE, "Ratto", 10))
		ProgressCommons.SHIP_PETER_BOUNTY.WAVE_TWO_DONE:
			Mes("Forget the rattos. We've got bats down there now. Bats, can you believe that?")
			Choice("Bats it is.", AcceptBounty.bind(ProgressCommons.SHIP_PETER_BOUNTY.ALL_DONE, "Bat", 10))

	Choice("Not right now.", OnDecline)

func AcceptBounty(nextState : int, monsterName : String, monsterCount : int):
	Mes("Close the door fast after you, the air there is quite nauseating.")
	WarpInstance(HOLD_SPAWN_MAP.hash(), HOLD_SPAWN_POS)
	Action(npc.ownScript.StartRun.bind(own, nextState, monsterName.hash(), monsterCount))

func OnDailyOffer():
	if npc.ownScript.CanRunDailyQuest(own.get_rid().get_id()):
		Mes("You again? Good. Rattos don't know when to quit, they're back.")
		Mes("Same as always. Go down, clear them out, come up for your coin.")
		Choice("On my way.", AcceptBounty.bind(ProgressCommons.SHIP_PETER_BOUNTY.ALL_DONE, "Ratto", 10))
		Choice("Not today.", OnDecline)
	else:
		Mes("You again? Hold is quiet today, I won't need your help you can move on.")
