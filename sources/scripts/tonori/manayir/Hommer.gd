extends NpcScript

const DESERT_SEED_ID : int = ProgressCommons.Quest.DESERT_SEED

#
func OnStart():
	Mes("Welcome to Manayir.")
	DisplayChoices()

func DisplayChoices():
	if GetQuest(DESERT_SEED_ID) == ProgressCommons.DESERT_SEED.SEEK_MANAYIR:
		Choice("I was sent by Nina of Tulimshar.", OnKano)
	Choice("What is this place?", OnAboutManayir)
	Choice("What are the Hantu?", OnHantus)
	Choice("Farewell.", Farewell)

func OnAboutManayir():
	Mes("We are Kahwe. An order of druids gathered to research, teach and protect the order of Mana in our world.")
	Mes("Long ago we were spread across the region, each of us tending to Hantus that grew nearby. That time is behind us now.")
	Mes("We also had a presence in Tulimshar for a long time. Tried to keep Mana from being made into a matter of politics. That time is also behind us.")
	Mes("Now we preserve what we still know and continue our studies.")
	DisplayChoices()

func OnHantus():
	Mes("The Hantu, or Mana trees as they are also known, were the pillars of Mana in our world.")
	Mes("They connected all living things through the flow of Mana. Each one kept the land around it alive and prevented Mana from decaying into Kaore.")
	Mes("When people came to fear Mana, they cut them down. It spread fast. Some religious and politics gave it a doctrine and a purpose, and before long there were none left.")
	Mes("We were their guardians. We failed at that.")
	Mes("What remains of our purpose is keeping the knowledge of what they were. We study the flows and traces of Mana they left behind. We wait.")
	DisplayChoices()

func OnKano():
	Mes("You carry something.")
	Mes("A Kano, a Mana Seed.")
	Mes("I have only read about these, we all have. I never thought we would see one again.")
	Choice("Nina said you could be trusted.", OnNinaSentMe)

func OnNinaSentMe():
	Mes("Good, she knew it was the right choice.")
	Mes("But before everything I should tell you something.")
	Choice("What is it?", OnEndPrototype)

func OnEndPrototype():
	Mes("The road ends here, for now.")
	Mes("The people who built this world are still working on what comes next. You have caught up to them.")
	Mes("Congratulation for getting this far and thank you for being part of this journey with us!")
	Mes("Stay as long as you like and please do come visit us and come say hi on our Discord.")
	Mes("Until then, Manayir and the Tonori region is yours to continue to explore.")
	Choice("I'll stay a while.", Farewell)
