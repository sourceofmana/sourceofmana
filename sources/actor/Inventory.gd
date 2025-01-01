extends Object
class_name ActorInventory

var actor : Actor					= null
var items: Array[Item]				= []
var equipments : Array[ItemCell]	= []

#
func GetItem(cell : ItemCell) -> Item:
	for item in items:
		if item.cell.name == cell.name:
			return item
	return null
#
func PushItem(cell : ItemCell, count : int) -> bool:
	if count <= 0 or not cell:
		return false

	if cell.stackable:
		var item : Item = GetItem(cell)
		if item:
			item.count += count
			return true

		if items.size() >= ActorCommons.InventorySize:
			return false
		items.append(Item.new(cell, count))
	else:
		if items.size() + count > ActorCommons.InventorySize:
			return false
		for _i in range(count):
			if items.size() >= ActorCommons.InventorySize:
				return false
			items.append(Item.new(cell))

	return true

func PopItem(cell : ItemCell, count : int) -> bool:
	if count <= 0 or not cell:
		return false

	var toRemove : Array[Item] = []
	for item in items:
		if item.cell.name == cell.name:
			if cell.stackable:
				if item.count >= count:
					item.count -= count
					if item.count <= 0:
						items.erase(item)
					return true
				else:
					return false
			else:
				toRemove.append(item)
				break

	if not cell.stackable and toRemove.size() == count:
		for item in toRemove:
			UnequipItem(cell)
			items.erase(item)
		return true

	return false

func HasItem(cell : ItemCell, count : int) -> bool:
	if count <= 0 or not cell:
		return false

	var totalCount : int = 0
	for item in items:
		if item.cell.id == cell.id:
			if cell.stackable:
				return item.count >= count
			else:
				totalCount += 1
				if totalCount >= count:
					return true
	return false

func HasSpace(count : int) -> bool:
	var inventoryCount : int = 0
	for item in items:
		inventoryCount += 1 if item.cell.stackable else item.count
	return inventoryCount + count < ActorCommons.InventorySize

#
func GetWeight() -> float:
	var weight : float = 0.0
	for item in items:
		weight += item.cell.weight * item.count
	return weight / 1000.0

func UseItem(cell : ItemCell):
	if cell and cell.type == CellCommons.Type.ITEM and cell.usable and actor and RemoveItem(cell):
		if cell.effects.has(CellCommons.effectHP):
			actor.stat.SetHealth(cell.effects[CellCommons.effectHP])
		if cell.effects.has(CellCommons.effectMana):
			actor.stat.SetMana(cell.effects[CellCommons.effectMana])
		if cell.effects.has(CellCommons.effectStamina):
			actor.stat.SetStamina(cell.effects[CellCommons.effectStamina])

func EquipItem(cell : ItemCell):
	if cell and cell.type == CellCommons.Type.ITEM and cell.slot != ActorCommons.Slot.NONE and actor:
		equipments[cell.slot] = cell
		actor.stat.RefreshEntityStats()

func UnequipItem(cell : ItemCell):
	if cell and cell.type == CellCommons.Type.ITEM and cell.slot != ActorCommons.Slot.NONE and actor:
		equipments[cell.slot] = null
		actor.stat.RefreshEntityStats()

#
func AddItem(cell : ItemCell, count : int = 1) -> bool:
	if PushItem(cell, count):
		if actor is PlayerAgent:
			if actor.rpcRID != NetworkCommons.RidUnknown:
				Network.ItemAdded(cell.id, count, actor.rpcRID)
		return true
	return false

func RemoveItem(cell : ItemCell, count : int = 1) -> bool:
	if PopItem(cell, count):
		if actor is PlayerAgent:
			if actor.rpcRID != NetworkCommons.RidUnknown:
				Network.ItemRemoved(cell.id, count, actor.rpcRID)
		return true
	return false

#
func ImportInventory(data : Dictionary):
	for key in data.keys():
		var hasKey : bool = DB.ItemsDB.has(key)
		assert(hasKey, "Could not find the requested key within the ItemsDB %d" % [key])
		if hasKey:
			PushItem(DB.ItemsDB[key], data[key])

func ExportInventory() -> Dictionary:
	var data : Dictionary = {}
	for item in items:
		if data.has(item.cell.id):
			data[item.cell.id] += item.count
		else:
			data[item.cell.id] = item.count
	return data

#
func Init(actorNode : Actor):
	assert(actorNode != null, "Caller actor node should never be null")
	actor = actorNode
	for itemID in actor.data._equipments:
		var cell : ItemCell = DB.ItemsDB[itemID]
		AddItem(cell)
		EquipItem(cell)
