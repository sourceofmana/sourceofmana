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
		Mes("Ah, another challenger! This cave is a proving ground, where the waves of corrupted creatures test your endurance. Think you're ready for what's inside?")
		QuestionStart()

func QuestionStart():
	Choice("I'm ready. Bring on the waves.", StartFight)
	Choice("I need to go. This feels wrong.", Farewell)
	Choice("What's this place? It feels strange.", ExplainCave)
	Choice("Waves of monsters? Why are they coming?", ExplainWaves)

func ExplainCave():
	Mes("Ah, this cave? It's... Alive, in a way. You feel it too, don't you?")
	Mes("It breathes Kaore, the corrupted Mana. Everything here was once... More alive. But now it's just hungry, like me.")
	QuestionsCave()

func QuestionsCave():
	Choice("No more questions.", QuestionStart)
	Choice("Who are you? You seem off.", ExplainNpc)
	Choice("What exactly happened to you?", ExplainNpcCorruption)
	Choice("Why is the cave like this?", ExplainCaveOrigin)

func ExplainWaves():
	Mes("Waves... Yes, waves of those lost to Kaore. They are drawn here, hungry for more of the decaying Mana.")
	Mes("You will fight them, over and over. But beware... With each wave, the cave itself grows more restless. You might not make it to the end.")
	QuestionsWaves()

func QuestionsWaves():
	Choice("No more questions.", QuestionStart)
	Choice("What happens if I fail?", ExplainFailure)
	Choice("Is there no way to cleanse the corruption?", ExplainCorruption)
	Choice("Why does Kaore make things this way?", ExplainKaore)

func ExplainNpc():
	Mes("Me? Oh, just a fellow survivor... Or maybe a guide? I can't tell anymore.")
	Mes("I've spent too long near the Kaore. It's in my blood, in my thoughts... But it's okay. I think?")
	Mes("But never mind me. You're here to fight, aren't you?")
	QuestionsCave()

func ExplainNpcCorruption():
	Mes("Oh, it started small... Whispers in the back of my mind, a strange craving for... Something.")
	Mes("But now? I don't remember what I was before. Maybe it's better this way.")
	Mes("You don't want this. But here we are.")
	QuestionsCave()

func ExplainCaveOrigin():
	Mes("This cave was once a Mana wellspring, a place of life and power.")
	Mes("But after the Aethyra War, the Mana decayed into Kaore. Now it’s nothing more than a trap for those who wander too close.")
	Mes("But don't worry. You'll either win... Or join the rest of us.")
	QuestionsCave()

func ExplainFailure():
	Mes("Even if you fall in battle, you need not fear. The Zielite Amulet you carry is more powerful than you may know.")
	Mes("When you perish, your Zielite Amulet will pull your soul to the nearest Soul Menhir. It’s the only reason I allow people like you to risk their lives here.")
	QuestionsWaves()

func ExplainCorruption():
	Mes("Ah, the corruption... Kaore, it's what Mana becomes when it’s left to decay.")
	Mes("Mana flows through all living things. When it's pure, it nurtures life. But here... It's been stagnant for far too long.")
	Mes("Once the Mana Trees was lost, the balance was broken. Now Kaore festers in places like this.")
	Mes("It seeps into everything: creatures, the land, even people. And once you're touched by it, there's no going back.")
	QuestionsWaves()
	
func ExplainKaore():
	Mes("Kaore... It's the decayed Mana. It festers where life was once vibrant. Here, in this cave, it thrives.")
	Mes("It changes things... Makes them hostile, makes them... Desperate.")
	Mes("You'll feel it too if you stay long enough.")
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
		elif RemoveItem(tributeItemID, tributeItemCount):
			Chat("Ah, you're ready for this! The fight begins in 10 seconds, brace yourself!")
			Trigger()
