extends Object
class_name ActorStats

# Active Stats
var level : int							= 1
var experience : int					= 0
var gp : int							= 0
var health : int						= 1
var mana : int							= 0
var stamina : int						= 0
var karma : int							= 0
var weight : float						= 0.0
var hairstyle : int						= 0
var haircolor : int						= 0
var gender : int						= ActorCommons.Gender.MALE
var race : int							= 0
var skin : int							= 0
var entityShape : String				= ""
var spiritShape : String				= ""
var currentShape : String				= ""

# Inactive Stats
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

# Signals
signal active_stats_updated
signal attributes_updated
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
	current.attack			= Formula.GetAttack(self)
	current.attackRange		= Formula.GetAttackRange(self)
	current.defense			= Formula.GetDefense(self)
	current.critRate		= Formula.GetCritRate(self)
	current.dodgeRate		= Formula.GetDodgeRate(self)
	current.castAttackDelay	= Formula.GetCastAttackDelay(self)
	current.cooldownAttackDelay = Formula.GetCooldownAttackDelay(self)
	current.walkSpeed		= Formula.GetWalkSpeed(self)
	current.weightCapacity	= Formula.GetWeightCapacity(self)
	entity_stats_updated.emit()

	RefreshActiveStats()
	RefreshRegenStats()

func RefreshAttributes():
	RefreshEntityStats()
	attributes_updated.emit()

#
func SetAttributes(attributes : Dictionary):
	for attribute in attributes:
		if attribute in self:
			self[attribute] = attributes[attribute]
	if actor.type == ActorCommons.Type.MONSTER:
		FillRandomAttributes()
	RefreshAttributes()

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
	entityShape	= data._name
	currentShape = entityShape

	if "Level" in stats:				level				= stats["Level"]
	if "Experience" in stats:			experience			= stats["Experience"]
	if "GP" in stats:					gp					= stats["GP"]
	if "Spirit" in stats:				spiritShape			= stats["Spirit"]
	if "BaseExp" in stats:				baseExp				= stats["BaseExp"]

	SetAttributes(stats)
	SetEntityStats(stats)

	health		= stats["Health"]	if "Health" in stats	else current.maxHealth
	mana		= stats["Mana"]		if "Mana" in stats		else current.maxMana
	stamina		= stats["Stamina"]	if "Stamina" in stats	else current.maxStamina
	RefreshActiveStats()

func FillRandomAttributes():
	var maxPoints : int			= Formula.GetMaxAttributePoints(self)
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
		SetAttributes(attributes)

func Morph(data : EntityData):
	currentShape = data._name
	SetMorphStats(data._stats)

func IsMorph() -> bool:
	return currentShape != entityShape

func IsSailing() -> bool:
	return currentShape == "Ship"

func AddAttribute(attribute : ActorCommons.Attribute):
	if Formula.GetMaxAttributePoints(self) - Formula.GetAssignedAttributePoints(self) > 0:
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
	var levelUpHappened = false
	var experiencelNeeded = Experience.GetNeededExperienceForNextLevel(level)
	while experiencelNeeded != Experience.MAX_LEVEL_REACHED and experience >= experiencelNeeded:
		experience -= experiencelNeeded
		level += 1
		levelUpHappened = true
		experiencelNeeded = Experience.GetNeededExperienceForNextLevel(level)
	if levelUpHappened and Launcher.Network.Server:
		Launcher.Network.Server.NotifyNeighbours(actor, "TargetLevelUp", [])

func AddGP(value : int):
	if not ActorCommons.IsAlive(actor) or value <= 0:
		return
	gp += value
