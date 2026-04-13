extends NpcScript

#
const QUEST_ID : int = ProgressCommons.Quest.TULIMSHAR_OLD_FRIENDSHIP
var sealedLettersID : int = DB.GetCellHash("Sealed Letters")
var heavyEnvelopeID : int = DB.GetCellHash("Heavy Envelope")

#
func OnStart():
	var questState : int = GetQuest(QUEST_ID)
	match questState:
		ProgressCommons.TULIMSHAR_OLD_FRIENDSHIP.INACTIVE:
			QuestInactive()
		ProgressCommons.TULIMSHAR_OLD_FRIENDSHIP.STARTED:
			QuestStarted()
		ProgressCommons.TULIMSHAR_OLD_FRIENDSHIP.ENVELOPES_FOUND:
			QuestEnvelopesFound()
		ProgressCommons.TULIMSHAR_OLD_FRIENDSHIP.LETTERS_DELIVERED:
			QuestRewards()
		ProgressCommons.TULIMSHAR_OLD_FRIENDSHIP.REWARDS_WITHDREW:
			QuestCompleted()

func QuestInactive():
	Mes("Careful where you step. The radishes are just coming in.")
	Mes("Sorry, I don't get many visitors. Not sicne I used to be a counsellor up in the palace.")
	Mes("Quit a few years back. Too much weight on everyone's shoulders up there, you know?")
	Mes("Out here it's just me and the dirt. Farming is useful for the city though, so I don't mind it.")
	Mes("Do you ever run the same scenario over and over in your head and wonder how different things would be if you took a different decision?")
	Choice("What's on your mind?", Lore)
	Choice("I should get going", Dismiss)

func QuestStarted():
	Mes("Still at it? Those corridors aren't friendly.")
	Choice("Tell me about Ben again", Lore)
	Choice("Where are the letters?", Directions)
	Choice("I'm on it", Dismiss)

func QuestEnvelopesFound():
	Mes("You found them. Good, good.")
	Mes("Bring the sealed letters to Ben. I just saw him walk into the corridor as soon as you left.")
	Mes("He has good instincts, or maybe you made noise while focusing on not being seen. Anyway, he'll be in there.")

func QuestRewards():
	if HasItem(heavyEnvelopeID):
		Mes("You're back. What did he...")
		Mes("This envelope. It's heavy.")
		Mes("...")
		Mes("Gold. He put gold in here. With my name on it.")
		Mes("When the Queen first stationed us together, we each set aside a share for the other. In case things got bad enough that one of us needed to get out.")
		Mes("I thought he'd spent this after I left. I would have understood if he did.")
		Mes("I don't deserve this. It should belong to someone who is a better friend than I managed to be.")
		Mes("Here. You take it. You've done more for us in one afternoon than we managed in years.")
		RemoveItem(heavyEnvelopeID)
		AddGP(1000)
		SetQuest(QUEST_ID, ProgressCommons.TULIMSHAR_OLD_FRIENDSHIP.REWARDS_WITHDREW)
	else:
		Mes("Did you find Ben? He's in the western wall corridor.")

func QuestCompleted():
	Mes("Radishes are coming in nicely this year.")
	Mes("I keep thinking I should walk over there. To the corridor. Not today, but I decided I will.")
	Mes("He kept those letters. That's something, right?")

func Lore():
	Mes("There was someone I worked with. Ben. Brilliant man. Could fix anything, build anything.")
	Mes("Quiet, though. He'd rather tear down a wall and rebuild it than explain why it needed fixing.")
	Mes("Me, I was the one who talked to people. Organized shifts, sorted out disagreements, kept things running.")
	Mes("We held these walls together for years. Under the Queen, that's no small thing.")
	Choice("What happened?", Conflict)
	Choice("I should get going", Dismiss)

func Conflict():
	Mes("The Queen happened. Or kept happening I guess. Always more demands, always her way.")
	Mes("I started making rules. Procedures for everything. I thought if I could just organize it all, maybe the pressure wouldn't crush us.")
	Mes("Ben saw it differently. Said I was piling even more pressure on top of what we were already under.")
	Mes("And he just did things. Decided things. Without telling me, without telling anyone. I'd find out after the fact.")
	Mes("We were both trying to keep the same walls standing. But somewhere along the way we stopped talking about it and started fighting about it instead.")
	Mes("I've made too many mistakes to think I was right about everything. But back then, neither of us would bend.")
	Mes("He told me to leave. And I just did. I'm not proud of how I handled it, but I got out of the way.")
	Mes("That was years ago. I still think about it more than I should.")
	if GetQuest(QUEST_ID) == ProgressCommons.TULIMSHAR_OLD_FRIENDSHIP.INACTIVE:
		Choice("Is there anything I can do?", Quest)
		Choice("I'm sorry to hear that", Dismiss)

func Quest():
	Mes("Actually... there might be.")
	Mes("At the far end of the western wall corridor near us, past Ben's patrols, there's a small chamber with a library shelf.")
	Mes("There's an envelope on that shelf. Letters we wrote each other, back when the Queen had us stationed apart. Before everything went wrong.")
	Mes("I don't know if it'll change anything. But maybe if he read them again he'd remember we weren't always like this.")
	Mes("The corridors are patrolled, though. You should stick to the shadows. If you step into the light, the guards will catch you.")
	Choice("I'll do it", Accept)
	Choice("Not now", Decline)

func Directions():
	Mes("Far end of the western wall corridor to our left, on top of the library shelf.")
	Mes("And stay out of the light. The guards are on strict orders to escort any unauthorised citizens out.")

func Accept():
	SetQuest(QUEST_ID, ProgressCommons.TULIMSHAR_OLD_FRIENDSHIP.STARTED)
	Mes("Thank you, really.")
	Directions()

func Decline():
	Chat("No I understand. It's a lot to ask of a stranger.")

func Dismiss():
	Chat("Right. Well, the radishes won't water themselves.")
