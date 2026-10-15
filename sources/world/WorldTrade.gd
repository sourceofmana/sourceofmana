extends RefCounted
class_name WorldTrade

#
class Session extends RefCounted:
	var parties : Array[PlayerAgent]		= []
	var offers : Array[Array]				= [[], []]
	var gp : PackedInt64Array				= [0, 0]
	var locked : Array[bool]				= [false, false]
	var revision : int						= 0

	func _init(requester : PlayerAgent, target : PlayerAgent):
		parties = [requester, target]

	func GetOther(player : PlayerAgent) -> PlayerAgent:
		return parties[1] if parties[0] == player else parties[0]

	func Unlock():
		locked = [false, false]

#
static var requests : Dictionary[int, Dictionary]	= {}

# Requests
static func CanTrade(player : PlayerAgent) -> bool:
	return player and ActorCommons.IsAlive(player) and not player.ownScript and not player.tradeSession and not player.isWarping

static func Request(requester : PlayerAgent, target : PlayerAgent):
	if not requester or not target or requester == target:
		return
	if not CanTrade(requester):
		NpcCommons.PushNotification(requester, "You can't trade right now.")
	elif not CanTrade(target):
		NpcCommons.PushNotification(requester, "%s is busy." % target.nick)
	elif not SkillCommons.IsTargetable(requester, target):
		NpcCommons.PushNotification(requester, "%s is too far away to trade." % target.nick)
	elif HasPendingRequest(target):
		NpcCommons.PushNotification(requester, "%s already has a pending trade request." % target.nick)
	else:
		requests[target.get_rid().get_id()] = {
			"requester": requester.get_rid().get_id(),
			"tick": Time.get_ticks_msec()
		}
		Network.TradeRequested(requester.nick, target.peerID)
		NpcCommons.PushNotification(requester, "Trade request sent to %s." % target.nick)

static func Respond(target : PlayerAgent, accept : bool):
	var request : Dictionary = requests.get(target.get_rid().get_id(), {})
	requests.erase(target.get_rid().get_id())
	if request.is_empty():
		return

	var requester : PlayerAgent = WorldAgent.GetAgent(request["requester"])
	if not requester or IsRequestExpired(request):
		NpcCommons.PushNotification(target, "This trade request has expired.")
	elif not accept:
		NpcCommons.PushNotification(requester, "%s declined your trade request." % target.nick)
	elif not CanTrade(target):
		NpcCommons.PushNotification(target, "You can't trade right now.")
	elif not CanTrade(requester):
		NpcCommons.PushNotification(target, "%s is busy." % requester.nick)
	elif not SkillCommons.IsTargetable(target, requester):
		NpcCommons.PushNotification(target, "%s is too far away to trade." % requester.nick)
	else:
		Open(requester, target)

# Session
static func Open(requester : PlayerAgent, target : PlayerAgent):
	var session : Session = Session.new(requester, target)
	requester.tradeSession = session
	target.tradeSession = session
	for player in session.parties:
		player.inventory.items_changed.connect(OnInventoryChanged.bind(player))
		player.SetRelativeMode(false, Vector2.ZERO)
		Network.TradeOpened(session.GetOther(player).nick, player.peerID)
	SendUpdate(session)

static func SetOffer(player : PlayerAgent, entries : Array, gpValue : int):
	var session : Session = player.tradeSession
	if not session:
		return

	var counts : Dictionary[ItemCell, int] = {}
	var isValid : bool = entries.size() <= ActorCommons.TradeMaxItems \
		and gpValue >= 0 and gpValue <= player.stat.gp \
		and ActorInventory.GetExchangeCounts(entries, counts)

	if isValid:
		for cell in counts:
			if cell.slot == ActorCommons.Slot.QUEST or player.inventory.GetAvailableCount(cell, true) < counts[cell]:
				isValid = false
				break

	if isValid:
		var offer : Array = []
		for cell in counts:
			offer.append([cell.id, counts[cell], cell.customfield])
		var playerIdx : int = session.parties.find(player)
		if offer != session.offers[playerIdx] or gpValue != session.gp[playerIdx]:
			session.offers[playerIdx] = offer
			session.gp[playerIdx] = gpValue
			session.revision += 1
			session.Unlock()
	else:
		NpcCommons.PushNotification(player, "Your offer is no longer valid.")

	SendUpdate(session)

