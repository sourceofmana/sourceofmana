extends NpcScript

#
func OnStart():
	match GetQuest(ProgressCommons.QUEST_SPLATYNA_OFFERING):
		ProgressCommons.STATE_SPLATYNA.INACTIVE: Inactive()
		ProgressCommons.STATE_SPLATYNA.STARTED: OnRecap()
		_: OnFinish()

func Inactive():
	Mes("Praise Splatyna, the mighty slime goddess!")
	Mes("You, traveler! Do you come to offer gold to our great lady?")
	InfoChoice()

func InfoChoice(previousText : int = -1):
	var questState : int = GetQuest(ProgressCommons.QUEST_SPLATYNA_OFFERING)
	if previousText != 0:
		if questState == ProgressCommons.STATE_SPLATYNA.INACTIVE:
			Choice("Sure, I'll bring her the offering.", OnAcceptQuest)
		else:
			Choice("What should I do?", OnRecap)
	if previousText != 1:
		Choice("This is nonsense, I’m leaving.", OnDecline)
	if previousText != 2:
		Choice("Who is Splatyna?", OnAskAboutSplatyna)
	if previousText != 3:
		Choice("What is this place?", OnAskAboutPlace)

func OnRecap():
	Mes("You still haven’t offered the gold to Splatyna?")
	Mes("Go into her cave, find her followers, and give her the gold! The three loyal ones hold the keys, remember that!")
	InfoChoice(0)

func OnFinish():
	Mes("Wait... I heard something. A scream!")
	Mes("Did something happen to Splatyna?! What have you done?")

	Choice("Nothing! Everything’s fine...", OnDeny)
	Choice("She’s... Gone.", OnAdmit)

func OnDeny():
	Mes("Good, good! As long as Splatyna still watches over us.")

func OnAdmit():
	Mes("Gone?! No, no! You’re lying! Splatyna can’t die!")
	Mes("Just... Go, before I lose my mind!")

func OnAskAboutSplatyna():
	Mes("Oh, Splatyna... She's not like the other slimes, no no. She's powerful! She's been blessed by Kaore!")
	Mes("She doesn't need food or water like the rest of us. Kaore keeps her alive! She’s stronger and wiser than us poor souls!")
	Mes("And the gold! Yes, she loves it. She says it keeps her safe, makes her strong! We give her gold, and she protects us, keeps the decay away!")
	Mes("But don't anger her, no! She can make you crazy with just a look! Her magic... It's powerful, twisted by Kaore. She's... perfect.")
	InfoChoice(2)

func OnAskAboutPlace():
	Mes("This is Splatyna's sacred cave! Only those who respect her can enter, yes, yes!")
	Mes("The slimes here, they're not normal. They're loyal to Splatyna, her closest followers. They guard her treasures, her power!")
	Mes("Three of them are special, real loyal ones. They have the keys to her chamber, but they won't just hand them over, no no! You'll have to earn them!")
	Mes("But don't worry. If you bring enough gold, maybe Splatyna will let you through...")
	InfoChoice(3)

func OnAcceptQuest():
	Mes("Very well, take this gold and offer it to Splatyna. She will judge your worth.")
	SetQuest(ProgressCommons.QUEST_SPLATYNA_OFFERING, ProgressCommons.STATE_SPLATYNA.STARTED)
	Farewell()

func OnDecline():
	Chat("Blasphemy! You dare refuse Splatyna’s offering?!")
