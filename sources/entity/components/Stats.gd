extends Object
class_name EntityStats

# Player Vars
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
var strength : int						= 1
var vitality : int						= 1
var agility : int						= 1
var endurance : int						= 1
var concentration : int					= 1

# Formula Stats
var base : BaseStats					= null
var current : BaseStats					= null

# Animation Ratios
var walkRatio : float					= 1.0
var attackRatio : float					= 1.0

# Constants to move to Conf
var deathDelay : int					= 10

# Signals
signal ratio_updated

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

func SetEntityStats(stats : Dictionary, isMorphed : bool):
	for modifier in stats:
		if modifier in base:
			base[modifier] = (base[modifier] + stats[modifier]) / 2 if isMorphed else stats[modifier]
	RefreshStats()

func SetPersonalStats(stats : Dictionary):
	if "Strength" in stats:				strength			= stats["Strength"] 
	if "Vitality" in stats:				vitality			= stats["Vitality"] 
	if "Agility" in stats:				agility				= stats["Agility"] 
	if "Endurance" in stats:			endurance			= stats["Endurance"]
	if "Concentration" in stats:		concentration		= stats["Concentration"]
	RefreshStats()

#
func Init(data : EntityData):
	var stats : Dictionary = data._stats

	base		= BaseStats.new()
	current		= BaseStats.new()
	entityShape	= data._name

	if "Level" in stats:				level				= stats["Level"]
	if "Experience" in stats:			experience			= stats["Experience"]
	if "Weight" in stats:				weight				= stats["Weight"]
	if "spirit" in stats:				spiritShape			= stats["spirit"]

	SetPersonalStats(stats)
	SetEntityStats(stats, morphed)

	health		= stats["Health"]	if "Health" in stats	else current.maxHealth
	mana		= stats["Mana"]		if "Mana" in stats		else current.maxMana
	stamina		= stats["Stamina"]	if "Stamina" in stats	else current.maxStamina
	ClampStats()

func Morph(data : EntityData):
	morphed = not morphed
	SetEntityStats(data._stats, morphed)

func UpdatePlayerVars(networkRID : int):
	Launcher.Network.UpdatePlayerVars(level, experience, networkRID)

func UpdateActiveStats(networkRID : int):
	Launcher.Network.UpdateActiveStats(health, mana, stamina, weight, morphed, networkRID)

func UpdatePersonalStats(networkRID : int):
	Launcher.Network.UpdatePersonalStats(strength, vitality, agility, endurance, concentration, networkRID)

#region Level and Experience

static func addExperience(agent: BaseAgent, points: float):
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
		Launcher.Network.Server.NotifyInstancePlayers(null, agent, "TargetLevelUp", [])

#endregion