static func SetLock(player : PlayerAgent, revision : int, state : bool):
	var session : Session = player.tradeSession
	if not session:
		return

	if revision == session.revision:
		session.locked[session.parties.find(player)] = state
		if session.locked[0] and session.locked[1]:
			Commit(session)
			return
	SendUpdate(session)

static func Cancel(player : PlayerAgent, reason : String):
	if player and player.tradeSession:
		Close(player.tradeSession, reason)

static func OnInventoryChanged(player : PlayerAgent):
	var session : Session = player.tradeSession
	if session and (session.locked[0] or session.locked[1]):
		session.revision += 1
		session.Unlock()
		SendUpdate(session)

# Commit
static func Commit(session : Session):
	var first : PlayerAgent = session.parties[0]
	var second : PlayerAgent = session.parties[1]

	var firstGives : Dictionary[ItemCell, int] = {}
	var firstGets : Dictionary[ItemCell, int] = {}
	var secondGives : Dictionary[ItemCell, int] = {}
	var secondGets : Dictionary[ItemCell, int] = {}

	if not ActorInventory.GetExchangeCounts(session.offers[0], firstGives) \
		or not ActorInventory.GetExchangeCounts(session.offers[1], firstGets) \
		or not ActorInventory.GetExchangeCounts(session.offers[1], secondGives) \
		or not ActorInventory.GetExchangeCounts(session.offers[0], secondGets):
		Close(session, "Trade cancelled, an offer is invalid.")
		return

	var failure : String = GetExchangeFailure(first, first.inventory.ValidateExchange(firstGives, firstGets, true), session.gp[0])
	if failure.is_empty():
		failure = GetExchangeFailure(second, second.inventory.ValidateExchange(secondGives, secondGets, true), session.gp[1])

	if not failure.is_empty():
		session.revision += 1
		session.Unlock()
		for player in session.parties:
			NpcCommons.PushNotification(player, failure)
		SendUpdate(session)
		return

	Detach(first)
	Detach(second)

	first.inventory.ApplyExchange(firstGives, firstGets)
	second.inventory.ApplyExchange(secondGives, secondGets)
	if first.stat.SpendGP(session.gp[0]):
		second.stat.AddGP(session.gp[0])
	if second.stat.SpendGP(session.gp[1]):
		first.stat.AddGP(session.gp[1])
	Launcher.SQL.RefreshCharacter(first)
	Launcher.SQL.RefreshCharacter(second)

	Util.PrintLog("Trade", "%s gave %s and %d GP, %s gave %s and %d GP" % [first.nick, session.offers[0], session.gp[0], second.nick, session.offers[1], session.gp[1]])
	for player in session.parties:
		Network.TradeClosed("Trade completed.", player.peerID)

static func GetExchangeFailure(player : PlayerAgent, result : ActorInventory.ExchangeResult, gpValue : int) -> String:
	match result:
		ActorInventory.ExchangeResult.MISSING_ITEMS:
			return "%s no longer has the offered items." % player.nick
		ActorInventory.ExchangeResult.NO_SPACE:
			return "%s doesn't have enough inventory space." % player.nick
		ActorInventory.ExchangeResult.INVALID:
			return "Trade failed, an offer is invalid."

	if player.stat.gp < gpValue:
		return "%s no longer has the offered GP." % player.nick

	return ""

# Commons
static func IsRequestExpired(request : Dictionary) -> bool:
	return Time.get_ticks_msec() - request["tick"] > ActorCommons.TradeRequestTimeoutMs

static func HasPendingRequest(target : PlayerAgent) -> bool:
	var request : Dictionary = requests.get(target.get_rid().get_id(), {})
	return not request.is_empty() and not IsRequestExpired(request)

static func Detach(player : PlayerAgent):
	player.tradeSession = null
	Callback.RemoveCallback(player.inventory.items_changed, OnInventoryChanged.bind(player))

static func Close(session : Session, reason : String):
	for player in session.parties:
		if player.tradeSession == session:
			Detach(player)
			if player.peerID != NetworkCommons.PeerUnknownID:
				Network.TradeClosed(reason, player.peerID)

static func SendUpdate(session : Session):
	for playerIdx in session.parties.size():
		var otherIdx : int = 1 - playerIdx
		var player : PlayerAgent = session.parties[playerIdx]
		if player.peerID != NetworkCommons.PeerUnknownID:
			Network.TradeUpdate(session.offers[playerIdx], session.gp[playerIdx], session.offers[otherIdx], session.gp[otherIdx], session.locked[playerIdx], session.locked[otherIdx], session.revision, player.peerID)
