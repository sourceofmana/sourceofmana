extends Object
class_name Skill

#
class AlterationInfo:
	var value : int						= 0
	var type : ActorCommons.Alteration	= ActorCommons.Alteration.MISS

enum TargetMode
{
	SINGLE = 0,
	ZONE,
	SELF,
}

# Skill Flow
static func Cast(agent : BaseAgent, target : BaseAgent, skill : SkillCell):
	if not ActorCommons.IsAlive(agent) or not SkillCommons.HasSkill(agent, skill) or SkillCommons.IsCoolingDown(agent, skill) or SkillCommons.IsCasting(agent, skill):
		return
	if skill.mode == TargetMode.SINGLE and (not target or not ActorCommons.IsAlive(target)):
		return
	var map : WorldMap = WorldAgent.GetMapFromAgent(agent)
	if map and map.HasFlags(WorldMap.Flags.NO_SPELL):
		return

	if SkillCommons.TryConsume(agent, SkillCommons.ConsomeType.MANA, skill):
		Stopped(agent)
		agent.SetSkillCastID(skill.id)
		Callback.StartTimer(agent.actionTimer, skill.castTime + agent.stat.current.castAttackDelay, Skill.Attack.bind(agent, target, skill), true)
		if skill.mode == TargetMode.SINGLE:
			agent.LookAt(target)
		agent.UpdateChanged()

static func Attack(agent : BaseAgent, target : BaseAgent, skill : SkillCell):
	if ActorCommons.IsAlive(agent) and SkillCommons.IsCasting(agent) and SkillCommons.HasSkill(agent, skill):
		var hasStamina : bool = SkillCommons.TryConsume(agent, SkillCommons.ConsomeType.STAMINA, skill)

		match skill.mode:
			TargetMode.SINGLE:
				if not ActorCommons.IsAlive(target):
					Stopped(agent)
					return
				if SkillCommons.IsTargetable(agent, target, skill):
					var handle : Callable = Skill.Handle.bind(agent, target, skill, SkillCommons.GetRNG(hasStamina))
					if SkillCommons.IsDelayed(skill):
						Callback.SelfDestructTimer(agent, agent.stat.current.castAttackDelay, handle)
						Delayed(agent, target, skill)
					else:
						handle.call()
					Casted(agent, target, skill)
					return
			TargetMode.ZONE:
				for zoneTarget in SkillCommons.GetSurroundingTargets(agent, skill):
					Handle(agent, zoneTarget, skill, SkillCommons.GetRNG(hasStamina))
				Casted(agent, agent, skill)
				return
			TargetMode.SELF:
				Handle(agent, agent, skill, SkillCommons.GetRNG(hasStamina))
				Casted(agent, agent, skill)
				return
		Missed(agent, target)

static func Handle(agent : BaseAgent, target : BaseAgent, skill : SkillCell, rng : float):
	if skill.effects.has(CellCommons.effectDamage):		Damaged(agent, target, skill, rng)
	if skill.effects.has(CellCommons.effectHP):			Healed(agent, target, skill, rng)

# Handling
static func Casted(agent : BaseAgent, target : BaseAgent, skill : SkillCell):
	var callable : Callable = Callable()
	var args : Array = []
	if skill.repeat and ActorCommons.IsAlive(target):
		callable = Skill.Cast
		args = [agent, target, skill]

	agent.SetSkillCastID(DB.UnknownHash)
	var timer : Timer = Callback.SelfDestructTimer(agent, SkillCommons.GetCooldown(agent, skill), callable, args, skill.name + " CoolDown")
	agent.cooldownTimers[skill.name] = timer
	Network.Server.NotifyNeighbours(agent, "Casted", [skill.id, timer.time_left])

static func Damaged(agent : BaseAgent, target : BaseAgent, skill : SkillCell, rng : float):
	var info : AlterationInfo = SkillCommons.GetDamage(agent, target, skill, rng)
	if target is AIAgent:
		target.AddAttacker(agent, info.value)
		AI.Refresh(target)
	target.stat.SetHealth(-info.value)
	Network.Server.NotifyNeighbours(agent, "TargetAlteration", [target.get_rid().get_id(), info.value, info.type, skill.id])

static func Healed(agent : BaseAgent, target : BaseAgent, skill : SkillCell, rng : float):
	var heal : int = SkillCommons.GetHeal(agent, target, skill, rng)
	target.stat.SetHealth(heal)
	Network.Server.NotifyNeighbours(agent, "TargetAlteration", [target.get_rid().get_id(), heal, ActorCommons.Alteration.HEAL, skill.id])

static func Stopped(agent : BaseAgent):
	if SkillCommons.HasActionInProgress(agent):
		agent.SetSkillCastID(DB.UnknownHash)
		Callback.ClearTimer(agent.actionTimer)
		if agent is AIAgent:
			AI.Refresh(agent)

static func Missed(agent : BaseAgent, target : BaseAgent):
	if target == null:
		return
	Network.Server.NotifyNeighbours(agent, "TargetAlteration", [target.get_rid().get_id(), 0, ActorCommons.Alteration.MISS, DB.UnknownHash])
	Stopped(agent)

static func Delayed(agent : BaseAgent, target : BaseAgent, skill : SkillCell):
	Network.Server.NotifyNeighbours(agent, "TargetAlteration", [target.get_rid().get_id(), 0, ActorCommons.Alteration.PROJECTILE, skill.id])
