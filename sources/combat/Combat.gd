extends Node2D
class_name Combat

#
static func DealDamage(agent : BaseAgent, map : World.Map):
	var canAttack = false
	if map and agent.target:
		var target : BaseAgent = agent.target
		if WorldAgent.GetMapFromAgent(target) == map:
			var pathLength : int = int(WorldNavigation.GetPathLength(agent, target.position))
			if pathLength > agent.stat.current.attackRange:
				agent.WalkToward(target.position)
			else:
				canAttack = true
				agent.ResetNav()

				var damage : int = min(agent.stat.current.attackStrength * randf_range(0.9, 1.1), target.stat.health)
				target.stat.health -= damage
				Launcher.Network.Server.NotifyInstancePlayers(null, agent, "DamageDealt", [target.get_rid().get_id(), damage])

				if target.stat.health <= 0:
					Util.StartTimer(target.deathTimer, target.stat.deathDelay, WorldAgent.RemoveAgent.bind(target))
					agent.target = null
				Util.StartTimer(agent.combatTimer, Formulas.GetAttackSpeedSec(agent.stat), Combat.DealDamage.bind(agent, map))
	agent.isAttacking = canAttack

#
static func Update(agent : BaseAgent, map : World.Map):
	if agent and agent.combatTimer and agent.combatTimer.is_stopped():
		DealDamage(agent, map)
