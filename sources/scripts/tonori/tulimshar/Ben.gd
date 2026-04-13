extends NpcScript

#
const QUEST_ID : int = ProgressCommons.Quest.TULIMSHAR_OLD_FRIENDSHIP
var sealedLettersID : int = DB.GetCellHash("Sealed Letters")

#
func OnStart():
	var questState : int = GetQuest(QUEST_ID)
	match questState:
		ProgressCommons.TULIMSHAR_OLD_FRIENDSHIP.ENVELOPES_FOUND:
			ReceiveLetters()
		ProgressCommons.TULIMSHAR_OLD_FRIENDSHIP.LETTERS_DELIVERED, \
		ProgressCommons.TULIMSHAR_OLD_FRIENDSHIP.REWARDS_WITHDREW:
			FreeRoaming()
		_:
			TulimsharWestWallLightTrigerGlobal.CallGuard(own)

func ReceiveLetters():
	if HasItem(sealedLettersID):
		Mes("What. Who sent you with these?")
		Mes("...")
		Mes("I know this handwriting.")
		Mes("These are old. Back when the Queen had us stationed apart, before we even shared the same wall.")
		Mes("Frost handled the people. I handled the stone. That was the deal.")
		Mes("It worked, for a while.")
		Mes("Then the Queen kept pushing. More demands, always her way. No room to just do the work.")
		Mes("Frost started making rules. Procedures for everything. I told him we didn't need more chains on top of the ones we already had.")
		Mes("He said I was shutting him out, making decisions without telling anyone.")
		Mes("Maybe I was, words aren't my tool. Never were.")
		Mes("I just wanted to build things and have people stop arguing about how I build them.")
		Mes("Anyway. I told him to leave. He left. End of story.")
		Mes("...")
		Mes("Except it wasn't, obviously. Because here I am, guarding walls nobody's trying to break through.")
		RemoveItem(sealedLettersID)
		SetQuest(QUEST_ID, ProgressCommons.TULIMSHAR_OLD_FRIENDSHIP.LETTERS_DELIVERED)
		Mes("Take this envelope back to him. He'll know what's inside.")
		Mes("And tell him the walls still stand. He'll... Yeah. Tell him that.")
	else:
		Mes("You look like you want to say something. But your hands are empty.")
		Mes("Come back when you've got something to show me. I have work to do.")

func FreeRoaming():
	Mes("You again. Corridors are open to you now, I meant that.")
	Mes("There's a passage behind the library next to me. Goes outside the walls. Not many know about it.")
