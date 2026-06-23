extends NpcScript

const DESERT_SEED_ID : int = ProgressCommons.Quest.DESERT_SEED

#
func OnStart():
	var state : ProgressCommons.DESERT_SEED = GetQuest(DESERT_SEED_ID) as ProgressCommons.DESERT_SEED
	if state == ProgressCommons.DESERT_SEED.SEEK_NINA and HasItem(DB.GetCellHash("Sandstorm Kano")):
		OnDesertSeedIntro()
	elif state == ProgressCommons.DESERT_SEED.SEEK_MANAYIR:
		OnDesertSeedReminder()
	else:
		var questState : ProgressCommons.NINA_HUNGRY = GetQuest(ProgressCommons.Quest.NINA_HUNGRY) as ProgressCommons.NINA_HUNGRY
		if questState == ProgressCommons.NINA_HUNGRY.INACTIVE:
			OnIntro()
		else:
			Mes("Hello again.")
			OnPlayerChoice()

# Intro
func OnIntro():
	Mes("Hello. Elanore sent you? Welcome.")
	Mes("We are standing before Tulimshar's ancient Soul Menhir. I am its guardian and use its powers to protect the people of this city, or as much as I am allowed to.")
	OnPlayerChoice()

func OnPlayerChoice():
	if GetQuest(ProgressCommons.Quest.NINA_HUNGRY) == ProgressCommons.NINA_HUNGRY.STARTED and HasItem(DB.GetCellHash("Croissant")):
		Choice("I found a croissant for you!", OnCroissantTurnIn)
	else:
		Choice("Is someone trying to stop you?", OnExplainOpposition)
		Choice("Can you tell me more about Mana and Kaore?", OnExplainMana)
		Choice("What is a Soul Menhir?", OnExplainMenhir)
	Choice("See you.", Farewell)

# Opposition and faith
func OnExplainOpposition():
	Mes("Not exactly. Kahwes, or Druids, have always been allowed in Tulimshar. If anything because without us the city would not survive the worst droughts and other perils of Tonori's climate.")
	Mes("The Kingdom however officially follows the Savean Creed. They believe, like half of the people around you, that Mana is also a corrupting force just like Kaore and that both should be avoided unless strictly necessary.")
	Mes("Our Menhir still stands because it makes people's lives easier. Even those who have opposing beliefs cannot deny the benefit of Mana use. They will oppose it publicly, but when a personal need arises, they will seek Kahwes like myself to heal a loved one or bring some needed rain.")
	Mes("I just wish that more people embraced the ancient traditions more openly. The Savean beliefs have brought much trouble to our world. Now they have even spawned these new cultists, the Varunian, who essentially worship Kaore.")
	Mes("None of this is how the relationship with Mana has been for most of Aemil's existence.")
	Choice("What is your people's position?", OnKahwePosition)
	Choice("I have some other topics I wanted to discuss.", OnPlayerChoice)
	Choice("Thank you for your time.", Farewell)

func OnKahwePosition():
	Mes("The Kahwe carry on the knowledge of times when Mana was a harmonious force of good in our world. We seek to restore the balance that was lost when the Hantu were destroyed.")
	Choice("What are the Hantu?", OnExplainHantu)
	Choice("I have some other topics I wanted to discuss.", OnPlayerChoice)
	Choice("Thank you for your time.", Farewell)

func OnExplainHantu():
	Mes("Hantu, also known as Mana Trees, used to be the heart of the world's lifeforce, acting as a natural conductor for Mana energy.")
	Mes("In ancient times, there were many, each serving as a stabilizing force, preventing Mana from decaying into Kaore.")
	Mes("The Mana Trees were destroyed many years ago after a devastating war where the Savean Creed took hold among the ruling elites of Aemil.")
	Mes("The decision was made to destroy the Hantu and attempt to create a world without Mana.")
	Choice("Where do things stand now?", OnCurrentSituation)
	Choice("I have some other topics I wanted to discuss.", OnPlayerChoice)
	Choice("Thank you for your time.", Farewell)

