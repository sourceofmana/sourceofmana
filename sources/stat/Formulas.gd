extends Node
class_name Formulas

#
static func GetMaxHealth(stat : EntityStats) -> int:
	var value : float = stat.vitality
	value += stat.base.maxHealth
	return int(value)

static func GetMaxMana(stat : EntityStats) -> int:
	var value : float = stat.concentration
	value += stat.base.maxMana
	return int(value)

static func GetMaxStamina(stat : EntityStats) -> int:
	var value : float = stat.endurance * 0.5
	value += stat.concentration * 0.5
	value += stat.base.maxStamina
	return int(value)

static func GetAttackStrength(stat : EntityStats) -> int:
	var value : float = stat.strength * 2
	value += stat.base.attackStrength
	return int(value)

static func GetAttackSpeed(stat : EntityStats) -> float:
	var value : float = stat.agility * 2
	value += stat.base.attackSpeed
	return value

static func GetCritRate(stat : EntityStats) -> float:
	var value : float = 1 + int(stat.concentration * 0.2)
	value *= stat.base.critRate
	return value

static func GetCastAttackDelay(stat : EntityStats) -> float:
	var value : float = stat.current.attackSpeed
	value /= 250
	return value

static func GetCooldownAttackDelay(stat : EntityStats) -> float:
	var value : float = stat.current.attackSpeed
	value /= 500
	return value

static func GetAttackRange(stat : EntityStats) -> int:
	return stat.base.attackRange

static func GetWalkSpeed(stat : EntityStats) -> float:
	var value : float = stat.level * 0.1
	value += stat.base.walkSpeed
	return value

static func GetWeightCapacity(stat : EntityStats) -> float:
	var value : float = stat.level
	value += stat.strength * 2
	value += stat.base.weightCapacity * 0.3
	return snappedf(value, 0.001)

#
static func ClampHealth(stat : EntityStats) -> int:
	return clampi(stat.health, 0, stat.current.maxHealth)

static func ClampMana(stat : EntityStats) -> int:
	return clampi(stat.mana, 0, stat.current.maxMana)

static func ClampStamina(stat : EntityStats) -> int:
	return clampi(stat.stamina, 0, stat.current.maxStamina)

static func GetWeight(inventory : EntityInventory) -> float:
	return inventory.calculate_weight() / 1000.0

#
static func GetAttackRatio(stat : EntityStats) -> float:
	return stat.current.attackSpeed / stat.base.attackSpeed

static func GetWalkRatio(stat : EntityStats) -> float:
	return stat.current.walkSpeed / stat.base.walkSpeed

#
static func GetXpBonus(stat : EntityStats) -> float:
	var personalMean : float = float(stat.strength + stat.vitality + stat.agility + stat.endurance + stat.concentration) / 5
	var bonus : float = float(stat.level * personalMean)
	return bonus

static func ApplyXp(agent : BaseAgent):
	var bonus : float = Formulas.GetXpBonus(agent.stat)
	for attacker in agent.attackers:
		var bonusScaled : int = int(bonus * agent.GetDamageRatio(attacker))
		EntityStats.addExperience(attacker, bonusScaled)
