extends RefCounted
class_name CellCommons

enum Type
{
	ITEM = 0,
	EMOTE,
	SKILL,
	COUNT
}

#
static func CompareCell(cell : BaseCell, id : int, customfield : String) -> bool:
	return cell and \
	cell.id == id and \
	(
		cell is not ItemCell or \
		cell.customfield == customfield \
	)

static func IsSameItem(cell : BaseCell, item : Item) -> bool:
	return item and CompareCell(cell, item.cellID, item.cellCustomfield)

static func IsSameCell(cellA : BaseCell, cellB : BaseCell) -> bool:
	return cellB and CompareCell(cellA, cellB.id, cellB.customfield if cellB is ItemCell else "")

static func IsEquipment(cell : ItemCell) -> bool:
	return cell.slot >= ActorCommons.Slot.FIRST_EQUIPMENT and cell.slot < ActorCommons.Slot.LAST_EQUIPMENT

static func IsEquipped(cell : BaseCell) -> bool:
	return cell and cell is ItemCell and IsEquipment(cell) and \
	Launcher.Player and Launcher.Player.inventory and Launcher.Player.inventory.equipment and \
	IsSameCell(cell, Launcher.Player.inventory.equipment[cell.slot])

enum Modifier {
	None = 0,
	Health,
	Mana,
	Stamina,
	MaxMana,
	RegenMana,
	CritRate,
	MAttack,
	MDefense,
	MaxStamina,
	RegenStamina,
	CooldownDelay,
	MaxHealth,
	RegenHealth,
	Defense,
	CastDelay,
	DodgeRate,
	AttackRange,
	WalkSpeed,
	WeightCapacity,
	Attack,
	Count
}

static func GetModifierDisplayName(effect : Modifier) -> String:
	match effect:
		Modifier.Health:		return "Health"
		Modifier.Mana:			return "Mana"
		Modifier.Stamina:		return "Stamina"
		Modifier.MaxHealth:		return "Max Health"
		Modifier.MaxMana:		return "Max Mana"
		Modifier.MaxStamina:	return "Max Stamina"
		Modifier.Attack:		return "Attack"
		Modifier.Defense:		return "Defense"
		Modifier.MAttack:		return "M. Attack"
		Modifier.MDefense:		return "M. Defense"
		Modifier.AttackRange:	return "Atk Range"
		Modifier.CritRate:		return "Crit Rate"
		Modifier.DodgeRate:		return "Dodge Rate"
		Modifier.CastDelay:		return "Cast Delay"
		Modifier.CooldownDelay:	return "Cooldown"
		Modifier.RegenHealth:	return "HP Regen"
		Modifier.RegenMana:		return "MP Regen"
		Modifier.RegenStamina:	return "SP Regen"
		Modifier.WalkSpeed:		return "Walk Speed"
		Modifier.WeightCapacity: return "Carry Weight"
		_:						return "Unknown"

static func FormatModifierValue(effect : Modifier, value : Variant) -> String:
	match effect:
		Modifier.CritRate, Modifier.DodgeRate:
			var intVal : int = int(float(value) * 100.0)
			return ("+" if intVal >= 0 else "") + str(intVal) + "%"
		Modifier.CastDelay, Modifier.CooldownDelay:
			var floatVal : float = float(value)
			return ("+" if floatVal >= 0.0 else "") + ("%.2f" % floatVal) + "s"
		_:
			var intVal : int = int(value)
			return ("+" if intVal >= 0 else "") + str(intVal)
