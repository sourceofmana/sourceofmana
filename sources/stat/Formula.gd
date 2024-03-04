extends Object
class_name Formula

#
static func GetMaxHealth(stat : ActorStats) -> int:
	var value : float = stat.vitality
	value += stat.base.maxHealth
	return int(value)

static func GetMaxMana(stat : ActorStats) -> int:
	var value : float = stat.concentration
	value += stat.base.maxMana
	return int(value)

static func GetMaxStamina(stat : ActorStats) -> int:
	var value : float = stat.endurance * 0.5
	value += stat.concentration * 0.5
	value += stat.base.maxStamina
	return int(value)

static func GetAttackStrength(stat : ActorStats) -> int:
	var value : float = stat.strength * 2
	value += stat.base.attackStrength
	return int(value)

static func GetCritRate(stat : ActorStats) -> float:
	var value : float = 1 + int(stat.concentration * 0.2)
	value *= stat.base.critRate
	return value

static func GetCastAttackDelay(stat : ActorStats) -> float:
	var value : float = stat.base.castAttackDelay
	value -= stat.concentration / 100.0
	return maxf(value, 0.001)

static func GetCooldownAttackDelay(stat : ActorStats) -> float:
	var value : float = stat.base.cooldownAttackDelay
	value -= stat.agility / 100.0
	return maxf(value, 0.001)

static func GetAttackRange(stat : ActorStats) -> int:
	return stat.base.attackRange

static func GetWalkSpeed(stat : ActorStats) -> float:
	var value : float = stat.level * 0.1
	value += stat.base.walkSpeed
	return value

static func GetWeightCapacity(stat : ActorStats) -> float:
	var value : float = stat.level
	value += stat.strength * 2
	value += stat.base.weightCapacity
	return snappedf(value, 0.001)

#
static func ClampHealth(stat : ActorStats) -> int:
	return clampi(stat.health, 0, stat.current.maxHealth)

static func ClampMana(stat : ActorStats) -> int:
	return clampi(stat.mana, 0, stat.current.maxMana)

static func ClampStamina(stat : ActorStats) -> int:
	return clampi(stat.stamina, 0, stat.current.maxStamina)

static func GetWeight(inventory : EntityInventory) -> float:
	return inventory.calculate_weight() / 1000.0

#
static func GetCastAttackRatio(stat : ActorStats) -> float:
	return stat.base.castAttackDelay / stat.current.castAttackDelay if stat.current.castAttackDelay > 0 else 1.0

static func GetWalkRatio(stat : ActorStats) -> float:
	return stat.base.walkSpeed / stat.current.walkSpeed if stat.current.walkSpeed > 0 else 1.0

#
static func GetRegenHealth(stat : ActorStats) -> int:
	var regen : float = stat.current.maxHealth * 0.01
	return max(stat.base.regenHealth, regen)

static func GetRegenMana(stat : ActorStats) -> int:
	var regen : float = stat.current.maxMana * 0.007
	return max(stat.base.regenMana, regen)

static func GetRegenStamina(stat : ActorStats) -> int:
	var regen : float = stat.current.maxStamina * 0.07
	return max(stat.base.regenStamina, regen)

#
static func GetXpBonus(stat : ActorStats) -> float:
	var personalMean : float = float(stat.strength + stat.vitality + stat.agility + stat.endurance + stat.concentration) / 5
	var bonus : float = float(stat.level * personalMean)
	return bonus

static func ApplyXp(agent : BaseAgent):
	var bonus : float = Formula.GetXpBonus(agent.stat)
	for attacker in agent.attackers:
		if attacker != null and not attacker.is_queued_for_deletion():
			var bonusScaled : int = int(bonus * agent.GetDamageRatio(attacker))
			ActorStats.AddExperience(attacker, bonusScaled)

#
static func GetMaxPersonalPoints(stat : ActorStats) -> int:
	return stat.level * 3 + 5

static func GetAssignedPersonalPoints(stat : ActorStats) -> int:
	return stat.agility + stat.vitality + stat.strength + stat.endurance + stat.concentration
