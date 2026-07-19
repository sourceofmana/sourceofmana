extends RefCounted
class_name Formula

#
const attributePointsBase : int					= 4
const attributePointPerLevel : int				= 1
const attributeLevelCap : int					= 50
const coefAttackPerAttribute : float			= 3.0
const coefAttackPerLevel : float				= 0.4
const coefDefensePerAttribute : float			= 2.0
const coefDefensePerLevel : float				= 0.3
const coefHealthPerAttribute : float			= 10.0
const coefHealthPerLevel : float				= 2.0
const coefManaPerAttribute : float				= 5.0
const coefManaPerLevel : float					= 1.0
const coefStaminaPerAttribute : float			= 5.0
const coefStaminaPerLevel : float				= 1.0
const coefRatePerAttribute : float				= 0.005
const coefRatePerLevel : float					= 0.001
const coefDelayPerAttribute : float				= 0.01
const coefDelayPerLevel : float					= 0.002
const coefRegenMana : float						= 0.05
const coefRegenStamina : float					= 10.0
const coefRegenHealth : float					= 1.0
const weightSnap : float						= 0.001
const runningSpeedIncrease : float				= 50

# Base formulas functions
static func F(val) -> int:
	return floori(val)

static func Percent(val) -> float:
	return val * 0.01

static func FPercent(val) -> int:
	return F(Percent(val))

static func Fifth(val) -> float:
	return val * 0.2

static func FFifth(val) -> int:
	return F(Fifth(val))

static func Half(val) -> float:
	return val * 0.5

static func FHalf(val) -> int:
	return F(Half(val))

# Concentration related stats
static func GetMaxMana(stat : ActorStats) -> int:
	return stat.morphStat.maxMana + F(stat.concentration * coefManaPerAttribute + stat.level * coefManaPerLevel) + stat.modifiers.Get(CellCommons.Modifier.MaxMana, true)

static func GetRegenMana(stat : ActorStats) -> int:
	return 1 + FHalf(stat.concentration) + FPercent(GetMaxMana(stat) * coefRegenMana) + stat.modifiers.Get(CellCommons.Modifier.RegenMana, true)

static func GetCritRate(stat : ActorStats) -> float:
	return stat.morphStat.critRate + stat.concentration * coefRatePerAttribute + stat.level * coefRatePerLevel + stat.modifiers.Get(CellCommons.Modifier.CritRate, true)

static func GetMAttack(stat : ActorStats) -> int:
	return stat.morphStat.mattack + F(stat.concentration * coefAttackPerAttribute) + F(stat.level * coefAttackPerLevel) + stat.modifiers.Get(CellCommons.Modifier.MAttack, true)

static func GetMDefense(stat : ActorStats) -> int:
	return stat.morphStat.mdefense + F(stat.concentration * coefDefensePerAttribute) + F(stat.level * coefDefensePerLevel) + stat.modifiers.Get(CellCommons.Modifier.MDefense, true)

# Endurance related stats
static func GetMaxStamina(stat : ActorStats) -> int:
	return stat.morphStat.maxStamina + F(stat.endurance * coefStaminaPerAttribute + stat.level * coefStaminaPerLevel) + stat.modifiers.Get(CellCommons.Modifier.MaxStamina, true)

static func GetRegenStamina(stat : ActorStats) -> int:
	return stat.endurance * 2 + FFifth(stat.level) + FPercent(GetMaxStamina(stat) * coefRegenStamina) + stat.modifiers.Get(CellCommons.Modifier.RegenStamina, true)

static func GetCooldownAttackDelay(stat : ActorStats) -> float:
	return maxf(0.001, stat.morphStat.cooldownAttackDelay - stat.endurance * coefDelayPerAttribute - stat.level * coefDelayPerLevel) + stat.modifiers.Get(CellCommons.Modifier.CooldownDelay, true)

# Vitality related stats
static func GetMaxHealth(stat : ActorStats) -> int:
	return stat.morphStat.maxHealth + F(stat.vitality * coefHealthPerAttribute + stat.level * coefHealthPerLevel) + stat.modifiers.Get(CellCommons.Modifier.MaxHealth, true)

static func GetRegenHealth(stat : ActorStats) -> int:
	return 1 + FHalf(stat.vitality) + FPercent(GetMaxHealth(stat) * coefRegenHealth) + stat.modifiers.Get(CellCommons.Modifier.RegenHealth, true)

