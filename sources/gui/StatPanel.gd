extends WindowPanel

@onready var lName : Label						= $Margin/Layout/Stats/Information/Name
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
	lStrength.set_text(str(lStrength.get_text().to_int() + 1))

func IncreaseVitality():
	lVitality.set_text(str(lVitality.get_text().to_int() + 1))

func IncreaseAgility():
	lAgility.set_text(str(lAgility.get_text().to_int() + 1))

func IncreaseEndurance():
	lEndurance.set_text(str(lEndurance.get_text().to_int() + 1))

func IncreaseConcentration():
	lConcentration.set_text(str(lConcentration.get_text().to_int() + 1))

#
func Refresh(entity : BaseEntity):
	RefreshActiveStats(entity)
	RefreshPersonalStats(entity)
	RefreshEntityStats(entity)

func RefreshActiveStats(entity : BaseEntity):
	if not entity:
		pass

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


func RefreshEntityStats(entity : BaseEntity):
	if not entity:
		pass

	lAtkStrength.set_text(str(entity.stat.current.attackStrength))
	lAtkRange.set_text(str(entity.stat.current.attackRange))
	lCastDelay.set_text(str(entity.stat.current.castAttackDelay))
	lCooldownDelay.set_text(str(entity.stat.current.cooldownAttackDelay))
	lCritRate.set_text(str(entity.stat.current.critRate))
	lWalkSpeed.set_text(str(entity.stat.current.walkSpeed))
