extends Object
class_name SkillCommons

# Constants
const SkillNone : int					= -1
const SkillDefaultAttack : int			= 0

# Actions
enum ConsomeType
{
	HEALTH = 0,
	MANA,
	STAMINA,
}

static func TryConsume(agent : BaseAgent, stat : SkillCommons.ConsomeType, skill : SkillCell) -> bool:
	var callable : Callable
	var canConsome : bool		= false
	var exhaust : int			= 0

	match stat:
		SkillCommons.ConsomeType.HEALTH:
			if skill.effects.has(CellCommons.effectHP):
				exhaust = -skill.effects[CellCommons.effectHP]
			callable = agent.stat.SetHealth
			canConsome = agent.stat.health >= exhaust
		SkillCommons.ConsomeType.MANA:
			if skill.effects.has(CellCommons.effectMana):
				exhaust = -skill.effects[CellCommons.effectMana]
			callable = agent.stat.SetMana
			canConsome = agent.stat.mana >= exhaust
		SkillCommons.ConsomeType.STAMINA:
			if skill.effects.has(CellCommons.effectStamina):
				exhaust = -skill.effects[CellCommons.effectStamina]
			callable = agent.stat.SetStamina
			canConsome = agent.stat.stamina >= exhaust

	if canConsome:
		callable.call(-exhaust)

	return canConsome

static func GetDamage(agent : BaseAgent, target : BaseAgent, skill : SkillCell, rng : float) -> Skill.AlterationInfo:
	var info : Skill.AlterationInfo = Skill.AlterationInfo.new()
	var skillValue : int = skill.effects[CellCommons.effectDamage] if skill.effects.has(CellCommons.effectDamage) else 0
	info.value = max(1, agent.stat.current.attack + skillValue - target.stat.current.defense)

	var critMaster : bool = agent.stat.current.critRate > target.stat.current.dodgeRate
	if critMaster and rng > 1.0 - agent.stat.current.critRate:
		info.type = ActorCommons.Alteration.CRIT
		info.value *= 2
	elif not critMaster and rng > 1.0 - target.stat.current.dodgeRate:
		info.type = ActorCommons.Alteration.DODGE
		info.value = 0
	else:
		info.type = ActorCommons.Alteration.HIT
		info.value = ceili(info.value * rng)

	info.value += min(0, target.stat.health - info.value)
	if info.value <= 0:
		info.type = ActorCommons.Alteration.DODGE

	return info

static func GetHeal(agent : BaseAgent, target : BaseAgent, skill : SkillCell, rng : float) -> int:
	var skillValue : int = skill.effects[CellCommons.effectHP] if skill.effects.has(CellCommons.effectHP) else 0
	var healValue : int = int(agent.stat.concentration + skillValue * rng)
	healValue = min(healValue, target.stat.current.maxHealth - target.stat.health)
	return healValue

static func GetSurroundingTargets(agent : BaseAgent, skill : SkillCell) -> Array[BaseAgent]:
	var targets : Array[BaseAgent] = []
	var neighbours : Array[Array] = WorldAgent.GetNeighboursFromAgent(agent)

	if skill.effects.has(CellCommons.effectDamage):
		for neighbour in neighbours[1]:
			if ActorCommons.IsAlive(neighbour) and IsNear(agent, neighbour, GetRange(agent, skill)):
				targets.append(neighbour)
	if skill.effects.has(CellCommons.effectHP):
		for neighbour in neighbours[2]:
			if ActorCommons.IsAlive(neighbour) and IsNotSelf(agent, neighbour) and IsNear(agent, neighbour, GetRange(agent, skill)):
				targets.append(neighbour)

	return targets

static func GetRNG(hasStamina : bool) -> float:
	return randf_range(0.9 if hasStamina else 0.1, 1.0)

static func GetRange(agent : BaseAgent, skill : SkillCell) -> int:
	return agent.stat.current.attackRange + skill.cellRange

# Checks
static func IsNotSelf(agent : BaseAgent, target : BaseAgent) -> bool:
	return agent != target

static func IsNear(agent : BaseAgent, target : BaseAgent, skillRange : int) -> bool:
	return WorldNavigation.GetPathLength(agent, target.position) - agent.entityRadius - target.entityRadius <= skillRange

static func IsSameMap(agent : BaseAgent, target : BaseAgent) -> bool:
	return WorldAgent.GetMapFromAgent(agent) == WorldAgent.GetMapFromAgent(target)

static func IsTargetable(agent : BaseAgent, target : BaseAgent, skill : SkillCell) -> bool:
	return IsNotSelf(agent, target) and ActorCommons.IsAlive(target) and IsSameMap(agent, target) and IsNear(agent, target, GetRange(agent, skill))

static func IsCasting(agent : BaseAgent, skill : SkillCell = null) -> bool:
	return (agent.currentSkillID == skill.id) if skill else DB.SkillsDB.has(agent.currentSkillID)

static func IsCoolingDown(agent : BaseAgent, skill : SkillCell) -> bool:
	return agent.cooldownTimers.has(skill.name) and agent.cooldownTimers[skill.name] != null and not agent.cooldownTimers[skill.name].is_queued_for_deletion()

static func IsDelayed(skill : SkillCell) -> bool:
	return skill.projectilePreset != null

static func HasSkill(agent : BaseAgent, skill : SkillCell) -> bool:
	return agent.skillSet.find(skill) != -1

static func HasActionInProgress(agent : BaseAgent) -> bool:
	return agent.currentSkillID >= SkillDefaultAttack or not agent.actionTimer.is_stopped()