static func GetDefense(stat : ActorStats) -> int:
	return stat.morphStat.defense + F(stat.vitality * coefDefensePerAttribute) + F(stat.level * coefDefensePerLevel) + stat.modifiers.Get(CellCommons.Modifier.Defense, true)

# Agility related stats
static func GetCastAttackDelay(stat : ActorStats) -> float:
	return maxf(0.001, stat.morphStat.castAttackDelay - stat.agility * coefDelayPerAttribute - stat.level * coefDelayPerLevel) + stat.modifiers.Get(CellCommons.Modifier.CastDelay, true)

static func GetDodgeRate(stat : ActorStats) -> float:
	return stat.morphStat.dodgeRate + stat.agility * coefRatePerAttribute + stat.level * coefRatePerLevel + stat.modifiers.Get(CellCommons.Modifier.DodgeRate, true)

static func GetAttackRange(stat : ActorStats) -> int:
	return stat.morphStat.attackRange + FFifth(stat.agility) + stat.modifiers.Get(CellCommons.Modifier.AttackRange, true)

# Strength related stats
static func GetBaseWalkSpeed(stat : ActorStats) -> float:
	return stat.morphStat.walkSpeed + Fifth(stat.strength) + stat.modifiers.Get(CellCommons.Modifier.WalkSpeed, true)

static func GetWalkSpeed(stat : ActorStats) -> float:
	var walkSpeed : float = GetBaseWalkSpeed(stat)
	if stat.isRunning:
		walkSpeed += runningSpeedIncrease
	return walkSpeed

static func GetWeightCapacity(stat : ActorStats) -> float:
	return snappedf(stat.morphStat.weightCapacity + Half(stat.strength) + Fifth(stat.level), weightSnap) + stat.modifiers.Get(CellCommons.Modifier.WeightCapacity, true)

static func GetAttack(stat : ActorStats) -> int:
	return stat.morphStat.attack + F(stat.strength * coefAttackPerAttribute) + F(stat.level * coefAttackPerLevel) + stat.modifiers.Get(CellCommons.Modifier.Attack, true)

# GM modifiers
static func IsHidden(stat : ActorStats) -> bool:
	return stat.modifiers.Get(CellCommons.Modifier.Hide, true) > 0

static func IsInvisible(stat : ActorStats) -> bool:
	return stat.modifiers.Get(CellCommons.Modifier.Invisible, true) > 0

#
static func ClampHealth(stat : ActorStats) -> int:
	return clampi(stat.health, 0, stat.current.maxHealth)

static func ClampMana(stat : ActorStats) -> int:
	return clampi(stat.mana, 0, stat.current.maxMana)

static func ClampStamina(stat : ActorStats) -> int:
	return clampi(stat.stamina, 0, stat.current.maxStamina)

static func GetWeight(inventory : ActorInventory) -> float:
	return snappedf(inventory.GetWeight(), weightSnap)

# Animation ratios
static func GetWalkRatio(stat : ActorStats) -> float:
	var ratio : float = 1.0
	if stat.current.walkSpeed > 0:
		ratio *= stat.current.walkSpeed / stat.morphStat.walkSpeed
	return ratio

# Experience management
static func GetInternalXpBonus(baseExp : int, level : int) -> float:
	return baseExp * pow(level, 1.7)

static func GetXpBonus(stat : ActorStats) -> float:
	return GetInternalXpBonus(stat.baseExp, stat.level)

static func ApplyXp(agent : BaseAgent):
	var bonus : float = Formula.GetXpBonus(agent.stat)
	for entry in agent.attackers:
		if entry.attacker != null and not entry.attacker.is_queued_for_deletion():
			var damageRatio : float = agent.GetDamageRatio(entry.attacker)
			var bonusScaled : int = int(bonus * damageRatio)
			entry.attacker.stat.AddExperience(bonusScaled, false)
			if damageRatio > 0.5 and entry.attacker.progress:
				entry.attacker.progress.AddBestiary(agent.data._id, 1)

# Attribute points
static func GetMaxAttributePoints(level : int) -> int:
	return attributePointsBase + mini(level, attributeLevelCap) * attributePointPerLevel

static func GetAssignedAttributePoints(stat : ActorStats) -> int:
	return stat.agility + stat.vitality + stat.strength + stat.endurance + stat.concentration
