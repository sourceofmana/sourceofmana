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

# Skill Flow
static func Cast(agent : BaseAgent, target : BaseAgent, skill : SkillData):
	if not SkillCommons.IsAlive(agent) or not SkillCommons.HasSkill(agent, skill) or SkillCommons.IsCoolingDown(agent, skill) or SkillCommons.IsCasting(agent, skill):
		return
	if skill._mode == TargetMode.SINGLE and (not target or not SkillCommons.IsAlive(target)):
		return

	if SkillCommons.SetConsume(agent, "mana", skill):
		Stopped(agent)
		agent.SetSkillCastName(skill._name)
		Callback.StartTimer(agent.actionTimer, skill._castTime + agent.stat.current.castAttackDelay, Skill.Attack.bind(agent, target, skill))
		if skill._mode == TargetMode.SINGLE:
			agent.currentOrientation = Vector2(target.position - agent.position).normalized()
		agent.UpdateChanged()

static func Attack(agent : BaseAgent, target : BaseAgent, skill : SkillData):
	if SkillCommons.IsAlive(agent) and SkillCommons.IsCasting(agent) and SkillCommons.HasSkill(agent, skill):
		var hasStamina : bool = SkillCommons.SetConsume(agent, "stamina", skill)

		match skill._mode:
			TargetMode.SINGLE:
				if not SkillCommons.IsAlive(target):
					Stopped(agent)
					return
				if SkillCommons.IsTargetable(agent, target, skill):
					var handle : Callable = Skill.Handle.bind(agent, target, skill, SkillCommons.GetRNG(hasStamina))
					if SkillCommons.IsDelayed(skill):
						Callback.SelfDestructTimer(agent, agent.stat.current.castAttackDelay, handle, "SKILL_" + skill._name)
						Delayed(agent, target, skill)
					else:
						handle.call()
					return
			TargetMode.ZONE:
				for zoneTarget in SkillCommons.GetSurroundingTargets(agent, skill):
					Handle(agent, zoneTarget, skill, SkillCommons.GetRNG(hasStamina))
				return
			TargetMode.SELF:
				Handle(agent, agent, skill, SkillCommons.GetRNG(hasStamina))
				return
		Missed(agent, target)

static func Handle(agent : BaseAgent, target : BaseAgent, skill : SkillData, rng : float):
	if skill._damage > 0:		Damaged(agent, target, skill, rng)
	if skill._heal > 0:			Healed(agent, target, skill, rng)
	Casted(agent, target, skill)

# Handling
static func Casted(agent : BaseAgent, target : BaseAgent, skill : SkillData):
	var callable : Callable = Skill.Cast.bind(agent, target, skill) if skill._repeat and SkillCommons.IsAlive(target) else Callable()
	agent.SetSkillCastName("")
	var timer : Timer = Callback.SelfDestructTimer(agent, agent.stat.current.cooldownAttackDelay + skill._cooldownTime, callable, skill._name + " CoolDown")
	agent.cooldownTimers[agent.currentSkillName] = timer

static func Damaged(agent : BaseAgent, target : BaseAgent, skill : SkillData, rng : float):
	var info : AlterationInfo = SkillCommons.GetDamage(agent, target, skill, rng)
	target.stat.health = max(target.stat.health - info.value, 0)
	Launcher.Network.Server.NotifyInstancePlayers(null, agent, "TargetAlteration", [target.get_rid().get_id(), info.value, info.type, skill._name])

	if target.aiTimer:
		target.AddAttacker(agent, info.value)
		AI.SetState(target, AI.State.ATTACK)

	if target.stat.health <= 0:
		Killed(agent, target)

static func Healed(agent : BaseAgent, target : BaseAgent, skill : SkillData, rng : float):
	var heal : int = SkillCommons.GetHeal(agent, target, skill, rng)
	target.stat.health = min(target.stat.health + heal, target.stat.current.maxHealth)
	Launcher.Network.Server.NotifyInstancePlayers(null, agent, "TargetAlteration", [target.get_rid().get_id(), heal, EntityCommons.Alteration.HEAL, skill._name])

static func Killed(agent : BaseAgent, target : BaseAgent):
	Formulas.ApplyXp(target)
	target.Killed(agent)
	Stopped(agent)

static func Stopped(agent : BaseAgent):
	if SkillCommons.HasActionInProgress(agent):
		agent.SetSkillCastName("")
		Callback.ClearTimer(agent.actionTimer)
		if agent.aiTimer:
			AI.SetState(agent, AI.State.IDLE)


static func Missed(agent : BaseAgent, target : BaseAgent):
	if target == null:
		return
	Launcher.Network.Server.NotifyInstancePlayers(null, agent, "TargetAlteration", [target.get_rid().get_id(), 0, EntityCommons.Alteration.MISS, ""])
	Stopped(agent)

static func Delayed(agent : BaseAgent, target : BaseAgent, skill : SkillData):
	Launcher.Network.Server.NotifyInstancePlayers(null, agent, "TargetAlteration", [target.get_rid().get_id(), 0, EntityCommons.Alteration.PROJECTILE, skill._name])
