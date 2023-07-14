extends Object
class_name EntityStats

# Player Vars
var level : int							= 1
var experience : float					= 0.0
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
var base : BaseStats					= BaseStats.new()
var current : BaseStats					= BaseStats.new()

# Constants to move to Conf
var deathDelay : int					= 10

#
func RefreshStats():
	# Current Stats
	current.health			= Formulas.GetMaxHealth(self)
	current.mana			= Formulas.GetMaxMana(self)
	current.stamina			= Formulas.GetMaxStamina(self)
	current.attackStrength	= Formulas.GetAttackStrength(self)
	current.attackSpeed		= Formulas.GetAttackSpeed(self)
	current.attackRange		= Formulas.GetAttackRange(self)
	current.walkSpeed		= Formulas.GetWalkSpeed(self)
	current.weightCapacity	= Formulas.GetWeightCapacity(self)

	# Active Stats
	health					= Formulas.ClampHealth(self)
	stamina					= Formulas.ClampStamina(self)
	mana					= Formulas.ClampMana(self)

func SetEntityStats(stats : Dictionary):
	if "Health" in stats:				base.health			= stats["Health"]
	if "Mana" in stats:					base.mana			= stats["Mana"]
	if "Stamina" in stats:				base.stamina		= stats["Stamina"]
	if "AttackStrength" in stats:		base.attackStrength	= stats["AttackStrength"]
	if "AttackSpeed" in stats:			base.attackSpeed	= stats["AttackSpeed"]
	if "AttackRange" in stats:			base.attackRange	= stats["AttackRange"]
	if "WalkSpeed" in stats:			base.walkSpeed		= stats["WalkSpeed"]
	if "WeightCapacity" in stats:		base.weightCapacity	= stats["WeightCapacity"]
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
	entityShape = data._name

	if "Level" in stats:				level				= stats["Level"]
	if "Experience" in stats:			experience			= stats["Experience"]
	if "Health" in stats:				health				= stats["Health"]
	if "Mana" in stats:					mana				= stats["Mana"] 
	if "Stamina" in stats:				stamina				= stats["Stamina"] 
	if "Weight" in stats:				weight				= stats["Weight"]
	if "Spirit" in stats:				spiritShape			= stats["Spirit"]
	SetPersonalStats(stats)
	SetEntityStats(stats)

func Morph(data : EntityData):
	SetPersonalStats(data._stats)
	morphed = not morphed
