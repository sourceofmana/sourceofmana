extends NpcScript

#
const QUEST_ID : int = ProgressCommons.Quest.TULIMSHAR_OLD_FRIENDSHIP
var sealedLettersID : int = DB.GetCellHash("Sealed Letters")
var heavyEnvelopeID : int = DB.GetCellHash("Heavy Envelope")

#
func OnStart():
	if HasItemsSpace([[sealedLettersID, 1], [heavyEnvelopeID, 1]]):
		Mes("You find two old envelopes tucked between the dusty books.")
		Mes("One is sealed with care, the other feels surprisingly heavy.")
		AddItem(sealedLettersID)
		AddItem(heavyEnvelopeID)
		SetQuest(QUEST_ID, ProgressCommons.TULIMSHAR_OLD_FRIENDSHIP.ENVELOPES_FOUND)
	else:
		Mes("You spot the envelopes, but your bag is too full to carry them.")
