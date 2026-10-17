extends NpcScript
class_name MerchantScript

#
var stockPrices : Dictionary[int, int]	= {}
var isShopOpen : bool					= false

# Overridable merchant definition
func GetStock() -> PackedStringArray:
	return []

func GetBuyPrice(cell : ItemCell) -> int:
	return cell.buyPrice

func GetSellPrice(cell : ItemCell) -> int:
	return cell.sellPrice

# Shop
func GetShopBuyPrice(cell : ItemCell) -> int:
	return stockPrices.get(cell.id, 0) if cell and cell.customfield.is_empty() else 0

func GetShopSellPrice(cell : ItemCell) -> int:
	return maxi(GetSellPrice(cell), 0) if cell and cell.slot != ActorCommons.Slot.QUEST else 0

func OpenShop():
	stockPrices.clear()
	for itemName in GetStock():
		var cell : ItemCell = DB.GetItem(DB.GetCellHash(itemName))
		if cell:
			var price : int = GetBuyPrice(cell)
			assert(price > 0, "Merchant item %s has no buy price" % itemName)
			if price > 0:
				stockPrices[cell.id] = price
	assert(HasValidPrices(), "Merchant %s has buy prices lower than or equal to sell prices" % npc.nick)

	var sellPrices : Dictionary[int, int] = {}
	for item in own.inventory.items:
		var cell : ItemCell = DB.GetItem(item.cellID, item.cellCustomfield) if item else null
		if cell:
			var price : int = GetShopSellPrice(cell)
			if price > 0:
				sellPrices[cell.id] = price

	isShopOpen = true
	Network.MerchantOpened(npc.nick, stockPrices, sellPrices, own.peerID)

func CloseShop():
	if isShopOpen:
		isShopOpen = false
		Close()

func Trade(sellEntries : Array, buyEntries : Array):
	if not isShopOpen:
		return

	var sellCounts : Dictionary[ItemCell, int] = {}
	var buyCounts : Dictionary[ItemCell, int] = {}
	var isValid : bool = sellEntries.size() <= ActorCommons.TradeMaxItems \
		and buyEntries.size() <= ActorCommons.TradeMaxItems \
		and ActorInventory.GetExchangeCounts(sellEntries, sellCounts) \
		and ActorInventory.GetExchangeCounts(buyEntries, buyCounts) \
		and not (sellCounts.is_empty() and buyCounts.is_empty())

	var balance : int = 0
	if isValid:
		for cell in sellCounts:
			var price : int = GetShopSellPrice(cell)
			isValid = isValid and price > 0
			balance += price * sellCounts[cell]
		for cell in buyCounts:
			var price : int = GetShopBuyPrice(cell)
			isValid = isValid and price > 0 and buyCounts[cell] <= ActorCommons.MerchantMaxItemCount
			balance -= price * buyCounts[cell]

	if not isValid:
		Notification("This trade is not valid.")
		return
	if own.stat.gp + balance < 0:
		Notification("You don't have enough GP.")
		return

	match own.inventory.ValidateExchange(sellCounts, buyCounts, true):
		ActorInventory.ExchangeResult.MISSING_ITEMS:
			Notification("You no longer have the offered items.")
			return
		ActorInventory.ExchangeResult.NO_SPACE:
			Notification("You don't have enough inventory space.")
			return

	own.inventory.ApplyExchange(sellCounts, buyCounts)
	if balance < 0:
		own.stat.SpendGP(-balance)
	elif balance > 0:
		own.stat.AddGP(balance)
	Launcher.SQL.RefreshCharacter(own)

	Util.PrintLog("Merchant", "%s traded with %s, sold %s, bought %s, balance %d GP" % [own.nick, npc.nick, sellEntries, buyEntries, balance])
	Network.TradeClosed("Trade completed.", own.peerID)
	CloseShop()

func HasValidPrices() -> bool:
	for cell in DB.ItemsDB.values():
		var buyPrice : int = GetShopBuyPrice(cell)
		var sellPrice : int = GetShopSellPrice(cell)

		if buyPrice > 0 and buyPrice <= maxi(sellPrice, cell.sellPrice):
			push_error("Merchant %s sells %s for %d GP, not above its sell price (%d GP here, %d GP by default)" % [npc.nick, cell.name, buyPrice, sellPrice, cell.sellPrice])
			return false

		if sellPrice > 0 and cell.buyPrice > 0 and sellPrice >= cell.buyPrice:
			push_error("Merchant %s buys %s for %d GP, not below its default buy price (%d GP)" % [npc.nick, cell.name, sellPrice, cell.buyPrice])
			return false

	return true

#
func OnStart():
	Choice("Trade", OpenShop)
	Choice("Cancel")

func OnQuit():
	if isShopOpen:
		isShopOpen = false
		if own.peerID != NetworkCommons.PeerUnknownID:
			Network.TradeClosed("", own.peerID)
	super.OnQuit()

func IsWaiting() -> bool:
	return super.IsWaiting() or isShopOpen
