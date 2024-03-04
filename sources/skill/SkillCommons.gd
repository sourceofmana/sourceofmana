extends Object
class_name SkillCommons

# Actions
static func SetConsume(agent : BaseAgent, stat : String, skill : SkillData) -> bool:
	var canConsume : bool = false
	if stat in agent.stat and stat in skill:
		var value : int = agent.stat.get(stat)
		var exhaust : int = skill.get(stat)

		canConsume = value >= exhaust
		if value >= exhaust:
			agent.stat.set(stat, value - exhaust)

	return canConsume

static func GetDamage(agent : BaseAgent, target : BaseAgent, skill : SkillData, rng : float) -> Skill.AlterationInfo:
	var info : Skill.AlterationInfo = Skill.AlterationInfo.new()
	info.value = agent.stat.current.attackStrength + skill._damage

	var critMaster : bool = agent.stat.current.critRate >= target.stat.current.critRate
	if critMaster and rng > 1.0 - agent.stat.current.critRate:
		info.type = ActorCommons.Alteration.CRIT
		info.value *= 2
	elif not critMaster and rng > 1.0 - target.stat.current.critRate:
		info.type = ActorCommons.Alteration.DODGE
		info.value = 0
	else:
		info.type = ActorCommons.Alteration.HIT
		info.value = int(info.value * rng)

	info.value += min(0, target.stat.health - info.value)
	if info.value == 0:
		info.type = ActorCommons.Alteration.DODGE

	return info

static func GetHeal(agent : BaseAgent, target : BaseAgent, skill : SkillData, rng : float) -> int:
	var healValue : int = int(agent.stat.concentration + skill._heal * rng)
	healValue = min(healValue, target.stat.current.maxHealth - target.stat.health)
	return healValue

static func GetSurroundingTargets(agent : BaseAgent, skill : SkillData) -> Array[BaseAgent]:
	var targets : Array[BaseAgent] = []
	var neighbours : Array[Array] = WorldAgent.GetNeighboursFromAgent(agent)

	if skill._damage > 0:
		for neighbour in neighbours[1]:
			if IsAlive(neighbour) and IsNear(agent, neighbour, GetRange(agent, skill)):
				targets.append(neighbour)
	if skill._heal > 0:
		for neighbour in neighbours[2]:
			if IsAlive(neighbour) and IsNotSelf(agent, neighbour) and IsNear(agent, neighbour, GetRange(agent, skill)):
				targets.append(neighbour)

	return targets

static func GetRNG(hasStamina : bool) -> float:
	return randf_range(0.9 if hasStamina else 0.1, 1.0)

static func GetRange(agent : BaseAgent, skill : SkillData) -> int:
	return agent.stat.current.attackRange + skill._range

# Checks
static func IsAlive(agent : BaseAgent) -> bool:
	return agent and agent.state != ActorCommons.State.DEATH

static func IsNotSelf(agent : BaseAgent, target : BaseAgent) -> bool:
	return agent != target

static func IsNear(agent : BaseAgent, target : BaseAgent, skillRange : int) -> bool:
	return WorldNavigation.GetPathLength(agent, target.position) <= skillRange

static func IsSameMap(agent : BaseAgent, target : BaseAgent) -> bool:
	return WorldAgent.GetMapFromAgent(agent) == WorldAgent.GetMapFromAgent(target)

static func IsTargetable(agent : BaseAgent, target : BaseAgent, skill : SkillData) -> bool:
	return IsNotSelf(agent, target) and IsAlive(target) and IsSameMap(agent, target) and IsNear(agent, target, GetRange(agent, skill))

static func IsCasting(agent : BaseAgent, skill : SkillData = null) -> bool:
	return (agent.currentSkillName == skill._name) if skill else DB.SkillsDB.has(agent.currentSkillName)

static func IsCoolingDown(agent : BaseAgent, skill : SkillData) -> bool:
	return agent.cooldownTimers.has(skill._name) and agent.cooldownTimers[skill._name] != null and not agent.cooldownTimers[skill._name].is_queued_for_deletion()

static func IsDelayed(skill : SkillData) -> bool:
	return skill._projectilePreset != null

static func HasSkill(agent : BaseAgent, skill : SkillData) -> bool:
	return agent.skillSet.find(skill) != -1

static func HasActionInProgress(agent : BaseAgent) -> bool:
	return agent.currentSkillName.length() > 0 or not agent.actionTimer.is_stopped()
