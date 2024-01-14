extends Node2D
class_name Skill

#
class AlterationInfo:
	var value : int						= 0
	var type : EntityCommons.Alteration	= EntityCommons.Alteration.MISS

enum TargetMode
{
	SINGLE = 0,
	ZONE,
	SELF,
}

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

static func GetDamage(agent : BaseAgent, target : BaseAgent, _skill : SkillData, rng : float) -> AlterationInfo:
	var info : AlterationInfo = AlterationInfo.new()

	var critMaster : bool = agent.stat.current.critRate >= target.stat.current.critRate
	if critMaster and rng > 1.0 - agent.stat.current.critRate:
		info.type = EntityCommons.Alteration.CRIT
		info.value = int(agent.stat.current.attackStrength * 2)
	elif not critMaster and rng > 1.0 - target.stat.current.critRate:
		info.type = EntityCommons.Alteration.DODGE
		info.value = 0
	else:
		info.type = EntityCommons.Alteration.HIT
		info.value = int(agent.stat.current.attackStrength * rng)

	info.value += min(0, target.stat.health - info.value)
	if info.value == 0:
		info.type = EntityCommons.Alteration.DODGE

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
	return agent and agent.currentState != EntityCommons.State.DEATH
static func IsNotSelf(agent : BaseAgent, target : BaseAgent) -> bool:
	return agent != target
static func IsNear(agent : BaseAgent, target : BaseAgent, skillRange : int) -> bool:
	return WorldNavigation.GetPathLength(agent, target.position) <= skillRange
static func IsSameMap(agent : BaseAgent, target : BaseAgent) -> bool:
	return WorldAgent.GetMapFromAgent(agent) == WorldAgent.GetMapFromAgent(target)
static func IsTargetable(agent : BaseAgent, target : BaseAgent) -> bool:
	return IsNotSelf(agent, target) and IsAlive(target) and IsSameMap(agent, target)
static func IsCasting(agent : BaseAgent) -> bool:
	return agent.currentSkillCastID >= 0
static func IsCoolingDown(agent : BaseAgent, skill : SkillData) -> bool:
	return agent.cooldownTimers.has(skill._id) and agent.cooldownTimers[skill._id] != null and not agent.cooldownTimers[skill._id].is_queued_for_deletion()

# Skill Flow
static func Cast(agent : BaseAgent, target : BaseAgent, skill : SkillData):
	if not IsAlive(agent) or IsCasting(agent) or IsCoolingDown(agent, skill):
		return
	if skill._mode == TargetMode.SINGLE and (not IsTargetable(agent, target) or not IsNear(agent, target, GetRange(agent, skill))):
		Stopped(agent)
		return

	if SetConsume(agent, "mana", skill):
		agent.SetSkillCastID(skill._id)
		Util.StartTimer(agent.castTimer, agent.stat.current.castAttackDelay + skill._castTime, Skill.Attack.bind(agent, target, skill))
		if skill._mode == TargetMode.SINGLE:
			agent.currentOrientation = Vector2(target.position - agent.position).normalized()
		agent.UpdateChanged()

static func Attack(agent : BaseAgent, target : BaseAgent, skill : SkillData):
	if IsCasting(agent):
		var hasStamina : bool		= SetConsume(agent, "stamina", skill)

		match skill._mode:
			TargetMode.SINGLE:
				if IsTargetable(agent, target) and IsNear(agent, target, GetRange(agent, skill)):
					Handle(agent, target, skill, GetRNG(hasStamina))
					return
			TargetMode.ZONE:
				for zoneTarget in GetSurroundingTargets(agent, skill):
					Handle(agent, zoneTarget, skill, GetRNG(hasStamina))
				return
			TargetMode.SELF:
				Handle(agent, agent, skill, GetRNG(hasStamina))
				return
	Missed(agent, target)

static func Handle(agent : BaseAgent, target : BaseAgent, skill : SkillData, rng : float):
	if skill._damage > 0:		Damaged(agent, target, skill, rng)
	if skill._heal > 0:			Healed(agent, target, skill, rng)
	Casted(agent, target, skill)

# Handling
static func Casted(agent : BaseAgent, target : BaseAgent, skill : SkillData):
	var callable : Callable = Skill.Cast.bind(agent, target, skill) if skill._repeat else Callable()
	var timer : Timer = Util.SelfDestructTimer(agent, agent.stat.current.cooldownAttackDelay + skill._cooldownTime, callable, skill._name + " CoolDown")
	agent.cooldownTimers[agent.currentSkillCastID] = timer
	agent.SetSkillCastID(-1)

static func Damaged(agent : BaseAgent, target : BaseAgent, skill : SkillData, rng : float):
	var info : AlterationInfo = GetDamage(agent, target, skill, rng)
	target.stat.health = max(target.stat.health - info.value, 0)
	Launcher.Network.Server.NotifyInstancePlayers(null, agent, "TargetAlteration", [target.get_rid().get_id(), info.value, info.type])
	if target.stat.health <= 0:
		Killed(agent, target)

static func Healed(agent : BaseAgent, target : BaseAgent, skill : SkillData, rng : float):
	var heal : int = GetHeal(agent, target, skill, rng)
	target.stat.health = min(target.stat.health + heal, target.stat.current.maxHealth)
	Launcher.Network.Server.NotifyInstancePlayers(null, agent, "TargetAlteration", [target.get_rid().get_id(), heal, EntityCommons.Alteration.HEAL])

static func Killed(agent : BaseAgent, target : BaseAgent):
	agent.stat.XpBonus(target)
	Util.StartTimer(target.deathTimer, target.stat.deathDelay, WorldAgent.RemoveAgent.bind(target))
	Stopped(agent)

static func Stopped(agent : BaseAgent):
	agent.SetSkillCastID(-1)
	agent.castTimer.stop()

static func Missed(agent : BaseAgent, target : BaseAgent):
	Launcher.Network.Server.NotifyInstancePlayers(null, agent, "TargetAlteration", [target.get_rid().get_id(), 0, EntityCommons.Alteration.MISS])
	Stopped(agent)
