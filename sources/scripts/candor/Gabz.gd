extends NpcScript

# Requirements
var tributeItemID : int					= DB.GetCellHash("Apple")
const tributeItemCount : int			= 5
const playerLevelRequirement : int		= 1

#
func OnStart():
	if IsTriggering():
		Chat("Focus on your mission!")
	else:
		Mes("Welcome to the Heart of Candor, where Mana comes to die!")
		QuestionStart()

func QuestionStart():
	Choice("Let's get this started, Gabz.", StartFight)
	Choice("I changed my mind, I need to go.", Farewell)
	Choice("What is this place?", ExplainCave)
	Choice("Do you know where these waves of monsters come from?", ExplainWaves)

func ExplainCave():
	Mes("This is the Heart of Candor. It is a cave system that has always contained high concentrations of Kaore.")
	Mes("As Mana flows across Aemil, some of the energy decays and settles in particular areas.")
	Mes("This is one of those areas. A place where Mana stops flowing and becomes Kaore.")
	QuestionsCave()

func QuestionsCave():
	Choice("No more questions.", QuestionStart)
	Choice("Who are you? You seem off.", ExplainNpc)
	Choice("Why is the cave like this?", ExplainCaveOrigin)

func ExplainWaves():
	Mes("The board where we are standing is a catalyst that uses the energy of this cave to summon all sorts of creatures.")
	Mes("They will come in progressive waves and try to wear you down.)
	Mes("If you survive enough waves, the summoning will stop and you will have conquered the Heart of Candor.")


func QuestionsWaves():
	Choice("No more questions.", QuestionStart)
	Choice("What happens if I fail?", ExplainFailure)
	Choice("Is there no way to cleanse the corruption?", ExplainCorruption)
	Choice("Why does Kaore make things this way?", ExplainKaore)

func ExplainNpc():
	Mes("I never thought about that... I don't know! I have always been here, I think?")
	Think("Gabz looks at you slightly confused.")
	Mes("I am Gabz.")
	QuestionsCave()

func ExplainCaveOrigin():
	Mes("No one really knows. Some say its tunnels lead down to the core of Aemil and that it's all filled with Kaore.")
	Mes("Others think that something about the rock attracts Kaore from all directions.")
	Mes("I don't ask myself too many questions.")
	QuestionsCave()

func ExplainFailure():
	Mes("Luckily for you, I hold the power of life and death in this place!")
	Mes("When you perish in this cave, I will use your Zielite Amulet to have your living essence restored at a Soul Menhir.")
	Mes("If I didn't save you, I'd quickly run out of pawns to play with.")
	QuestionsWaves()

func ExplainCorruption():
	Mes("A high concentration of Mana could perhaps change the balance of energies.")
	Mes("But I am here to keep the Kaore at bay, so why not let me enjoy it?")
	QuestionsWaves()
	
func ExplainKaore():
	Mes("Kaore can turn creatures hostile and, over time, undead.")
	Mes("It powers them to act against living creatures and their connection to Mana.")
	Mes("You might feel it too if you stay here too long.")
	QuestionsWaves()

func StartFight():
	var alivePlayerCount : int = AlivePlayerCount()
	if IsTriggering():
		if alivePlayerCount == 0:
			CallGlobal("OnCancel")
		else:
			Mes("The fight has already begun. You can't start another one now.")
	elif alivePlayerCount > 0:
		if not HasItem(tributeItemID, tributeItemCount):
			Mes("You'll need to bring me 5 apples as a tribute before we begin.")
		elif own.stat.level < playerLevelRequirement:
			Mes("You're not strong enough for this fight. Come back when you've reached level %d." % playerLevelRequirement)
		else:
			RemoveItem(tributeItemID, tributeItemCount)
			Chat("Ah, you're ready for this! The fight begins in 10 seconds, brace yourself!")
			Action(Trigger)
