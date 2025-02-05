extends Object
class_name ActorInventory

var actor : Actor					= null
var items: Array[Item]				= []
var equipments : Array[ItemCell]	= []

#
func GetItem(cell : ItemCell) -> Item:
	if not cell:
		return null
	for item in items:
		if item and item.cell.id == cell.id and item.cell.customfield and cell.customfield:
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
		if ActorCommons.IsSameCell(item.cell, cell):
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
		if ActorCommons.IsSameCell(item.cell, cell):
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

func DropItem(cell : ItemCell, count : int):
	if RemoveItem(cell, count):
		var item : Item = Item.new(cell, count)
		WorldDrop.PushDrop(item, actor)

func EquipItem(cell : ItemCell):
	if cell and cell.type == CellCommons.Type.ITEM and cell.slot != ActorCommons.Slot.NONE and equipments[cell.slot] != cell and actor:
		equipments[cell.slot] = cell
		actor.stat.RefreshEntityStats()
		if actor is PlayerAgent and actor.rpcRID != NetworkCommons.RidUnknown:
			Network.Server.NotifyNeighbours(actor, "ItemEquiped", [cell.id, cell.customfield, true])

func UnequipItem(cell : ItemCell):
	if cell and cell.type == CellCommons.Type.ITEM and cell.slot != ActorCommons.Slot.NONE and equipments[cell.slot] != null and actor:
		equipments[cell.slot] = null
		actor.stat.RefreshEntityStats()
		if actor is PlayerAgent and actor.rpcRID != NetworkCommons.RidUnknown:
			Network.Server.NotifyNeighbours(actor, "ItemEquiped", [cell.id, cell.customfield, false])

#
func AddItem(cell : ItemCell, count : int = 1) -> bool:
	if PushItem(cell, count):
		if actor is PlayerAgent and actor.rpcRID != NetworkCommons.RidUnknown:
			Network.ItemAdded(cell.id, cell.customfield, count, actor.rpcRID)
		return true
	return false

func RemoveItem(cell : ItemCell, count : int = 1) -> bool:
	if PopItem(cell, count):
		if actor is PlayerAgent and actor.rpcRID != NetworkCommons.RidUnknown:
			Network.ItemRemoved(cell.id, cell.customfield, count, actor.rpcRID)
		return true
	return false

#
func ImportInventory(data : Dictionary):
	for key in data.keys():
		var keyData : Dictionary = data[key]
		var id : int = keyData.get("id", -1)
		var customfield : String = keyData.get("customfield", "")
		var cell : ItemCell = DB.GetItem(id, customfield)
		if cell:
			var count : int = keyData.get("count", 1)
			PushItem(cell, count)

func ExportInventory() -> Dictionary:
	var idx : int = 0
	var data : Dictionary = {}
	for item in items:
		data[idx] = {
			"id": item.cell.id,
			"customfield": item.cell.customfield,
			"count": item.count,
		}
		idx += 1
	return data

#
func _init(actorNode : Actor):
	assert(actorNode != null, "Caller actor node should never be null")
	actor = actorNode
	equipments.resize(ActorCommons.SlotEquipmentCount)
	for item in actor.data._equipments:
		if item and item is ItemCell:
			AddItem(item)
			EquipItem(item)
