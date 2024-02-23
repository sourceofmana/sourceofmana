extends Object
class_name EntityStats

# General Vars
var level : int							= 1
var experience : float					= 0

# Shapes
var entityShape : String				= ""
var spiritShape : String				= ""

# Active Stats
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

# Formula Stats
var base : BaseStats					= BaseStats.new()
var current : BaseStats					= BaseStats.new()

# Animation Ratios
var walkRatio : float					= 1.0
var attackRatio : float					= 1.0

# Signals
signal ratio_updated
signal health_updated

#
func RefreshStats():
	# Current Stats
	current.maxHealth		= Formulas.GetMaxHealth(self)
	current.maxMana			= Formulas.GetMaxMana(self)
	current.maxStamina		= Formulas.GetMaxStamina(self)
	current.attackStrength	= Formulas.GetAttackStrength(self)
	current.attackSpeed		= Formulas.GetAttackSpeed(self)
	current.attackRange		= Formulas.GetAttackRange(self)
	current.critRate		= Formulas.GetCritRate(self)
	current.castAttackDelay	= Formulas.GetCastAttackDelay(self)
	current.cooldownAttackDelay = Formulas.GetCooldownAttackDelay(self)
	current.walkSpeed		= Formulas.GetWalkSpeed(self)
	current.weightCapacity	= Formulas.GetWeightCapacity(self)

	ClampStats()
	RefreshAnimation()

func RefreshAnimation():
	walkRatio				= Formulas.GetWalkRatio(self)
	attackRatio				= Formulas.GetAttackRatio(self)
	ratio_updated.emit()

func ClampStats():
	# Active Stats
	health					= Formulas.ClampHealth(self)
	stamina					= Formulas.ClampStamina(self)
	mana					= Formulas.ClampMana(self)
	health_updated.emit()

func SetEntityStats(stats : Dictionary, isMorphed : bool):
	for modifier in stats:
		if modifier in base:
			base[modifier] = (base[modifier] + stats[modifier]) / 2 if isMorphed else stats[modifier]
	RefreshStats()

func SetPersonalStats(personalStats : Dictionary):
	for modifier in personalStats:
		if modifier in self:
			self[modifier] = personalStats[modifier]
	RefreshStats()

func FillRandomPersonalStats():
	var maxPoints : int			= Formulas.GetMaxPersonalPoints(self)
	var assignedPoints : int	= Formulas.GetAssignedPersonalPoints(self)
	if maxPoints > assignedPoints:
		var pointToDispatch : int = maxPoints - assignedPoints
		var stats = ["strength", "vitality", "agility", "endurance", "concentration"]
		for modifier in stats:
			var r : int = randi_range(0, pointToDispatch)
			pointToDispatch -= r
			self[modifier] += r
			if pointToDispatch == 0:
				break
	RefreshStats()
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
	ClampStats()

func Morph(data : EntityData):
	morphed = not morphed
	SetEntityStats(data._stats, morphed)

static func Regen(agent : BaseAgent):
	if SkillCommons.IsAlive(agent):
		if agent.stat.health < agent.stat.current.maxHealth:
			agent.stat.health  = min(agent.stat.health + Formulas.GetRegenHealth(agent), agent.stat.current.maxHealth)
		if agent.stat.mana < agent.stat.current.maxMana:
			agent.stat.mana  = min(agent.stat.mana + Formulas.GetRegenMana(agent), agent.stat.current.maxMana)
		if agent.stat.stamina < agent.stat.current.maxStamina:
			agent.stat.stamina  = min(agent.stat.stamina + Formulas.GetRegenStamina(agent), agent.stat.current.maxStamina)
	Callback.LoopTimer(agent.regenTimer, EntityCommons.RegenDelay)

static func AddExperience(agent: BaseAgent, points: float):
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