func OnCurrentSituation():
	Mes("It depends on who you ask. Some people, like the Red Queen, would say that life is better without magic.")
	Mes("But then, she still uses it in her palace. She only means that it's better for the common people to not have it, claims that it's too dangerous.")
	Mes("If you ask me, I believe that magic is a natural part of our world. It has led us to where we are today, and despite being the most dangerous force of nature, we need it.")
	Mes("Water is a dangerous force of nature too if you think about it, but no one is suggesting to close the wells.")
	Choice("Who is the Red Queen?", OnRedQueen)
	Choice("Is there anything I can do for you?", OnAskForHelp)

func OnRedQueen():
	Mes("She's the ruler of our city and the whole Kingdom of Tonori, though she doesn't have much power outside of the city walls.")
	Mes("The Zuni tribes of Tonori never recognised our Kingdom so she really only rules over the city.")
	Mes("Another reason for her to keep magic away from her people. The Zuni still practice their ancient magic and it makes them very hard to fight.")
	Mes("She'd rather not have the same problem here in Tulimshar.")
	Choice("What can you tell me about the Zuni?", OnZuni)
	Choice("Is there anything I can do for you?", OnAskForHelp)

func OnZuni():
	Mes("They have lived in the Tonori desert for a very long time. In fact, they still tell stories of this land before it was even a desert.")
	Mes("They've always traded with Tulimshar and are mostly friendly towards us, but only as long as we don't send our soldiers too far outside our walls.")
	Mes("Whenever that has happened in the past they've fought us back until we gave up. I respect that about them, they have clear boundaries and will defend their homeland.")
	Choice("Bah! They seem like uncivilised nomads to me.", OnZuniDismissal)
	Choice("It would be interesting to meet them!", OnZuniMarket)

func OnZuniDismissal():
	Mes("Right...")
	OnZuniMarket()

func OnZuniMarket():
	Mes("You can find some of their traders in the marketplace north of here.")
	Mes("I'm sure they'll be happy to chat, especially if you buy some of their wares.")
	Choice("Is there anything I can do for you?", OnAskForHelp)

# Mana and Kaore
func OnExplainMana():
	Mes("Mana, often called \"lifepower,\" is the essence of all living things.")
	Mes("It flows through the world's biomass, forming an interconnected web of energy. Properly channelled, it can be harnessed to produce magic, heal the land, and sustain life.")
	Mes("Kaore is what remains when Mana is severed from its source.")
	Mes("Instead of nourishing life, it festers, corrupts, and decays. It seeps into the land, warping living beings into hostile, aggressive forms.")
	Mes("Kaore in many ways is a form of Mana, which is the main energy we can perceive.")
	Mes("Mana flows through all living things, but also infuses a particular mineral known as Zielite. That's what this Soul Menhir is made of.")
	OnPlayerChoice()

# Soul Menhir and Zielite
func OnExplainMenhir():
	Mes("Soul Menhirs are ancient monoliths carved from massive blocks of Zielite, once erected by the Kahwe, known as druids around here, to channel and radiate Mana.")
	Mes("When active, they generate a protective aura, repelling Kaore-infected creatures and stabilizing the land.")
	Mes("With the help of a Kahwe, a Soul Menhir can be used to heal those who are injured and even to prevent death in some cases, giving people multiple chances at life.")
	Choice("What do you know about Zielite?", OnExplainZielite)
	Choice("I have some other topics I wanted to discuss.", OnPlayerChoice)
	Choice("Thank you for your time.", Farewell)

func OnExplainZielite():
	Mes("Zielite is a rare mineral with a natural affinity for Mana. It can absorb, store, and emit Mana energy, making it invaluable for both magic and protection.")
	Mes("Though once abundant, Zielite has become scarce due to the purge that took place when the Savean Creed turned society against the use of Mana.")
	Mes("Zielite craftsmanship still exists in hidden talismans, forgotten ruins, and the few remaining Soul Menhirs that continue to stand as bastions against Kaore.")
	OnPlayerChoice()

# Hungry quest
func OnAskForHelp():
	var questState : int = GetQuest(ProgressCommons.Quest.NINA_HUNGRY)
	if questState == ProgressCommons.NINA_HUNGRY.STARTED:
		Mes("Not at the moment. I am still hoping for that snack, if you happen to find one!")
		OnPlayerChoice()
	elif questState == ProgressCommons.NINA_HUNGRY.REWARDS_WITHDREW:
		Mes("Not at the moment, but thank you for asking.")
		OnPlayerChoice()
	else:
		Mes("Not at the moment...")
		Mes("I am a bit hungry though. Not that I would ask you to bring me food! I'll take care of it later.")
		Choice("I'll keep an eye out for snacks on the way to the market.", OnStartHungryQuest)
		Choice("Ok bye.", Farewell)

