extends RefCounted
class_name ActorInventory

var actor : Actor					= null
var items : Array[Item]				= []
var equipment : Array[Item]			= []
var itemCount : int					= 0

#
func GetEquipmentCell(slot : int) -> ItemCell:
	if slot >= ActorCommons.Slot.FIRST_EQUIPMENT and slot < ActorCommons.Slot.LAST_MODIFIER:
		var item : Item = equipment[slot]
		if item:
			return DB.GetItem(item.cellID, item.cellCustomfield)
	return null

func IsItemEquipped(item : Item) -> bool:
	return equipment.find(item) != -1

func GetItem(cell : ItemCell) -> Item:
	if not cell:
		return null
	for item in items:
		if CellCommons.IsSameItem(cell, item):
			return item
	return null

func FindItemIndex(cell : ItemCell) -> int:
	var cachedIdx : int = -1
	var itemIdx : int = 0
	for item in items:
		if CellCommons.IsSameItem(cell, item):
			if not IsItemEquipped(item):
				return itemIdx
			elif cachedIdx == -1:
				cachedIdx = itemIdx
		itemIdx += 1
	return cachedIdx

#
func PushItem(cell : ItemCell, count : int) -> bool:
	if count <= 0 or not cell:
		return false

	if cell.stackable:
		var item : Item = GetItem(cell)
		if item:
			item.count += count
			return true

		if itemCount >= ActorCommons.InventorySize:
			return false

		itemCount += 1
		items.append(Item.new(cell, count))
	else:
		if itemCount + count > ActorCommons.InventorySize:
			return false
		for _i in count:
			if itemCount >= ActorCommons.InventorySize:
				return false

			itemCount += 1
			items.append(Item.new(cell))

	return true

func PopItem(cell : ItemCell, count : int, itemIndex : int) -> bool:
	if count <= 0 or not cell:
		return false

	var item : Item = null
	if cell.stackable:
		item = GetItem(cell)
		if not item or item.count < count:
			return false
		item.count -= count
		if item.count <= 0:
			items.erase(item)
			itemCount -= 1
	else:
		if itemIndex < 0 or itemIndex >= itemCount or not CellCommons.IsSameItem(cell, items[itemIndex]):
			return false
		item = items[itemIndex]
		if IsItemEquipped(item):
			UnequipItem(cell)
		items.erase(item)
		itemCount -= 1
	return true

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
	return inventoryCount + count <= ActorCommons.InventorySize

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
	if not cell or cell.type != CellCommons.Type.ITEM or not cell.usable or not actor:
		return
	var itemIndex : int = FindItemIndex(cell)
	if itemIndex >= 0 and RemoveItem(cell, 1, itemIndex):
		if cell.modifiers:
			cell.modifiers.Apply(actor)
		if cell.cellScript:
			var script : CellScript = cell.cellScript.new()
			if script:
				script.Execute(actor)

func DropItem(cell : ItemCell, count : int, itemIndex : int):
	var inst : WorldInstance = WorldAgent.GetInstanceFromAgent(actor)
	if inst and inst.map and not inst.map.HasFlags(WorldMap.Flags.NO_DROP):
		if RemoveItem(cell, count, itemIndex):
			var item : Item = Item.new(cell, count)
			WorldDrop.PushDrop(item, actor)

func EquipItem(cell : ItemCell, itemIndex : int):
	if not cell or cell.type != CellCommons.Type.ITEM or cell.slot == ActorCommons.Slot.NONE or not actor:
		return

	var targetItem : Item = null
	if itemIndex >= 0 and itemIndex < itemCount and CellCommons.IsSameItem(cell, items[itemIndex]):
		targetItem = items[itemIndex]
	else:
		targetItem = Item.new(cell)
	if equipment[cell.slot] == targetItem:
		return

	var previousItem : Item = equipment[cell.slot]
	if previousItem:
		var previousCell : ItemCell = DB.GetItem(previousItem.cellID, previousItem.cellCustomfield)
		if previousCell and previousCell.modifiers:
			previousCell.modifiers.Unequip(actor)
	equipment[cell.slot] = targetItem
	if cell.modifiers:
		cell.modifiers.Equip(actor)
	actor.stat.RefreshEntityStats()

	if actor is PlayerAgent and actor.peerID != NetworkCommons.PeerUnknownID:
		var charID : int = Peers.GetCharacter(actor.peerID)
		if charID != NetworkCommons.PeerUnknownID:
			Launcher.SQL.UpdateEquipment(charID, ExportEquipment())
		var inst : WorldInstance = WorldAgent.GetInstanceFromAgent(actor)
		if inst:
			Network.NotifyInstance(inst, "ItemEquiped", [actor.get_rid().get_id(), cell.id, cell.customfield, true, itemIndex])

