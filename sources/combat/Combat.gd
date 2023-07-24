extends Node2D
class_name Combat

# To move to stats
const exhaustPerAttack : int = 5

#
static func IsTargetable(agent : BaseAgent, enemy : BaseAgent) -> bool:
	if agent != enemy:
		if agent && agent.currentState != EntityCommons.State.DEATH:
			if enemy && enemy.currentState != EntityCommons.State.DEATH:
				if agent.castTimer.is_stopped() and agent.cooldownTimer.is_stopped():
					if WorldAgent.GetMapFromAgent(agent) == WorldAgent.GetMapFromAgent(enemy):
						return true
	return false

static func IsNear(agent : BaseAgent, enemy : BaseAgent) -> bool:
	var pathLength : int = int(WorldNavigation.GetPathLength(agent, enemy.position))
	if pathLength <= agent.stat.current.attackRange:
		return true
	return false

#
static func StartCastDelay(agent : BaseAgent):
	Util.StartTimer(agent.castTimer, Formulas.GetCastAttackDelay(agent.stat), Combat.Attack.bind(agent))
	agent.isAttacking = true

static func StartCooldownDelay(agent : BaseAgent):
	Util.StartTimer(agent.cooldownTimer, Formulas.GetCooldownAttackDelay(agent.stat), Combat.Cast.bind(agent))
	agent.isAttacking = false

#
static func Cast(agent : BaseAgent):
	if agent and not agent.isAttacking and IsTargetable(agent, agent.target):
		if IsNear(agent, agent.target):
			StartCastDelay(agent)
			agent.ResetNav()
		else:
			Stop(agent)

static func Stop(agent : BaseAgent):
	agent.target = null
	agent.isAttacking = false

static func Attack(agent : BaseAgent):
	if agent.isAttacking and IsTargetable(agent, agent.target) and IsNear(agent, agent.target):
		var hasStamina : bool		= agent.stat.stamina >= exhaustPerAttack
		agent.stat.stamina			= max(agent.stat.stamina - exhaustPerAttack, 0)

		var lowerBound : float		= 0.9 if hasStamina else 0.1
		var RNGvalue : float		= randf_range(lowerBound, 1.0)
		var damage : int			= int(agent.stat.current.attackStrength * RNGvalue)
		agent.target.stat.health = max(agent.target.stat.health - damage, 0)

		Launcher.Network.Server.NotifyInstancePlayers(null, agent, "DamageDealt", [agent.target.get_rid().get_id(), damage])

		if agent.target.stat.health <= 0:
			agent.stat.XpBonus(agent.target)
			Util.StartTimer(agent.target.deathTimer, agent.target.stat.deathDelay, WorldAgent.RemoveAgent.bind(agent.target))
			agent.target = null

		Combat.StartCooldownDelay(agent)
	else:
		Combat.Stop(agent)
