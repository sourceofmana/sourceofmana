extends WindowPanel

@onready var lName : Label						= $Margin/Layout/Stats/Information/Name
@onready var tGender : TextureRect				= $Margin/Layout/Stats/Information/Gender
@onready var lLevel : Label						= $Margin/Layout/Stats/Information/Level
@onready var lSpirit : Label					= $Margin/Layout/Stats/Information/Spirit

@onready var pExperience : Control				= $Margin/Layout/Stats/PreciseStats/ActiveStatsBox/ExperienceBox/ProgressBar
@onready var pHealth : Control					= $Margin/Layout/Stats/PreciseStats/ActiveStatsBox/HealthBox/ProgressBar
@onready var pMana : Control					= $Margin/Layout/Stats/PreciseStats/ActiveStatsBox/ManaBox/ProgressBar
@onready var pStamina : Control					= $Margin/Layout/Stats/PreciseStats/ActiveStatsBox/StaminaBox/ProgressBar
@onready var pWeight : Control					= $Margin/Layout/Stats/PreciseStats/ActiveStatsBox/WeightBox/ProgressBar

@onready var lStrength : Label					= $Margin/Layout/Stats/StatBox/StrengthBox/Current
@onready var lVitality : Label					= $Margin/Layout/Stats/StatBox/VitalityBox/Current
@onready var lAgility : Label					= $Margin/Layout/Stats/StatBox/AgilityBox/Current
@onready var lEndurance : Label					= $Margin/Layout/Stats/StatBox/EnduranceBox/Current
@onready var lConcentration : Label				= $Margin/Layout/Stats/StatBox/ConcentrationBox/Current
@onready var lAvailablePoints : Label			= $Margin/Layout/Stats/StatBox/AvailablePointsBox/Value

@onready var bStrength : Button					= $Margin/Layout/Stats/StatBox/StrengthBox/Button
@onready var bVitality : Button					= $Margin/Layout/Stats/StatBox/VitalityBox/Button
@onready var bAgility : Button					= $Margin/Layout/Stats/StatBox/AgilityBox/Button
@onready var bEndurance : Button				= $Margin/Layout/Stats/StatBox/EnduranceBox/Button
@onready var bConcentration : Button			= $Margin/Layout/Stats/StatBox/ConcentrationBox/Button

@onready var lAtkStrength : Label				= $Margin/Layout/Stats/PreciseStats/AdvancedStatsBox/AtkStrengthBox/Value
@onready var lAtkRange : Label					= $Margin/Layout/Stats/PreciseStats/AdvancedStatsBox/AtkRangeBox/Value
@onready var lCastDelay : Label					= $Margin/Layout/Stats/PreciseStats/AdvancedStatsBox/CastDelayBox/Value
@onready var lCooldownDelay : Label				= $Margin/Layout/Stats/PreciseStats/AdvancedStatsBox/CooldownDelayBox/Value
@onready var lCritRate : Label					= $Margin/Layout/Stats/PreciseStats/AdvancedStatsBox/CritRateBox/Value
@onready var lWalkSpeed : Label					= $Margin/Layout/Stats/PreciseStats/AdvancedStatsBox/WalkBox/Value

#
func IncreaseStrength():
	Launcher.Network.AddPersonalStat(EntityCommons.PersonalStat.STRENGTH)

func IncreaseVitality():
	Launcher.Network.AddPersonalStat(EntityCommons.PersonalStat.VITALITY)

func IncreaseAgility():
	Launcher.Network.AddPersonalStat(EntityCommons.PersonalStat.AGILITY)

func IncreaseEndurance():
	Launcher.Network.AddPersonalStat(EntityCommons.PersonalStat.ENDURANCE)

func IncreaseConcentration():
	Launcher.Network.AddPersonalStat(EntityCommons.PersonalStat.CONCENTRATION)

