extends NpcScript

#
func OnStart():
	match GetQuest(ProgressCommons.Quest.SPLATYNA_OFFERING):
		ProgressCommons.SPLATYNA_OFFERING.INACTIVE: Inactive()
		ProgressCommons.SPLATYNA_OFFERING.STARTED: OnRecap()
		_: OnFinish()

func Inactive():
	Mes("Praise Splatyna, the mighty Slime Queen!")
	Mes("You, there! Do you come to offer gold to our viscous lady?")
	InfoChoice()

func InfoChoice(previousText : int = -1):
	var questState : int = GetQuest(ProgressCommons.Quest.SPLATYNA_OFFERING)
	if previousText != 0:
		if questState == ProgressCommons.SPLATYNA_OFFERING.INACTIVE:
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
	Mes("You still haven’t offered any riches to Splatyna?")
	Mes("Go into her cave, find her followers, and give her the gold!")
	Mes("The three loyal ones hold the keys, remember that!")
	InfoChoice(0)

func OnFinish():
	Mes("Wait... I heard something. A scream!")
	Mes("Did something happen to Splatyna?! What have you done?")

	Choice("Nothing! Everything’s fine...", OnDeny)
	Choice("She’s... gone.", OnAdmit)

func OnDeny():
	Mes("Good, good! I will be here making sure the Queen is happy.")

func OnAdmit():
	Mes("Gone?! No, no! You’re lying! Splatyna can’t die!")
	Mes("Just... go, before I lose my mind!")

func OnAskAboutSplatyna():
	Mes("Splatyna is not like the other slimes. She's powerful! She's been blessed by Kaore!")
	Mes("She was once a great queen. Her soul was banished and found its way here. Now she can be a great queen again!")
	Mes("My queen loves gold. It makes her new form so pretty! She likes it better that way.")
	Mes("We must give her the gold she demands. If we anger her, she will consume us all!")
	InfoChoice(2)

func OnAskAboutPlace():
	Mes("This is Splatyna's Golden Kingdom! It was once just a cave, but my queen now rules here.")
	Mes("The slimes here are loyal to Splatyna. They guard her and her immense treasures.")
	Mes("Three of them are special, real loyal ones. They have the keys to her chamber, but they won't just hand them over. You'll have to earn them!")
	Mes("But don't worry. If you bring enough gold, maybe Splatyna will let you through...")
	InfoChoice(3)

func OnAcceptQuest():
	Mes("Very well, take this gold and offer it to Splatyna. She will judge your worth.")
	SetQuest(ProgressCommons.Quest.SPLATYNA_OFFERING, ProgressCommons.SPLATYNA_OFFERING.STARTED)
	Farewell()

func OnDecline():
	Chat("Blasphemy! You dare refuse Splatyna’s offering?!")
