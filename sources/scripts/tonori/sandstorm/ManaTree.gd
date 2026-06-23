extends NpcScript

const QUEST_ID : int = ProgressCommons.Quest.MINE_EXPLORATION

#
func OnStart():
	match GetQuest(QUEST_ID):
		ProgressCommons.MINE_EXPLORATION.REWARDS_WITHDREW, ProgressCommons.MINE_EXPLORATION.MANA_TREE_MET:
			OnComplete()
		ProgressCommons.MINE_EXPLORATION.DEFEATED:
			OnPostFight()
		_:
			OnPreFightIntro()

func OnPreFightIntro():
	Narrate("A calm voice fills your head.")
	Mes("I don't feel the same dark presence that I felt with the first one who came through here. Please come forward, I will be needing someone's help for the first time in over 5000 years.")

func OnPostFight():
	Mes("Thank you.")
	Mes("I could have defended myself just as I defended you, but he would have left just as he did.")
	Mes("My location is known now and I need an ally against this new threat.")
	Choice("Are you... A tree?", OnTree)

func OnTree():
	Mes("Yes. I am an Uru, or a Mana Tree.")
	Mes("My kind was the first life on our world of Aemil and, until today, I thought I would be the last.")
	Mes("The person you just fought was after my Kano. You would call it a Mana Seed.")
	Mes("It is an exceptionally rare thing, as it can sprout into a new Uru. It is particularly precious at this time in our history, as I am the last Uru that is left alive.")
	Action(OnTreeBranch)

func OnTreeBranch():
	Choice("How do you survive down here?", OnHowSurvive)
	Choice("What should I do now?", OnWhatNext)
	Choice("How did you end up in this cave?", OnLocation)
	Choice("What happened since that time?", OnWhatHappened)

func OnHowSurvive():
	Mes("Although I would like to see it, I do not need light to live.")
	Mes("My roots extend deep into the earth and share in the source of life that empowers all of us: Mana.")
	Mes("As long as I can connect to its flow, I am alive.")
	Mes("Many years ago this world was full of Uru like me. Our roots were interconnected and Mana flowed more powerfully than it does now.")
	Action(OnTreeBranch)

func OnWhatHappened():
	Mes("Mana can behave in unexpected ways.")
	Mes("When it disrupted the lives of people for a time, a belief that it could be harmful developed.")
	Mes("This quickly spread to many cultures and it became customary to cut down the Uru to limit the flow of Mana.")
	Action(OnTreeBranch)

func OnLocation():
	Mes("When the Uru were threatened, a group of druids that intended to protect us planted a Kano here in this cave.")
	Mes("Then, they founded an order called Manayir somewhere nearby, to study and use the flow of Mana close to my roots.")
	Mes("I was born here, hidden from the world. Over time the Manayir let their knowledge of my existence fade, even from their own, so that I would remain hidden.")
	Action(OnTreeBranch)

func OnWhatNext():
	Mes("I would ask you to never speak to anyone of my existence.")
	Mes("Take the Kano, the Mana Seed.")
	Mes("The druid Nina of Tulimshar is someone I know you can trust with it. She is very attuned to the flow of Mana and I have come to know her presence.")
	Mes("You should tell the guards inspecting the mines around here that you found great dangers and that it is not safe to access the lower levels.")
	Mes("I have no choice but to trust that you will take good decisions.")
	Mes("Whatever you do, it won't be as bad as what the person you fought here would have done.")
	Choice("I will go to Nina then.", OnTellNina)
	Choice("What do you know about that man?", OnXakelbael)

func OnTellNina():
	Mes("Be careful. What you have discovered here today has been hidden for thousands of years.")
	Mes("As chance has dictated, you are now a warden of a powerful Source of Mana.")
	SetQuest(QUEST_ID, ProgressCommons.MINE_EXPLORATION.MANA_TREE_MET)
	SetQuest(ProgressCommons.Quest.DESERT_SEED, ProgressCommons.DESERT_SEED.SEEK_NINA)

func OnXakelbael():
	Mes("He used to be one of the Manayir. His intentions are different now.")
	Mes("You should speak to those who belong to his order. They will tell you who he is.")
	Choice("I will go to Nina then.", OnTellNina)

func OnComplete():
	Chat("Remember what you carry.")