#
func Init(entity : BaseEntity):
	Callback.PlugCallback(entity.stat.active_stats_updated, RefreshActiveStats.bind(entity))
	Callback.PlugCallback(entity.stat.personal_stats_updated, RefreshPersonalStats.bind(entity))
	Callback.PlugCallback(entity.stat.entity_stats_updated, RefreshEntityStats.bind(entity))

	RefreshActiveStats(entity)
	RefreshPersonalStats(entity)
	RefreshEntityStats(entity)

func RefreshGender(entity : BaseEntity):
	var texture : Texture2D = null
	match entity.gender:
		EntityCommons.Gender.MALE:
			texture = EntityCommons.GenderMaleTexture
		EntityCommons.Gender.FEMALE:
			texture = EntityCommons.GenderFemaleTexture
		EntityCommons.Gender.NONBINARY:
			texture = EntityCommons.GenderNonBinaryTexture
	tGender.set_texture(texture)

func RefreshActiveStats(entity : BaseEntity):
	if not entity:
		pass

	RefreshGender(entity)
	lName.set_text(entity.entityName)
	lLevel.set_text("Lv. %d" % entity.stat.level)
	lSpirit.set_text(entity.stat.spiritShape)

	pExperience.SetStat(entity.stat.experience, Experience.GetNeededExperienceForNextLevel(entity.stat.level))
	pHealth.SetStat(entity.stat.health, entity.stat.current.maxHealth)
	pMana.SetStat(entity.stat.mana, entity.stat.current.maxMana)
	pStamina.SetStat(entity.stat.stamina, entity.stat.current.maxStamina)
	pWeight.SetStat(entity.stat.weight, entity.stat.current.weightCapacity)

func RefreshPersonalStats(entity : BaseEntity):
	if not entity:
		pass

	lStrength.set_text(str(entity.stat.strength))
	lVitality.set_text(str(entity.stat.vitality))
	lAgility.set_text(str(entity.stat.agility))
	lEndurance.set_text(str(entity.stat.endurance))
	lConcentration.set_text(str(entity.stat.concentration))

	var availablePoints : int = Formulas.GetMaxPersonalPoints(entity.stat) - Formulas.GetAssignedPersonalPoints(entity.stat)
	lAvailablePoints.set_text(str(availablePoints))

	bStrength.set_disabled(availablePoints <= 0 or entity.stat.strength >= EntityCommons.MaxPointPerPersonalStat)
	bVitality.set_disabled(availablePoints <= 0 or entity.stat.vitality >= EntityCommons.MaxPointPerPersonalStat)
	bAgility.set_disabled(availablePoints <= 0 or entity.stat.agility >= EntityCommons.MaxPointPerPersonalStat)
	bEndurance.set_disabled(availablePoints <= 0 or entity.stat.endurance >= EntityCommons.MaxPointPerPersonalStat)
	bConcentration.set_disabled(availablePoints <= 0 or entity.stat.concentration >= EntityCommons.MaxPointPerPersonalStat)

func RefreshEntityStats(entity : BaseEntity):
	if not entity:
		pass

	lAtkStrength.set_text(GetPercentString(entity.stat.current.attackStrength, entity.stat.base.attackStrength))
	lAtkRange.set_text(GetPercentString(entity.stat.current.attackRange, entity.stat.base.attackRange))
	lCastDelay.set_text(GetPercentString(entity.stat.base.castAttackDelay, entity.stat.current.castAttackDelay))
	lCooldownDelay.set_text(GetPercentString(entity.stat.base.cooldownAttackDelay, entity.stat.current.cooldownAttackDelay))
	lCritRate.set_text(GetPercentString(entity.stat.current.critRate, entity.stat.base.critRate))
	lWalkSpeed.set_text(GetPercentString(entity.stat.current.walkSpeed, entity.stat.base.walkSpeed))

#
func GetPercentString(current : float, base : float) -> String:
	return "%d%%" % (int(current / base * 100.0) if base > 0 else 100)