func UnequipItem(cell : ItemCell):
	if not actor or not cell or cell.type != CellCommons.Type.ITEM or cell.slot == ActorCommons.Slot.NONE:
		return
	var equippedItem : Item = equipment[cell.slot]
	if not equippedItem or not CellCommons.IsSameItem(cell, equippedItem):
		return

	if cell.modifiers:
		cell.modifiers.Unequip(actor)
	equipment[cell.slot] = null
	actor.stat.RefreshEntityStats()

	if actor is PlayerAgent and actor.peerID != NetworkCommons.PeerUnknownID:
		var charID : int = Peers.GetCharacter(actor.peerID)
		if charID != NetworkCommons.PeerUnknownID:
			Launcher.SQL.UpdateEquipment(charID, ExportEquipment())
		var inst : WorldInstance = WorldAgent.GetInstanceFromAgent(actor)
		if inst:
			Network.NotifyInstance(inst, "ItemEquiped", [actor.get_rid().get_id(), cell.id, cell.customfield, false, -1])

#
func AddItem(cell : ItemCell, count : int = 1) -> bool:
	if PushItem(cell, count):
		if actor is PlayerAgent and actor.peerID != NetworkCommons.PeerUnknownID:
			var charID : int = Peers.GetCharacter(actor.peerID)
			if charID != NetworkCommons.PeerUnknownID:
				Launcher.SQL.AddItem(charID, cell.id, cell.customfield, count)
			Network.ItemAdded(cell.id, cell.customfield, count, actor.peerID)
		actor.stat.weight += cell.weight * count / 1000.0
		return true
	return false

func RemoveItem(cell : ItemCell, count : int, itemIndex : int) -> bool:
	if PopItem(cell, count, itemIndex):
		if actor is PlayerAgent and actor.peerID != NetworkCommons.PeerUnknownID:
			var charID : int = Peers.GetCharacter(actor.peerID)
			if charID != NetworkCommons.PeerUnknownID:
				Launcher.SQL.RemoveItem(charID, cell.id, cell.customfield, count)
			Network.ItemRemoved(cell.id, cell.customfield, count, itemIndex, actor.peerID)
		actor.stat.weight -= cell.weight * count / 1000.0
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
	actor.stat.weight = Formula.GetWeight(actor.inventory)

	for slot in ActorCommons.SlotEquipmentCount:
		var equippedItem : Item = equipment[slot]
		if not equippedItem or items.has(equippedItem):
			continue
		for item in items:
			if item.cellID == equippedItem.cellID and item.cellCustomfield == equippedItem.cellCustomfield and not IsItemEquipped(item):
				equipment[slot] = item
				break

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
			var cell : ItemCell = DB.GetItem(cellHash, cellCustomfield)
			if cell:
				EquipItem(cell, FindItemIndex(cell))

func ExportEquipment() -> Dictionary:
	var dic : Dictionary = {}
	for equipmentID in ActorCommons.SlotEquipmentCount:
		var equipmentKey : String = ActorCommons.GetSlotName(equipmentID).to_lower()
		if equipment[equipmentID]:
			dic[equipmentKey] = equipment[equipmentID].cellID
			dic[equipmentKey + "Custom"] = equipment[equipmentID].cellCustomfield
		else:
			dic[equipmentKey] = DB.UnknownHash
			dic[equipmentKey + "Custom"] = ""
	return dic

static func UpdateExportedEquipment(equipmentDic : Dictionary, itemID : int, customfield : StringName, state : bool):
	var cell : ItemCell = DB.GetItem(itemID, customfield)
	if not cell or cell.slot == ActorCommons.Slot.NONE:
		return
	var slotKey : String = ActorCommons.GetSlotName(cell.slot).to_lower()
	if state:
		equipmentDic[slotKey] = itemID
		equipmentDic[slotKey + "Custom"] = customfield
	else:
		equipmentDic[slotKey] = DB.UnknownHash
		equipmentDic[slotKey + "Custom"] = ""

#
func _init(actorNode : Actor):
	actor = actorNode
	equipment.resize(ActorCommons.SlotEquipmentCount)
	for item in actor.data._equipment:
		if item and item is ItemCell:
			AddItem(item)
			EquipItem(item, itemCount - 1)
