extends NpcScript

#
var waitingPlayer : PlayerAgent		= null
var games : Dictionary				= {}

#
func JoinPvP(player : PlayerAgent) -> int:
	if waitingPlayer and is_instance_valid(waitingPlayer) and waitingPlayer != player:
		var game : Dictionary = _CreateGame(waitingPlayer, player)
		games[waitingPlayer.get_rid().get_id()] = game
		games[player.get_rid().get_id()] = game
		NpcCommons.PushNotification(waitingPlayer, "An opponent has arrived! Talk to %s." % npc.nick)
		waitingPlayer = null
		return 1
	waitingPlayer = player
	return 0

func GetGame(player : PlayerAgent) -> Dictionary:
	return games.get(player.get_rid().get_id(), {})

func GetHand(player : PlayerAgent) -> Array:
	var game : Dictionary = GetGame(player)
	if game.is_empty():
		return []
	if game.get("p1") == player:
		return game.get("p1Hand", [])
	return game.get("p2Hand", [])

func DrawCard(player : PlayerAgent) -> int:
	var game : Dictionary = GetGame(player)
	if game.is_empty():
		return -1
	var gameDeck : Array = game.get("deck", [])
	if gameDeck.is_empty():
		return -1
	return gameDeck.pop_back()

func FinishHand(player : PlayerAgent, value : int, busted : bool):
	var game : Dictionary = GetGame(player)
	if game.is_empty():
		return
	if game.get("p1") == player:
		game["p1Done"] = true
		game["p1Value"] = value
		game["p1Busted"] = busted
	else:
		game["p2Done"] = true
		game["p2Value"] = value
		game["p2Busted"] = busted
	if game.get("p1Done", false) and game.get("p2Done", false):
		_ResolveGame(game)

func LeavePvP(player : PlayerAgent):
	if not player or not is_instance_valid(player):
		return
	if waitingPlayer == player:
		waitingPlayer = null
	var rid : int = player.get_rid().get_id()
	if games.has(rid):
		var game : Dictionary = games[rid]
		if not game.has("result"):
			var isP1 : bool = game.get("p1") == player
			var opponent = game.get("p2") if isP1 else game.get("p1")
			if isP1:
				game["p1Done"] = true
				game["p1Value"] = 0
				game["p1Busted"] = true
			else:
				game["p2Done"] = true
				game["p2Value"] = 0
				game["p2Busted"] = true
			_ResolveGame(game)
			if opponent and is_instance_valid(opponent):
				NpcCommons.PushNotification(opponent, "Your opponent left. You win!")
		_ClearGameCallbacks(game)
		games.erase(rid)

func ForfeitPvP(player : PlayerAgent):
	LeavePvP(player)

func CleanupGame(player : PlayerAgent):
	var game : Dictionary = GetGame(player)
	if not game.is_empty():
		_ClearGameCallbacks(game)
	games.erase(player.get_rid().get_id())

#
func _CreateGame(p1 : PlayerAgent, p2 : PlayerAgent) -> Dictionary:
	var gameDeck : Array = []
	gameDeck.resize(52)
	for i : int in range(52):
		gameDeck[i] = i
	gameDeck.shuffle()
	Callback.OneShotCallback(p1.tree_exiting, _PlayerLeft.bind(p1))
	Callback.OneShotCallback(p2.tree_exiting, _PlayerLeft.bind(p2))
	return {
		"p1": p1, "p2": p2,
		"deck": gameDeck,
		"p1Hand": [gameDeck.pop_back(), gameDeck.pop_back()],
		"p2Hand": [gameDeck.pop_back(), gameDeck.pop_back()],
		"p1Value": 0, "p2Value": 0,
		"p1Done": false, "p2Done": false,
		"p1Busted": false, "p2Busted": false,
	}

func _ClearGameCallbacks(game : Dictionary):
	var p1 = game.get("p1")
	var p2 = game.get("p2")
	if p1 and is_instance_valid(p1):
		Callback.ClearOneShot(p1.tree_exiting)
	if p2 and is_instance_valid(p2):
		Callback.ClearOneShot(p2.tree_exiting)

func _ResolveGame(game : Dictionary):
	var p1v : int = game.get("p1Value", 0)
	var p2v : int = game.get("p2Value", 0)
	var p1b : bool = game.get("p1Busted", false)
	var p2b : bool = game.get("p2Busted", false)
	if p1b and p2b:
		game["result"] = "draw"
	elif p1b:
		game["result"] = "p2"
	elif p2b:
		game["result"] = "p1"
	elif p1v > p2v:
		game["result"] = "p1"
	elif p2v > p1v:
		game["result"] = "p2"
	else:
		game["result"] = "draw"

func _PlayerLeft(player : PlayerAgent):
	LeavePvP(player)
