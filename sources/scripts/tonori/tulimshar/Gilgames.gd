extends NpcScript

#
func OnStart():
	var questState : int = GetQuest(ProgressCommons.Quest.TUTORIAL)
	if questState >= ProgressCommons.TUTORIAL.EKINU_DONE:
		Mes("You're the new one Ekinu took on? Good.")
		Mes("I guess you have many questions before going out, what can I help you with?")
		OnTutorialResume()
	else:
		Mes("Stand clear of the gate. Move along.")

# Common questions
func OnTutorialResume():
	Choice("How can I improve myself?", OnStat)
	Choice("What happens if I'm lost?", OnMinimap)
	Choice("How can I easily access everything I gathered?", OnShortcut)
	Choice("All good!", Farewell)

func Farewell():
	Chat("Try not to get yourself killed.")

# Explanations
func OnStat():
	Mes("Completing an objective, fighting or taking part in activities will help you grow. Look around and don't be afraid to talk to people around you nor to explore surrounding areas.")
	HighlightUI(UICommons.UITarget.STAT)
	Narrate("When you level up you earn some new attribute points, you can spend them on attributes that match your play style and confirm your choice.")
	Narrate("Strength increases your physical damage, walk speed and carrying capacity.")
	Narrate("Agility affects how fast and far you can attack and how well you can dodge an attack.")
	Narrate("Vitality raises your health pool, regeneration and global defense.")
	Narrate("Endurance helps your stamina last longer, regenerate faster and lets you land another hit sooner.")
	Narrate("Concentration feeds your mana and permits you to reach peak performance from your skills.")
	HighlightUI(UICommons.UITarget.STATINDICATOR)
	Narrate("Keep a look at your vital resources, running into the wild with low health, mana or stamina may not be the wisest choice.")
	HighlightUI(UICommons.UITarget.NONE)
	Mes("You will need every edge you can get to defeat what you will face in the desert.")
	OnTutorialResume()

func OnMinimap():
	Mes("Your map is your friend, do not hesitate to use it to know where you have to go.")
	HighlightUI(UICommons.UITarget.MINIMAP)
	Narrate("You can pinpoint any location on the map to move toward it in case you are lost.")
	HighlightUI(UICommons.UITarget.NONE)
	OnTutorialResume()

func OnShortcut():
	Mes("Keep your favorite objects, potions or even skills nearby, they may be useful during the sandstorm.")
	HighlightUI(UICommons.UITarget.ACTION_BAR)
	Narrate("You can drag and drop any usable items, skills or even emotes into the shortcut bar.")
	HighlightUI(UICommons.UITarget.NONE)
	OnTutorialResume()
