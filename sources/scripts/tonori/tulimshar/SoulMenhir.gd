extends NpcScript

const DESERT_SEED_ID : int = ProgressCommons.Quest.DESERT_SEED

#
func OnStart():
	Narrate("A towering monument hums with ancient Mana. Faint glyphs pulse along its surface, warm to the touch.")
	if GetQuest(DESERT_SEED_ID) >= ProgressCommons.DESERT_SEED.SEEK_MANAYIR:
		Narrate("Do you wish to lay your hands on the Soul Menhir?")
		Choice("Touch the Soul Menhir.", Touch)
		Choice("Leave it be.")

func Touch():
	Notification("You feel the mana power growing inside you!")
