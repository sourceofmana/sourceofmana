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
var actor : Actor						= null

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
func Init(actorNode : Actor, data : EntityData):
	Util.Assert(actorNode != null, "Caller actor node should never be null")
	actor = actorNode

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
		RefreshPersonalStats()

func Regen():
	if SkillCommons.IsAlive(actor):
		if actor.stat.health < actor.stat.current.maxHealth:
			SetHealth(Formula.GetRegenHealth(self))
		if actor.stat.mana < actor.stat.current.maxMana:
			SetMana(Formula.GetRegenMana(self))
		if actor.stat.stamina < actor.stat.current.maxStamina:
			SetStamina(Formula.GetRegenStamina(self))

	Callback.LoopTimer(actor.regenTimer, ActorCommons.RegenDelay)

func SetHealth(bonus : int):
	health = clampi(health + bonus, 0, current.maxHealth)
	if health <= 0:
		actor.Killed()

func SetMana(bonus : int):
	mana = clampi(mana + bonus, 0, current.maxMana)

func SetStamina(bonus : int):
	stamina = clampi(stamina + bonus, 0, current.maxStamina)

func AddExperience(bonus : int):
	experience += bonus
	# Manage level up
	var levelUpHappened = false
	var experiencelNeeded = Experience.GetNeededExperienceForNextLevel(level)
	while experiencelNeeded != Experience.MAX_LEVEL_REACHED and experience >= experiencelNeeded:
		experience -= experiencelNeeded
		level += 1
		levelUpHappened = true
		experiencelNeeded = Experience.GetNeededExperienceForNextLevel(level)
	if levelUpHappened and Launcher.Network.Server:
		Launcher.Network.Server.NotifyInstance(actor, "TargetLevelUp", [])
