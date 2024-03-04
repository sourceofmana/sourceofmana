extends Object
class_name ActorStats

# Active Stats
var level : int							= 1
var experience : int					= 0
var health : int						= 1
var mana : int							= 0
var stamina : int						= 0
var weight : float						= 0.0
var entityShape : String				= ""
var spiritShape : String				= ""
var morphed : bool						= false

# Personal Stats
var strength : int						= 0
var vitality : int						= 0
var agility : int						= 0
var endurance : int						= 0
var concentration : int					= 0

# Entity Stats
var base : BaseStats					= BaseStats.new()
var current : BaseStats					= BaseStats.new()

# Signals
signal active_stats_updated
signal personal_stats_updated
signal entity_stats_updated

#
func RefreshActiveStats():
	health					= Formula.ClampHealth(self)
	stamina					= Formula.ClampStamina(self)
	mana					= Formula.ClampMana(self)
	active_stats_updated.emit()

func RefreshRegenStats():
	current.regenHealth		= Formula.GetRegenHealth(self)
	current.regenMana		= Formula.GetRegenMana(self)
	current.regenStamina	= Formula.GetRegenStamina(self)

func RefreshEntityStats():
	# Current Stats
	current.maxHealth		= Formula.GetMaxHealth(self)
	current.maxMana			= Formula.GetMaxMana(self)
	current.maxStamina		= Formula.GetMaxStamina(self)
	current.attackStrength	= Formula.GetAttackStrength(self)
	current.attackRange		= Formula.GetAttackRange(self)
	current.critRate		= Formula.GetCritRate(self)
	current.castAttackDelay	= Formula.GetCastAttackDelay(self)
	current.cooldownAttackDelay = Formula.GetCooldownAttackDelay(self)
	current.walkSpeed		= Formula.GetWalkSpeed(self)
	current.weightCapacity	= Formula.GetWeightCapacity(self)
	entity_stats_updated.emit()

	RefreshActiveStats()
	RefreshRegenStats()

func RefreshPersonalStats():
	RefreshEntityStats()
	personal_stats_updated.emit()

#
func SetPersonalStats(personalStats : Dictionary):
	for modifier in personalStats:
		if modifier in self:
			self[modifier] = personalStats[modifier]
	RefreshPersonalStats()

func SetEntityStats(entityStats : Dictionary, isMorphed : bool):
	for modifier in entityStats:
		if modifier in base:
			base[modifier] = (base[modifier] + entityStats[modifier]) / 2 if isMorphed else entityStats[modifier]
	RefreshEntityStats()

#
func Init(data : EntityData):
	var stats : Dictionary = data._stats
	entityShape	= data._name

	if "Level" in stats:				level				= stats["Level"]
	if "Experience" in stats:			experience			= stats["Experience"]
	if "Weight" in stats:				weight				= stats["Weight"]
	if "Spirit" in stats:				spiritShape			= stats["Spirit"]

	SetPersonalStats(stats)
	SetEntityStats(stats, morphed)

	health		= stats["Health"]	if "Health" in stats	else current.maxHealth
	mana		= stats["Mana"]		if "Mana" in stats		else current.maxMana
	stamina		= stats["Stamina"]	if "Stamina" in stats	else current.maxStamina
	RefreshActiveStats()

func FillRandomPersonalStats():
	var maxPoints : int			= Formula.GetMaxPersonalPoints(self)
	var assignedPoints : int	= Formula.GetAssignedPersonalPoints(self)
	if maxPoints > assignedPoints:
		const stats = ["strength", "vitality", "agility", "endurance", "concentration"]
		var personalStats : Dictionary = {}
		var pointToDispatch : int = maxPoints - assignedPoints
		for modifier in stats:
			var r : int = randi_range(0, pointToDispatch)
			pointToDispatch -= r
			personalStats[modifier] = self[modifier] + r
			if pointToDispatch == 0:
				break
		SetPersonalStats(personalStats)

func Morph(data : EntityData):
	morphed = not morphed
	SetEntityStats(data._stats, morphed)

func AddPersonalStat(stat : ActorCommons.PersonalStat):
	if Formula.GetMaxPersonalPoints(self) - Formula.GetAssignedPersonalPoints(self) > 0:
		match stat:
			ActorCommons.PersonalStat.STRENGTH:
				strength = min(ActorCommons.MaxPointPerPersonalStat, strength + 1)
			ActorCommons.PersonalStat.VITALITY:
				vitality = min(ActorCommons.MaxPointPerPersonalStat, vitality + 1)
			ActorCommons.PersonalStat.AGILITY:
				agility = min(ActorCommons.MaxPointPerPersonalStat, agility + 1)
			ActorCommons.PersonalStat.ENDURANCE:
				endurance = min(ActorCommons.MaxPointPerPersonalStat, endurance + 1)
			ActorCommons.PersonalStat.CONCENTRATION:
				concentration = min(ActorCommons.MaxPointPerPersonalStat, concentration + 1)

static func Regen(agent : BaseAgent):
	if SkillCommons.IsAlive(agent):
		if agent.stat.health < agent.stat.current.maxHealth:
			SetHealth(agent, Modifier.GetRegenHealth(agent))
		if agent.stat.mana < agent.stat.current.maxMana:
			SetMana(agent, Modifier.GetRegenMana(agent))
		if agent.stat.stamina < agent.stat.current.maxStamina:
			SetStamina(agent, Modifier.GetRegenStamina(agent))

	Callback.LoopTimer(agent.regenTimer, ActorCommons.RegenDelay)

static func SetHealth(agent : BaseAgent, bonus : int):
	agent.stat.health = clampi(agent.stat.health + bonus, 0, agent.stat.current.maxHealth)

static func SetMana(agent : BaseAgent, bonus : int):
	agent.stat.mana = clampi(agent.stat.mana + bonus, 0, agent.stat.current.maxMana)

static func SetStamina(agent : BaseAgent, bonus : int):
	agent.stat.stamina = clampi(agent.stat.stamina + bonus, 0, agent.stat.current.maxStamina)

static func AddExperience(agent : BaseAgent, bonus : int):
	agent.stat.experience += bonus
	# Manage level up
	var levelUpHappened = false
	var experiencelNeeded = Experience.GetNeededExperienceForNextLevel(agent.stat.level)
	while experiencelNeeded != Experience.MAX_LEVEL_REACHED and agent.stat.experience >= experiencelNeeded:
		agent.stat.experience -= experiencelNeeded
		agent.stat.level += 1
		levelUpHappened = true
		experiencelNeeded = Experience.GetNeededExperienceForNextLevel(agent.stat.level)
	if levelUpHappened:
		# Network notify of level up
		Launcher.Network.Server.NotifyInstance(agent, "TargetLevelUp", [])
