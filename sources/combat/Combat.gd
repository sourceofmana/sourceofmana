extends Node2D
class_name Combat

#
class DamageInfo:
	var damage : int					= 0
	var type : EntityCommons.DamageType	= EntityCommons.DamageType.MISS

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

static func GetDamage(agent : BaseAgent, target : BaseAgent, info : DamageInfo, skill : SkillData):
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

# Attack Flow
static func Cast(agent : BaseAgent, target : BaseAgent, castID : int):
	# To remove isAttacking, store cast ID instead
	if not agent.isAttacking and IsTargetable(agent, target):
		if IsNear(agent, target):
			Casting(agent, target, castID)
			agent.ResetNav()
		else:
			TargetStopped(agent)

static func Casting(agent : BaseAgent, target : BaseAgent, castID : int):
	if agent:
		Util.StartTimer(agent.castTimer, agent.stat.current.castAttackDelay, Combat.Attack.bind(agent, target, castID))
		agent.isAttacking = true
		if target:
			agent.currentOrientation = Vector2(target.position - agent.position).normalized()
		agent.UpdateChanged()

static func Attack(agent : BaseAgent, target : BaseAgent, castID : int):
	var info : DamageInfo = DamageInfo.new()
	if agent.isAttacking and IsTargetable(agent, target) and IsNear(agent, target):
		var castIDStr : String = str(castID)
		var hasMana : bool = SetConsume(agent, "mana", Launcher.DB.SkillsDB[castIDStr])
		if hasMana:
			GetDamage(agent, target, info, Launcher.DB.SkillsDB[castIDStr])
			TargetDamaged(agent, target, info)
			Attacked(agent, target, castID)
			return

	TargetDamaged(agent, target, info)
	TargetStopped(agent)

static func Attacked(agent : BaseAgent, target : BaseAgent, castID : int):
	Util.StartTimer(agent.cooldownTimer, agent.stat.current.cooldownAttackDelay, Combat.Cast.bind(agent, target, castID))
	agent.isAttacking = false

# Target Handling
static func TargetDamaged(agent : BaseAgent, target : BaseAgent, info : DamageInfo):
	Launcher.Network.Server.NotifyInstancePlayers(null, agent, "TargetDamaged", [target.get_rid().get_id(), info.damage, info.type])
	target.stat.health = max(target.stat.health - info.damage, 0)
	if target.stat.health <= 0:
		TargetKilled(agent, target)

static func TargetKilled(agent : BaseAgent, target : BaseAgent):
	agent.stat.XpBonus(target)
	Util.StartTimer(target.deathTimer, target.stat.deathDelay, WorldAgent.RemoveAgent.bind(target))
	TargetStopped(agent)

static func TargetStopped(agent : BaseAgent):
	if agent.cooldownTimer.is_stopped():
		agent.isAttacking = false
		if not agent.castTimer.is_stopped():
			agent.castTimer.stop()
