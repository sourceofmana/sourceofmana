extends Object
class_name Formula

#
const attributePointsBase : int					= 10
const attributePointPerLevel : int				= 3
const coefMaxMana : float						= 1.5
const coefRegenMana : float						= 0.05
const coefMaxStamina : float					= 1.8
const coefRegenStamina : float					= 5.0
const coefMaxHealth : float						= 2.0
const coefRegenHealth : float					= 0.01
const coefDefense : float						= 2.0
const coefAttack : float						= 2.0
const weightSnap : float						= 0.001

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
	return stat.morphStat.maxMana + F((stat.concentration + stat.level) * coefMaxMana)

static func GetRegenMana(stat : ActorStats) -> int:
	return 1 + FFifth(stat.concentration) + FPercent(GetMaxMana(stat) * coefRegenMana)

static func GetCritRate(stat : ActorStats) -> float:
	return stat.morphStat.critRate + Percent(FFifth(stat.concentration + stat.level))

# Endurance related stats
static func GetMaxStamina(stat : ActorStats) -> int:
	return stat.morphStat.maxStamina + F((stat.endurance + stat.level) * coefMaxStamina)

static func GetRegenStamina(stat : ActorStats) -> int:
	return 1 + FFifth(stat.endurance) + FPercent(GetMaxStamina(stat) * coefRegenStamina)

static func GetCooldownAttackDelay(stat : ActorStats) -> float:
	return maxf(0.001, stat.morphStat.cooldownAttackDelay - Percent(stat.endurance + stat.level))

# Vitality related stats
static func GetMaxHealth(stat : ActorStats) -> int:
	return stat.morphStat.maxHealth + F((stat.vitality + stat.level) * coefMaxHealth)

static func GetRegenHealth(stat : ActorStats) -> int:
	return 1 + FFifth(stat.vitality) + FPercent(GetMaxHealth(stat) * coefRegenHealth)

static func GetDefense(stat : ActorStats) -> int:
	return stat.morphStat.defense + F(stat.vitality * coefDefense) + stat.level

# Agility related stats
static func GetCastAttackDelay(stat : ActorStats) -> float:
	return max(0.001, stat.morphStat.castAttackDelay - Percent(stat.agility + stat.level))

static func GetDodgeRate(stat : ActorStats) -> float:
	return stat.morphStat.dodgeRate + Percent(FFifth(stat.agility + stat.level))

static func GetAttackRange(stat : ActorStats) -> int:
	return stat.morphStat.attackRange + FFifth(stat.agility)

# Strength related stats
static func GetWalkSpeed(stat : ActorStats) -> float:
	return stat.morphStat.walkSpeed + Fifth(stat.strength + stat.level)

static func GetWeightCapacity(stat : ActorStats) -> float:
	return snappedf(stat.morphStat.weightCapacity + Half(stat.strength + stat.level), weightSnap)

static func GetAttack(stat : ActorStats) -> int:
	return stat.morphStat.attack + F(stat.strength * coefAttack) + stat.level

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
	return stat.morphStat.walkSpeed / stat.current.walkSpeed if stat.current.walkSpeed > 0 else 1.0

# Experience management
static func GetXpBonus(stat : ActorStats) -> float:
	return stat.baseExp * pow(stat.level, 1.7)

static func ApplyXp(agent : BaseAgent):
	var bonus : float = Formula.GetXpBonus(agent.stat)
	for entry in agent.attackers:
		if entry.attacker != null and not entry.attacker.is_queued_for_deletion():
			var bonusScaled : int = int(bonus * agent.GetDamageRatio(entry.attacker))
			entry.attacker.stat.AddExperience(bonusScaled)

# Attribute points
static func GetMaxAttributePoints(stat : ActorStats) -> int:
	return attributePointsBase + stat.level * attributePointPerLevel

static func GetAssignedAttributePoints(stat : ActorStats) -> int:
	return stat.agility + stat.vitality + stat.strength + stat.endurance + stat.concentration