func OnStartHungryQuest():
	Mes("That is very kind of you. I would not normally ask, but a croissant would be absolutely wonderful right now.")
	Mes("You can usually find them at the bakery stand in the market. I would go myself but, well... this Menhir will not guard itself.")
	SetQuest(ProgressCommons.Quest.NINA_HUNGRY, ProgressCommons.NINA_HUNGRY.STARTED)

func OnCroissantTurnIn():
	Mes("Oh my!")
	Mes("A croissant! I cannot believe it. You are truly too kind, I did not expect this at all!")
	RemoveItem(DB.GetCellHash("Croissant"))
	SetQuest(ProgressCommons.Quest.NINA_HUNGRY, ProgressCommons.NINA_HUNGRY.REWARDS_WITHDREW)
	AddItem(DB.GetCellHash("Cactus Potion"), 10)
	AddGP(100)
	Mes("Please, take these Cactus Potions and a bit of gold to cover what you spent.")

# Desert Seed quest
func OnDesertSeedIntro():
	Mes("Oh.")
	Mes("I felt it the moment you walked through the gate. What is it that you are carrying?")
	Choice("Something I found deep in the Sandstorm Mines.", OnRevealKano)

func OnRevealKano():
	Mes("May I see it?")
	Mes("...")
	Mes("This is a Kano. A Mana Seed.")
	Mes("I have only ever read about these. I never imagined I would see one in my lifetime.")
	Mes("How did you come to find this?")
	Choice("There is a Mana Tree at the bottom of the mines. It gave it to me.", OnRevealManaTree)

func OnRevealManaTree():
	Mes("A Mana Tree. Alive. In the Sandstorm Mines.")
	Mes("I...")
	Mes("I need a moment.")
	Mes("I once felt something in that direction, a long time ago. I assumed it was a deep Zielite deposit. I had no idea.")
	Mes("Were you able to communicate together? Did it tell you what to do with that Kano?")
	Choice("It said to bring it to you and that you could be trusted.", OnNinaReacts)

func OnNinaReacts():
	Mes("Then I will not let it down.")
	Mes("Manayir will need to know about this. They are an ancient order of druids who were once guardians of these trees.")
	Mes("They built a castle into a small peninsula, all the way across the beach on west side of the sandstorm area.")
	Mes("Find them. Show them the Kano and tell them what you have seen.")
	Mes("Tell no one else. Not yet. The wrong person hearing about this could endanger everything.")
	Mes("Before you go, take this.")
	SetQuest(DESERT_SEED_ID, ProgressCommons.DESERT_SEED.SEEK_MANAYIR)
	AddItem(DB.GetCellHash("Brass Zielite Amulet"))
	Mes("It is a Zielite Amulet. The stone at its centre is a fragment of pure Zielite, the same mineral this Menhir is made of.")
	Mes("When worn, it allows you to channel Mana, and to connect with Soul Menhirs.")
	Choice("What does connecting to a Soul Menhir do?", OnExplainMenhirSync)

func OnExplainMenhirSync():
	Mes("When you touch a Soul Menhir while wearing a Zielite Amulet, the stone resonates with the Menhir's Zielite.")
	Mes("This creates a bond between your soul and the Menhir. Should something happen to you, the Menhir acts as an anchor.")
	Mes("Your soul returns here instead of being lost.")
	Mes("It is how we Kahwe have always protected those under our care. I should have given you one sooner.")
	Choice("[Touch the Soul Menhir]", OnTouchMenhir)

func OnTouchMenhir():
	Narrate("You place your hand on the Soul Menhir. The Zielite Amulet grows warm against your skin. A soft resonance passes through you, and for a moment the stone pulses with a faint light.")
	Mes("Good. You are connected now.")
	Mes("If you ever find another Soul Menhir, touch it. Each one you connect with strengthens the bond.")
	Mes("Now go. The Manayir are waiting, even if they do not know it yet.")
	OnPlayerChoice()

func OnDesertSeedReminder():
	Mes("Have you found the Manayir yet?")
	Mes("They gather somewhere in the desert near the Sandstorm Mines. Ask around in that area, someone should be able to point you in the right direction.")
	OnPlayerChoice()
