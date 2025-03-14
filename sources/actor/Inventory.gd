extends Object
class_name ActorInventory

var actor : Actor					= null
var items : Array[Item]				= []
var equipments : Array[ItemCell]	= []

#
func GetItem(cell : ItemCell) -> Item:
	if not cell:
		return null
	for item in items:
		if CellCommons.IsSameItem(cell, item):
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
		if CellCommons.IsSameItem(cell, item):
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
		if CellCommons.IsSameItem(cell, item):
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
		if item:
			var cell : ItemCell = DB.GetItem(item.cellID)
			if cell:
				inventoryCount += 1 if cell.stackable else item.count
	return inventoryCount + count < ActorCommons.InventorySize

#
func GetWeight() -> float:
	var weight : float = 0.0
	for item in items:
		if item:
			var cell : ItemCell = DB.GetItem(item.cellID)
			if cell:
				weight += cell.weight * item.count
	return weight / 1000.0

func UseItem(cell : ItemCell):
	if cell and cell.modifiers and cell.type == CellCommons.Type.ITEM and cell.usable and actor and RemoveItem(cell):
		cell.modifiers.Apply(actor)

func DropItem(cell : ItemCell, count : int):
	if RemoveItem(cell, count):
		var item : Item = Item.new(cell, count)
		WorldDrop.PushDrop(item, actor)

func EquipItem(cell : ItemCell):
	if cell and cell.type == CellCommons.Type.ITEM and cell.slot != ActorCommons.Slot.NONE and equipments[cell.slot] != cell and actor:
		var previousItem : ItemCell = equipments[cell.slot]
		if previousItem and previousItem.modifiers:
			previousItem.modifiers.Unequip(actor)
		equipments[cell.slot] = cell
		if cell and cell.modifiers:
			cell.modifiers.Equip(actor)
		actor.stat.RefreshEntityStats()
		if actor is PlayerAgent and actor.rpcRID != NetworkCommons.RidUnknown:
			var charID : int = Peers.GetCharacter(actor.rpcRID)
			if charID != NetworkCommons.RidUnknown:
				Launcher.SQL.UpdateEquipment(charID, ExportEquipment())
			Network.NotifyNeighbours(actor, "ItemEquiped", [cell.id, cell.customfield, true])

func UnequipItem(cell : ItemCell):
	if cell and cell.type == CellCommons.Type.ITEM and cell.slot != ActorCommons.Slot.NONE and equipments[cell.slot] == cell and actor:
		if cell and cell.modifiers:
			cell.modifiers.Unequip(actor)
		equipments[cell.slot] = null
		actor.stat.RefreshEntityStats()
		if actor is PlayerAgent and actor.rpcRID != NetworkCommons.RidUnknown:
			var charID : int = Peers.GetCharacter(actor.rpcRID)
			if charID != NetworkCommons.RidUnknown:
				Launcher.SQL.UpdateEquipment(charID, ExportEquipment())
			Network.NotifyNeighbours(actor, "ItemEquiped", [cell.id, cell.customfield, false])

#
func AddItem(cell : ItemCell, count : int = 1) -> bool:
	if PushItem(cell, count):
		if actor is PlayerAgent and actor.rpcRID != NetworkCommons.RidUnknown:
			var charID : int = Peers.GetCharacter(actor.rpcRID)
			if charID != NetworkCommons.RidUnknown:
				Launcher.SQL.AddItem(charID, cell.id, cell.customfield, count)
			Network.ItemAdded(cell.id, cell.customfield, count, actor.rpcRID)
		return true
	return false

func RemoveItem(cell : ItemCell, count : int = 1) -> bool:
	if PopItem(cell, count):
		if actor is PlayerAgent and actor.rpcRID != NetworkCommons.RidUnknown:
			var charID : int = Peers.GetCharacter(actor.rpcRID)
			if charID != NetworkCommons.RidUnknown:
				Launcher.SQL.RemoveItem(charID, cell.id, cell.customfield, count)
			Network.ItemRemoved(cell.id, cell.customfield, count, actor.rpcRID)
		return true
	return false

#
func ImportInventory(data : Array[Dictionary]):
	for item in data:
		var id : int = item.get("item_id", DB.UnknownHash)
		var customfield : String = item.get("customfield", "")
		var cell : ItemCell = DB.GetItem(id, customfield)
		if cell:
			var count : int = item.get("count", 1)
			PushItem(cell, count)

func ExportInventory() -> Array[Dictionary]:
	var data : Array[Dictionary] = []
	for item in items:
		data.push_back(item.Export())
	return data

#
func ImportEquipment(data : Dictionary):
	for equipmentID in ActorCommons.SlotEquipmentCount:
		var equipmentKey : String = ActorCommons.GetSlotName(equipmentID).to_lower()
		var cellHash = data.get(equipmentKey, DB.UnknownHash)
		if cellHash != null and cellHash != DB.UnknownHash:
			var cellCustomfield = data.get(equipmentKey + "Custom", "")
			if cellCustomfield == null:
				cellCustomfield = ""
			var cell : ItemCell = DB.GetItem(cellHash, cellCustomfield)
			if cell:
				EquipItem(cell)

func ExportEquipment() -> Dictionary:
	var dic : Dictionary = {}
	for equipmentID in ActorCommons.SlotEquipmentCount:
		var equipmentKey : String = ActorCommons.GetSlotName(equipmentID).to_lower()
		if equipments[equipmentID]:
			dic[equipmentKey] = equipments[equipmentID].id
			dic[equipmentKey + "Custom"] = equipments[equipmentID].customfield
		else:
			dic[equipmentKey] = DB.UnknownHash
			dic[equipmentKey + "Custom"] = ""
	return dic

#
func _init(actorNode : Actor):
	actor = actorNode
	equipments.resize(ActorCommons.SlotEquipmentCount)
	for item in actor.data._equipments:
		if item and item is ItemCell:
			AddItem(item)
			EquipItem(item)
