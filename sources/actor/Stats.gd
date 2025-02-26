extends Object
class_name ActorStats

# Public and private stats, can be initialized through a dictionary from a SQL query or entities.json
var level : int							= 1
var experience : int					= 0
var gp : int							= 0
var health : int						= ActorCommons.MaxStatValue
var mana : int							= ActorCommons.MaxStatValue
var stamina : int						= ActorCommons.MaxStatValue
var karma : int							= 0
var weight : float						= 0.0
var hairstyle : int						= DB.UnknownHash
var haircolor : int						= DB.UnknownHash
var gender : int						= ActorCommons.Gender.MALE
var race : int							= DB.UnknownHash
var skintone : int						= DB.UnknownHash
var shape : String						= ""
var spirit : String						= ""
var currentShape : String				= ""
var baseExp : int						= 1
# Attributes
var strength : int						= 0
var vitality : int						= 0
var agility : int						= 0
var endurance : int						= 0
var concentration : int					= 0

# Entity Stats
var entityStat : BaseStats				= BaseStats.new()
var morphStat : BaseStats				= BaseStats.new()
var current : BaseStats					= BaseStats.new()
var actor : Actor						= null
var modifiers : CellModifier			= CellModifier.new()

# Signals
signal vital_stats_updated
signal attributes_updated
signal entity_stats_updated

#
func RefreshVitalStats():
	health					= Formula.ClampHealth(self)
	stamina					= Formula.ClampStamina(self)
	mana					= Formula.ClampMana(self)
	vital_stats_updated.emit()

func RefreshRegenStats():
	current.regenHealth		= Formula.GetRegenHealth(self)
	current.regenMana		= Formula.GetRegenMana(self)
	current.regenStamina	= Formula.GetRegenStamina(self)

func RefreshEntityStats():
	# Current Stats
	current.maxHealth		= Formula.GetMaxHealth(self)
	current.maxMana			= Formula.GetMaxMana(self)
	current.maxStamina		= Formula.GetMaxStamina(self)
	current.attack			= Formula.GetAttack(self)
	current.attackRange		= Formula.GetAttackRange(self)
	current.mattack			= Formula.GetMAttack(self)
	current.defense			= Formula.GetDefense(self)
	current.mdefense		= Formula.GetMDefense(self)
	current.critRate		= Formula.GetCritRate(self)
	current.dodgeRate		= Formula.GetDodgeRate(self)
	current.castAttackDelay	= Formula.GetCastAttackDelay(self)
	current.cooldownAttackDelay = Formula.GetCooldownAttackDelay(self)
	current.walkSpeed		= Formula.GetWalkSpeed(self)
	current.weightCapacity	= Formula.GetWeightCapacity(self)
	entity_stats_updated.emit()

	RefreshVitalStats()
	RefreshRegenStats()

func RefreshAttributes():
	RefreshEntityStats()
	attributes_updated.emit()

#
func SetStats(stats : Dictionary):
	for statName in stats:
		if stats[statName] != null and statName in self:
			self[statName] = stats[statName]

	if actor.type == ActorCommons.Type.MONSTER:
		FillRandomAttributes()
	RefreshAttributes()

#
func SetEntityStats(newStats : Dictionary):
	for modifier in newStats:
		if modifier in entityStat:
			entityStat[modifier] = newStats[modifier]
			morphStat[modifier] = entityStat[modifier]
	RefreshEntityStats()

func SetMorphStats(newStats : Dictionary):
	for modifier in newStats:
		if modifier in morphStat:
			morphStat[modifier] = (entityStat[modifier] + newStats[modifier]) / 2 if IsMorph() else newStats[modifier]
	RefreshEntityStats()

#
func Init(actorNode : Actor, data : EntityData):
	assert(actorNode != null, "Caller actor node should never be null")
	actor = actorNode

	var stats : Dictionary = data._stats
	shape	= data._name
	currentShape = shape

	SetStats(stats)
	SetEntityStats(stats)
	RefreshVitalStats()

func FillRandomAttributes():
	var maxPoints : int			= Formula.GetMaxAttributePoints(level)
	var assignedPoints : int	= Formula.GetAssignedAttributePoints(self)
	if maxPoints > assignedPoints:
		const attributeNames = ["strength", "vitality", "agility", "endurance", "concentration"]
		var attributes : Dictionary = {}
		var pointToDispatch : int = maxPoints - assignedPoints
		for att in attributeNames:
			var points : int = randi_range(0, pointToDispatch)
			pointToDispatch -= points
			attributes[att] = self[att] + points
			if pointToDispatch == 0:
				break
		SetStats(attributes)

func Morph(data : EntityData):
	currentShape = data._name
	SetMorphStats(data._stats)

func IsMorph() -> bool:
	return currentShape != shape

func IsSailing() -> bool:
	return currentShape == "Ship"

func AddAttribute(attribute : ActorCommons.Attribute):
	if Formula.GetMaxAttributePoints(level) - Formula.GetAssignedAttributePoints(self) > 0:
		match attribute:
			ActorCommons.Attribute.STRENGTH:
				strength = min(ActorCommons.MaxPointPerAttributes, strength + 1)
			ActorCommons.Attribute.VITALITY:
				vitality = min(ActorCommons.MaxPointPerAttributes, vitality + 1)
			ActorCommons.Attribute.AGILITY:
				agility = min(ActorCommons.MaxPointPerAttributes, agility + 1)
			ActorCommons.Attribute.ENDURANCE:
				endurance = min(ActorCommons.MaxPointPerAttributes, endurance + 1)
			ActorCommons.Attribute.CONCENTRATION:
				concentration = min(ActorCommons.MaxPointPerAttributes, concentration + 1)
		RefreshAttributes()

func Regen():
	if ActorCommons.IsAlive(actor):
		var bonus : float = 1.0
		if ActorCommons.IsSitting(actor):
			bonus *= 2.0
		RefreshRegenStats()
		if actor.stat.health < actor.stat.current.maxHealth:
			SetHealth(floori(current.regenHealth * bonus))
		if actor.stat.mana < actor.stat.current.maxMana:
			SetMana(floori(current.regenMana * bonus))
		if not ActorCommons.IsAttacking(actor) and actor.stat.stamina < actor.stat.current.maxStamina:
			SetStamina(floori(current.regenStamina * bonus))

	Callback.LoopTimer(actor.regenTimer, ActorCommons.RegenDelay)

func SetHealth(bonus : int):
	health = clampi(health + bonus, 0, current.maxHealth)
	if health <= 0:
		actor.Killed()

func SetMana(bonus : int):
	mana = clampi(mana + bonus, 0, current.maxMana)

func SetStamina(bonus : int):
	stamina = clampi(stamina + bonus, 0, current.maxStamina)

func AddExperience(value : int):
	if not ActorCommons.IsAlive(actor) or value <= 0:
		return
	experience += value
	# Manage level up
	var experiencelNeeded = Experience.GetNeededExperienceForNextLevel(level)
	while experiencelNeeded != Experience.MAX_LEVEL_REACHED and experience >= experiencelNeeded:
		experience -= experiencelNeeded
		level += 1
		experiencelNeeded = Experience.GetNeededExperienceForNextLevel(level)

func AddGP(value : int):
	if not ActorCommons.IsAlive(actor) or value <= 0:
		return
	gp += value
