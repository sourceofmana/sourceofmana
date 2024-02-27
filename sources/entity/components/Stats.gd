extends Object
class_name EntityStats


# Active Stats
var level : int							= 1
var experience : float					= 0
var health : int						= 1
var mana : int							= 0
var stamina : int						= 0
var weight : float						= 0.0
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

# WIP: Unsync
var entityShape : String				= ""
var spiritShape : String				= ""

# Signals
signal active_stats_updated
signal personal_stats_updated
signal entity_stats_updated

#
func RefreshActiveStats():
	health					= Formulas.ClampHealth(self)
	stamina					= Formulas.ClampStamina(self)
	mana					= Formulas.ClampMana(self)
	active_stats_updated.emit()

func RefreshEntityStats():
	# Current Stats
	current.maxHealth		= Formulas.GetMaxHealth(self)
	current.maxMana			= Formulas.GetMaxMana(self)
	current.maxStamina		= Formulas.GetMaxStamina(self)
	current.attackStrength	= Formulas.GetAttackStrength(self)
	current.attackRange		= Formulas.GetAttackRange(self)
	current.critRate		= Formulas.GetCritRate(self)
	current.castAttackDelay	= Formulas.GetCastAttackDelay(self)
	current.cooldownAttackDelay = Formulas.GetCooldownAttackDelay(self)
	current.walkSpeed		= Formulas.GetWalkSpeed(self)
	current.weightCapacity	= Formulas.GetWeightCapacity(self)
	entity_stats_updated.emit()

	RefreshActiveStats()

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
	var maxPoints : int			= Formulas.GetMaxPersonalPoints(self)
	var assignedPoints : int	= Formulas.GetAssignedPersonalPoints(self)
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

func AddPersonalStat(stat : EntityCommons.PersonalStat):
	if Formulas.GetMaxPersonalPoints(self) - Formulas.GetAssignedPersonalPoints(self) > 0:
		match stat:
			EntityCommons.PersonalStat.STRENGTH:
				strength = min(EntityCommons.MaxPointPerPersonalStat, strength + 1)
			EntityCommons.PersonalStat.VITALITY:
				vitality = min(EntityCommons.MaxPointPerPersonalStat, vitality + 1)
			EntityCommons.PersonalStat.AGILITY:
				agility = min(EntityCommons.MaxPointPerPersonalStat, agility + 1)
			EntityCommons.PersonalStat.ENDURANCE:
				endurance = min(EntityCommons.MaxPointPerPersonalStat, endurance + 1)
			EntityCommons.PersonalStat.CONCENTRATION:
				concentration = min(EntityCommons.MaxPointPerPersonalStat, concentration + 1)

static func Regen(agent : BaseAgent):
	if SkillCommons.IsAlive(agent):
		if agent.stat.health < agent.stat.current.maxHealth:
			agent.stat.health  = min(agent.stat.health + Formulas.GetRegenHealth(agent), agent.stat.current.maxHealth)
		if agent.stat.mana < agent.stat.current.maxMana:
			agent.stat.mana  = min(agent.stat.mana + Formulas.GetRegenMana(agent), agent.stat.current.maxMana)
		if agent.stat.stamina < agent.stat.current.maxStamina:
			agent.stat.stamina  = min(agent.stat.stamina + Formulas.GetRegenStamina(agent), agent.stat.current.maxStamina)
	Callback.LoopTimer(agent.regenTimer, EntityCommons.RegenDelay)

static func AddExperience(agent : BaseAgent, points : float):
	agent.stat.experience += points
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
