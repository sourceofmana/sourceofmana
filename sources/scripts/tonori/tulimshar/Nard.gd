extends NpcScript

#
func OnStart():
	Mes("Welcome aboard, or close enough.")
	Mes("I'm the captain of La Johanne, the vessel docked right behind me.")
	Mes("We are currently enjoying a well earned break far from cold weathers as we've spent the last few weeks up in the north in the Kazei region.")
	MainChoices()

func MainChoices():
	Choice("Can you take me somewhere by sea?", OnSailOffer)
	Choice("Tell me about yourself.", OnAbout)
	Choice("Safe travels, Captain.", Farewell)

func OnSailOffer():
	Mes("We didn't have any plan, let's ride along!")
	Mes("The ocean is the fastest road there is, once you know how to read her.")
	Mes("I can get you just about anywhere the sea touches. Just say the word.")
	Mes("Or if you're feeling bold, I'll let you take the helm while I catch some rest below deck.")
	Mes("Been a while since I had a proper nap on calm waters.")
	Choice("Where can you take me?", OnDestinations)
	Choice("Let me think about it.", MainChoices)

func OnDestinations():
	Mes("Candor to the north, the Manayir coast west from here, or all the way to Artis on the north-east... You name it, I've docked everywhere.")
	Mes("Used to run supply routes all across Aemil before I found my crew.")
	Mes("Now we go where the wind takes us, more or less.")
	MainChoices()

func OnAbout():
	Mes("Ha. Where to start.")
	Mes("Grew up landlocked in Artis, if you can believe it. I stayed there half my life, learning, crafting and even at some point teaching!")
	Mes("I liked it well enough. Building things, explaining how they worked.")
	Mes("But one morning I woke up and I just knew. The sea was calling and I'd been ignoring it long enough.")
	Mes("Packed up. Walked to the docks. Found a crew in need of a cadet and later turned a captain under the very same deck.")
	Mes("Been out here ever since. No regrets.")
	Choice("Don't you miss your old life?", OnMissOldLife)
	Choice("How did you find your crew?", OnCrew)
	Choice("Back to it.", MainChoices)

func OnMissOldLife():
	Mes("Sometimes I miss the daily routine, waking up, greeting the same old couple that used to live nearby, the smell of grass on my way to work.")
	Mes("But the sea has its own kind of routine that is unmatched and your crew act as your neighbour and family.")
	Mes("And teaching, well... Every new sailor who comes aboard learns from somewhere. Might as well be me.")
	MainChoices()

func OnCrew():
	Mes("One by one, mostly. A dockworker who wanted more than the docks. A cook who'd never left port in his life.")
	Mes("A navigator who knew the stars but had never actually sailed by them.")
	Mes("There's something about this life. It draws people who are looking for something they couldn't name until they found it.")
	Mes("I recognized it in all of them. Same thing I felt that day I enroled.")
	Mes("We've been together long enough now that I can't imagine the ship any other way.")
	MainChoices()

func Farewell():
	Chat("Fair winds to you. Come find me when you're ready to sail.")
