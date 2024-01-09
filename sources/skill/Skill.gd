extends Node2D
class_name Skill

#
class DamageInfo:
	var damage : int					= 0
	var type : EntityCommons.DamageType	= EntityCommons.DamageType.MISS

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

static func GetDamage(agent : BaseAgent, target : BaseAgent, skill : SkillData) -> DamageInfo:
	var info : DamageInfo		= DamageInfo.new()
	var hasStamina : bool		= SetConsume(agent, "stamina", skill)
	var lowerBound : float		= 0.9 if hasStamina else 0.1
	var RNGValue : float		= randf_range(lowerBound, 1.0)

	var critMaster : bool		= agent.stat.current.critRate >= target.stat.current.critRate
	if critMaster and RNGValue > 1.0 - agent.stat.current.critRate:
		info.type = EntityCommons.DamageType.CRIT
		info.damage = int(agent.stat.current.attackStrength * 2)
	elif not critMaster and RNGValue > 1.0 - target.stat.current.critRate:
		info.type = EntityCommons.DamageType.DODGE
		info.damage = 0
	else:
		info.damage = int(agent.stat.current.attackStrength * RNGValue)
		info.type = EntityCommons.DamageType.DODGE if info.damage == 0 else EntityCommons.DamageType.HIT

	return info

static func GetSurroundingTargets(_agent : BaseAgent, _skill : SkillData) -> Array[BaseAgent]:
	Util.Assert(false, "Not implemented")
	return []

# Checks
static func IsAlive(agent : BaseAgent) -> bool:
	return agent and agent.currentState != EntityCommons.State.DEATH
static func IsNotSelf(agent : BaseAgent, target : BaseAgent) -> bool:
	return agent != target
static func IsNear(agent : BaseAgent, target : BaseAgent) -> bool:
	return WorldNavigation.GetPathLength(agent, target.position) <= agent.stat.current.attackRange
static func IsSameMap(agent : BaseAgent, target : BaseAgent) -> bool:
	return WorldAgent.GetMapFromAgent(agent) == WorldAgent.GetMapFromAgent(target)
static func IsTargetable(agent : BaseAgent, target : BaseAgent) -> bool:
	return IsNotSelf(agent, target) and IsAlive(agent) and IsAlive(target) and IsSameMap(agent, target)
static func IsCasting(agent : BaseAgent) -> bool:
	return agent.currentSkillCast >= 0
static func IsCoolingDown(agent : BaseAgent, skill : SkillData) -> bool:
	return agent.cooldownTimers.has(skill._id) and agent.cooldownTimers[skill._id] != null and not agent.cooldownTimers[skill._id].is_queued_for_deletion()

# Skill Flow
static func Cast(agent : BaseAgent, target : BaseAgent, skill : SkillData):
	if IsCasting(agent) or IsCoolingDown(agent, skill):
		return
	if skill._mode == TargetMode.SINGLE and (not IsTargetable(agent, target) or not IsNear(agent, target)):
		Stopped(agent)
		return
	Casting(agent, target, skill)

static func Casting(agent : BaseAgent, target : BaseAgent, skill : SkillData):
	if agent:
		agent.ResetNav()
		agent.currentSkillCast = skill._id
		Util.StartTimer(agent.castTimer, agent.stat.current.castAttackDelay, Skill.Attack.bind(agent, target, skill))
		if skill._mode == TargetMode.SINGLE:
			agent.currentOrientation = Vector2(target.position - agent.position).normalized()
		agent.UpdateChanged()

static func Attack(agent : BaseAgent, target : BaseAgent, skill : SkillData):
	if IsCasting(agent) and SetConsume(agent, "mana", skill):
		match skill._mode:
			TargetMode.SINGLE:
				if IsTargetable(agent, target) and IsNear(agent, target):
					Handle(agent, target, skill)
					return
			TargetMode.ZONE:
				for zoneTarget in GetSurroundingTargets(agent, skill):
					Handle(agent, zoneTarget, skill)
				return
			TargetMode.SELF:
				Handle(agent, agent, skill)
				return
	Missed(agent, target)

static func Handle(agent : BaseAgent, target : BaseAgent, skill : SkillData):
	if skill._damage > 0:		Damaged(agent, target, skill)
	if skill._heal > 0:			Healed(agent, target, skill)
	Casted(agent, target, skill)

# Handling
static func Casted(agent : BaseAgent, target : BaseAgent, skill : SkillData):
	var timer : Timer = Util.SelfDestructTimer(agent, agent.stat.current.cooldownAttackDelay, Skill.Cast.bind(agent, target, skill), skill._name + " CoolDown")
	agent.cooldownTimers[agent.currentSkillCast] = timer
	agent.currentSkillCast = -1

static func Damaged(agent : BaseAgent, target : BaseAgent, skill : SkillData):
	var info : DamageInfo = GetDamage(agent, target, skill)
	Launcher.Network.Server.NotifyInstancePlayers(null, agent, "TargetDamaged", [target.get_rid().get_id(), info.damage, info.type])
	target.stat.health = max(target.stat.health - info.damage, 0)
	if target.stat.health <= 0:
		Killed(agent, target)

static func Healed(_agent : BaseAgent, _target : BaseAgent, _skill : SkillData):
	Util.Assert(false, "Not implemented")
	pass

static func Killed(agent : BaseAgent, target : BaseAgent):
	agent.stat.XpBonus(target)
	Util.StartTimer(target.deathTimer, target.stat.deathDelay, WorldAgent.RemoveAgent.bind(target))
	Stopped(agent)

static func Stopped(agent : BaseAgent):
	agent.currentSkillCast = -1
	if not agent.castTimer.is_stopped():
		agent.castTimer.stop()

static func Missed(agent : BaseAgent, target : BaseAgent):
	Launcher.Network.Server.NotifyInstancePlayers(null, agent, "TargetDamaged", [target.get_rid().get_id(), 0, EntityCommons.DamageType.MISS])
	Stopped(agent)
