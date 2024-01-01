extends Node2D
class_name Combat

# To move to stats
const exhaustPerAttack : int = 5

#
static func IsTargetable(agent : BaseAgent, enemy : BaseAgent) -> bool:
	return agent != enemy and agent and enemy and \
		agent.currentState != EntityCommons.State.DEATH and \
		enemy.currentState != EntityCommons.State.DEATH and \
		agent.castTimer.is_stopped() and agent.cooldownTimer.is_stopped() and \
		WorldAgent.GetMapFromAgent(agent) == WorldAgent.GetMapFromAgent(enemy)

static func IsNear(agent : BaseAgent, enemy : BaseAgent) -> bool:
	return WorldNavigation.GetPathLength(agent, enemy.position) <= agent.stat.current.attackRange

#
static func StartCastDelay(agent : BaseAgent, target : BaseAgent):
	if agent:
		Util.StartTimer(agent.castTimer, Formulas.GetCastAttackDelay(agent.stat), Combat.Attack.bind(agent, target))
		agent.isAttacking = true
		if target:
			agent.currentOrientation = Vector2(target.position - agent.position).normalized()
		agent.UpdateChanged()

static func StartCooldownDelay(agent : BaseAgent, target : BaseAgent):
	Util.StartTimer(agent.cooldownTimer, Formulas.GetCooldownAttackDelay(agent.stat), Combat.Cast.bind(agent, target))
	agent.isAttacking = false

#
static func Cast(agent : BaseAgent, target : BaseAgent):
	if agent and not agent.isAttacking and IsTargetable(agent, target):
		if IsNear(agent, target):
			StartCastDelay(agent, target)
			agent.ResetNav()
		else:
			TargetStopped(agent)

static func Attack(agent : BaseAgent, target : BaseAgent):
	if agent.isAttacking and IsTargetable(agent, target) and IsNear(agent, target):
		var hasStamina : bool		= agent.stat.stamina >= exhaustPerAttack
		agent.stat.stamina			= max(agent.stat.stamina - exhaustPerAttack, 0)

		var lowerBound : float		= 0.9 if hasStamina else 0.1
		var RNGvalue : float		= randf_range(lowerBound, 1.0)
		var damage : int			= int(agent.stat.current.attackStrength * RNGvalue)
		var damageType : EntityCommons.DamageType = EntityCommons.DamageType.HIT
		if damage == 0:
			damageType = EntityCommons.DamageType.MISS

		target.stat.health = max(target.stat.health - damage, 0)
		Combat.TargetDamaged(agent, target, damage, damageType)

		if target.stat.health <= 0:
			Combat.TargetKilled(agent, target)

		Combat.StartCooldownDelay(agent, target)
	else:
		Combat.TargetDamaged(agent, target, 0, EntityCommons.DamageType.MISS)
		Combat.TargetStopped(agent)

#
static func TargetDamaged(agent : BaseAgent, target : BaseAgent, damage : int, type : EntityCommons.DamageType):
	Launcher.Network.Server.NotifyInstancePlayers(null, agent, "TargetDamaged", [target.get_rid().get_id(), damage, type])

static func TargetKilled(agent : BaseAgent, target : BaseAgent):
	agent.stat.XpBonus(target)
	Util.StartTimer(target.deathTimer, target.stat.deathDelay, WorldAgent.RemoveAgent.bind(target))
	TargetStopped(agent)

static func TargetStopped(agent : BaseAgent):
	if agent.cooldownTimer.is_stopped():
		agent.isAttacking = false
		if not agent.castTimer.is_stopped():
			agent.castTimer.stop()
