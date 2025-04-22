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

	if SkillCommons.TryConsume(agent, CellCommons.Modifier.Mana, skill):
		Stopped(agent)
		agent.SetSkillCastID(skill.id)
		Callback.StartTimer(agent.actionTimer, skill.castTime + agent.stat.current.castAttackDelay, Skill.Attack.bind(agent, target, skill), true)
		if skill.mode == TargetMode.SINGLE:
			agent.LookAt(target)

static func Attack(agent : BaseAgent, target : BaseAgent, skill : SkillCell):
	if ActorCommons.IsAlive(agent) and SkillCommons.IsCasting(agent) and SkillCommons.HasSkill(agent, skill):
		var hasStamina : bool = SkillCommons.TryConsume(agent, CellCommons.Modifier.Stamina, skill)

		match skill.mode:
			TargetMode.SINGLE:
				if not ActorCommons.IsAlive(target):
					Stopped(agent)
					return
				if SkillCommons.IsAttackable(agent, target, skill):
					var handle : Callable = Skill.Handle.bind(agent, target, skill, SkillCommons.GetRNG(hasStamina))
					if SkillCommons.IsDelayed(skill):
						Callback.SelfDestructTimer(agent, agent.stat.current.castAttackDelay, handle)
						ThrowProjectile(agent, target.position, skill)
					else:
						handle.call()
					Casted(agent, target, skill)
					return
				if SkillCommons.IsInteractable(agent, target):
					ThrowProjectile(agent, agent.position + agent.currentOrientation * Vector2(skill.cellRange, skill.cellRange), skill)
			TargetMode.ZONE:
				var handle : Callable = Skill.HandleZone.bind(agent, agent.get_position(), skill, SkillCommons.GetRNG(hasStamina))
				if SkillCommons.IsDelayed(skill):
					Callback.SelfDestructTimer(agent, agent.stat.current.castAttackDelay, handle)
					ThrowProjectile(agent, agent.position, skill)
				else:
					handle.call()
				Casted(agent, agent, skill)
				return
			TargetMode.SELF:
				Handle(agent, agent, skill, SkillCommons.GetRNG(hasStamina))
				Casted(agent, agent, skill)
				return
		Missed(agent, target)

static func HandleZone(agent : BaseAgent, zonePos : Vector2, skill : SkillCell, rng : float):
	var targets : Array[BaseAgent] = SkillCommons.GetZoneTargets(WorldAgent.GetInstanceFromAgent(agent), zonePos, skill)
	if targets.is_empty():
		return
	var halfRNG : float = rng / 2.0
	var scaledRNG : float = halfRNG + halfRNG / targets.size()
	for target in targets:
		Handle(agent, target, skill, scaledRNG)

static func Handle(agent : BaseAgent, target : BaseAgent, skill : SkillCell, rng : float):
	if skill.modifiers.Get(CellCommons.Modifier.Attack) != 0 or skill.modifiers.Get(CellCommons.Modifier.MAttack) != 0:
		Damaged(agent, target, skill, rng)
	if skill.modifiers.Get(CellCommons.Modifier.Health) != 0:
		Healed(agent, target, skill, rng)

# Handling
static func Casted(agent : BaseAgent, target : BaseAgent, skill : SkillCell):
	agent.cooldownTimers[skill.id] = true
	agent.SetSkillCastID(DB.UnknownHash)
	var timeLeft : float = SkillCommons.GetCooldown(agent, skill)
	Callback.SelfDestructTimer(agent, timeLeft, CooledDown, [agent, target, skill], skill.name + " CoolDown")
	Network.NotifyNeighbours(agent, "Casted", [skill.id, timeLeft])

static func CooledDown(agent : BaseAgent, target : BaseAgent, skill : SkillCell):
	agent.cooldownTimers[skill.id] = false
	if skill.repeat and ActorCommons.IsAlive(target):
		Skill.Cast(agent, target, skill)

static func Damaged(agent : BaseAgent, target : BaseAgent, skill : SkillCell, rng : float):
	var info : AlterationInfo = SkillCommons.GetDamage(agent, target, skill, rng)
	if target is AIAgent:
		target.AddAttacker(agent, info.value)
		AI.Refresh(target)
	target.stat.SetHealth(-info.value)
	Network.NotifyNeighbours(agent, "TargetAlteration", [target.get_rid().get_id(), info.value, info.type, skill.id], true, true)

static func Healed(agent : BaseAgent, target : BaseAgent, skill : SkillCell, rng : float):
	var heal : int = SkillCommons.GetHeal(agent, target, skill, rng)
	target.stat.SetHealth(heal)
	Network.NotifyNeighbours(agent, "TargetAlteration", [target.get_rid().get_id(), heal, ActorCommons.Alteration.HEAL, skill.id], true, true)

static func Stopped(agent : BaseAgent):
	if SkillCommons.HasActionInProgress(agent):
		agent.SetSkillCastID(DB.UnknownHash)
		Callback.ClearTimer(agent.actionTimer)
		if agent is AIAgent:
			AI.Refresh(agent)

static func Missed(agent : BaseAgent, target : BaseAgent):
	if target == null:
		return
	Network.NotifyNeighbours(agent, "TargetAlteration", [target.get_rid().get_id(), 0, ActorCommons.Alteration.MISS, DB.UnknownHash], true, true)
	Stopped(agent)

static func ThrowProjectile(agent : BaseAgent, targetPos : Vector2, skill : SkillCell):
	Network.NotifyNeighbours(agent, "ThrowProjectile", [targetPos, skill.id])
