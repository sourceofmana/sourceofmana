extends NpcScript

# Behaviour
const ThresholdHandValue : int			= 17

# Card utilities
static var RANKS : PackedStringArray	= ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"]
static var SUITS : PackedStringArray	= [
	"[outline_size=2][outline_color=white][color=#635994]♠[/color][/outline_color][/outline_size]",
	"[outline_size=2][outline_color=white][color=#f8312f]♥[/color][/outline_color][/outline_size]",
	"[outline_size=2][outline_color=white][color=#f8312f]♦[/color][/outline_color][/outline_size]",
	"[outline_size=2][outline_color=white][color=#635994]♣[/color][/outline_color][/outline_size]"
]

# Game state
var deck : Array						= []
var playerHand : Array					= []
var dealerHand : Array					= []

# Helper
static func _CardName(card : int) -> String:
	return "%s of %s" % [RANKS[card % 13], SUITS[floori(card / 13.0)]]

static func _CardValue(card : int) -> int:
	var rank : int = card % 13
	if rank == 0: return 11
	if rank >= 10: return 10
	return rank + 1

static func _HandValue(hand : Array) -> int:
	var value : int = 0
	var aces : int = 0
	for card : int in hand:
		value += _CardValue(card)
		if card % 13 == 0:
			aces += 1
	while value > 21 and aces > 0:
		value -= 10
		aces -= 1
	return value

static func _HandStr(hand : Array) -> String:
	var parts : PackedStringArray = []
	for card : int in hand:
		parts.append(_CardName(card))
	return ", ".join(parts) + " (%d)" % _HandValue(hand)

static func _NewDeck() -> Array:
	var d : Array = []
	d.resize(52)
	for i : int in range(52):
		d[i] = i
	d.shuffle()
	return d

# General flow
func OnStart():
	Mes("Ah, another brave soul! Sit down, sit down. The cards have been waiting.")
	DisplayChoices()

func DisplayChoices():
	Choice("Challenge you", StartDealer)
	Choice("Find me a worthy opponent", StartPvP)
	Choice("Rules", ShowRules)
	Choice("Not today", Decline)

func ShowRules():
	Mes("Even the guards could learn this one, and that's saying something.")
	Mes("Get as close to 21 as you can without going over. Number cards are face value, face cards are 10, and Aces... Well, Aces are tricky. They can be 1 or 11.")
	Mes("Beat me, and I'll tip my hat. Go over 21, and you bust. That's the game.")
	DisplayChoices()

func Decline():
	Chat("Off you go then. You know where to find me.")

func OnQuit():
	if npc and npc.ownScript:
		npc.ownScript.call("LeavePvP", own)
	super.OnQuit()

# Player vs Dealer Mode
func StartDealer():
	deck = _NewDeck()
	playerHand = [deck.pop_back(), deck.pop_back()]
	dealerHand = [deck.pop_back(), deck.pop_back()]
	_DealerTurn()

func _DealerTurn():
	if _HandValue(playerHand) == 21:
		_DealerReveal()
	else:
		Mes("Your hand: %s" % _HandStr(playerHand))
		Mes("And I'm showing: %s." % _CardName(dealerHand[0]))
		Choice("Hit", _DealerHit)
		Choice("Stand", _DealerReveal)

func _DealerHit():
	playerHand.append(deck.pop_back())
	var value : int = _HandValue(playerHand)
	if value > 21:
		Mes("Your hand: %s" % _HandStr(playerHand))
		Mes("Oho, bust! Greed will do that to you. I've seen it a thousand times.")
		Choice("Play again", StartDealer)
		Choice("Leave", Decline)
	elif value == 21:
		_DealerReveal()
	else:
		_DealerTurn()

func _DealerReveal():
	while _HandValue(dealerHand) < ThresholdHandValue:
		dealerHand.append(deck.pop_back())
	var pv : int = _HandValue(playerHand)
	var dv : int = _HandValue(dealerHand)
	Mes("Your hand: %s" % _HandStr(playerHand))
	Mes("My hand: %s" % _HandStr(dealerHand))
	if dv > 21:
		Mes("Bah! Even an old master overreaches sometimes. Well played.")
	elif pv > dv:
		Mes("Heh... Not bad.")
	elif dv > pv:
		Mes("Experience wins again. Don't feel bad, most people lose to me.")
	else:
		Mes("A tie at %d! You've got guts, I'll give you that." % pv)
	Choice("Play again", StartDealer)
	Choice("Leave", Decline)

