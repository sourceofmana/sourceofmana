extends NpcScript

const DESERT_SEED_ID : int = ProgressCommons.Quest.DESERT_SEED

#
func OnStart():
	Narrate("An imposing carved stone, wrapped in flowing Mana energy. Its presence feels calming.")
	Narrate("Thin silery veins run through the dark grey stone, shifting hues as the blue glow of raw Mana flows past them.")
	if GetQuest(DESERT_SEED_ID) >= ProgressCommons.DESERT_SEED.SEEK_MANAYIR:
		Narrate("Do you wish to lay your hands on the Soul Menhir?")
		Choice("Touch the Soul Menhir.", Touch)
		Choice("Leave it be.")

func Touch():
	var globalScript : SoulMenhirGlobal = npc.ownScript
	if globalScript:
		globalScript.SaveRespawn(own)