# Player vs Player Mode
func StartPvP():
	var result : int = npc.ownScript.call("JoinPvP", own)
	if result == 0:
		Mes("Alright, let's see who else is brave enough. Hang tight.")
		Choice("Check", _PvPCheck)
		Choice("Cancel", _PvPCancel)
	else:
		_PvPBegin()

func _PvPCheck():
	var game : Dictionary = npc.ownScript.call("GetGame", own)
	if game.is_empty():
		Mes("Patience... A good card player learns to wait.")
		Choice("Check", _PvPCheck)
		Choice("Cancel", _PvPCancel)
	elif game.has("result"):
		_PvPShowResult(game)
	else:
		_PvPBegin()

func _PvPCancel():
	npc.ownScript.call("LeavePvP", own)
	Chat("Cold feet, eh? No shame in that.")

func _PvPBegin():
	playerHand = npc.ownScript.call("GetHand", own)
	Mes("Ha! We've got a match! Let's see what you're both made of.")
	_PvPTurn()

func _PvPTurn():
	Mes("Your hand: %s" % _HandStr(playerHand))
	if _HandValue(playerHand) == 21:
		Mes("Blackjack!")
		_PvPStand()
	else:
		Choice("Hit", _PvPHit)
		Choice("Stand", _PvPStand)

func _PvPHit():
	var card : int = npc.ownScript.call("DrawCard", own)
	if card < 0:
		_PvPStand()
		return
	playerHand.append(card)
	var value : int = _HandValue(playerHand)
	if value > 21:
		Mes("Your hand: %s" % _HandStr(playerHand))
		Mes("Bust! Should've listened to your gut.")
		npc.ownScript.call("FinishHand", own, value, true)
		_PvPWait()
	elif value == 21:
		Mes("Your hand: %s" % _HandStr(playerHand))
		_PvPStand()
	else:
		_PvPTurn()

func _PvPStand():
	npc.ownScript.call("FinishHand", own, _HandValue(playerHand), false)
	_PvPWait()

func _PvPWait():
	var game : Dictionary = npc.ownScript.call("GetGame", own)
	if game.has("result"):
		_PvPShowResult(game)
	else:
		Mes("Your part's done. Now we wait for the other one...")
		Choice("Check", _PvPWaitCheck)
		Choice("Forfeit", _PvPForfeit)

func _PvPWaitCheck():
	var game : Dictionary = npc.ownScript.call("GetGame", own)
	if game.has("result"):
		_PvPShowResult(game)
	else:
		Mes("Still thinking... Some people take forever.")
		Choice("Check", _PvPWaitCheck)
		Choice("Forfeit", _PvPForfeit)

func _PvPShowResult(game : Dictionary):
	var isP1 : bool = game.get("p1") == own
	var myVal : int = game.get("p1Value") if isP1 else game.get("p2Value")
	var oppBust : bool = game.get("p2Busted") if isP1 else game.get("p1Busted")
	var oppHand : Array = game.get("p2Hand") if isP1 else game.get("p1Hand")
	var myBust : bool = game.get("p1Busted") if isP1 else game.get("p2Busted")
	Mes("Your score: %d%s" % [myVal, " (Bust)" if myBust else ""])
	Mes("Opponent's hand: %s%s" % [_HandStr(oppHand), " (Bust)" if oppBust else ""])
	var result : String = game.get("result", "")
	if result == "draw":
		Mes("A draw! Evenly matched. That doesn't happen often at my table.")
	elif (result == "p1" and isP1) or (result == "p2" and not isP1):
		Mes("Victory is yours! The cards favored you today.")
	else:
		Mes("Tough break. The cards are fickle, but they always come back around.")
	npc.ownScript.call("CleanupGame", own)
	Choice("Play again", StartPvP)
	Choice("Leave", Decline)

func _PvPForfeit():
	npc.ownScript.call("ForfeitPvP", own)
	Mes("Walking away mid-game? In my day, that'd cost you a round of drinks.")
	Choice("Play again", StartPvP)
	Choice("Leave", Decline)
