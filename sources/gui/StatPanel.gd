extends WindowPanel

@onready var lName : Label						= $Scroll/Margin/Layout/Stats/Information/Name
@onready var tGender : TextureRect				= $Scroll/Margin/Layout/Stats/Information/Gender
@onready var lLevel : Label						= $Scroll/Margin/Layout/Stats/Information/Level
@onready var lSpirit : Label					= $Scroll/Margin/Layout/Stats/Information/Spirit

@onready var pExperience : Control				= $Scroll/Margin/Layout/Stats/PreciseStats/ActiveStatsBox/ExperienceBox/ProgressBar
@onready var pHealth : Control					= $Scroll/Margin/Layout/Stats/PreciseStats/ActiveStatsBox/HealthBox/ProgressBar
@onready var pMana : Control					= $Scroll/Margin/Layout/Stats/PreciseStats/ActiveStatsBox/ManaBox/ProgressBar
@onready var pStamina : Control					= $Scroll/Margin/Layout/Stats/PreciseStats/ActiveStatsBox/StaminaBox/ProgressBar
@onready var pWeight : Control					= $Scroll/Margin/Layout/Stats/PreciseStats/ActiveStatsBox/WeightBox/ProgressBar
@onready var lGP : Label						= $Scroll/Margin/Layout/Stats/PreciseStats/ActiveStatsBox/GPBox/Value

@onready var lStrength : Label					= $Scroll/Margin/Layout/Stats/StatBox/StrengthBox/Current
@onready var lVitality : Label					= $Scroll/Margin/Layout/Stats/StatBox/VitalityBox/Current
@onready var lAgility : Label					= $Scroll/Margin/Layout/Stats/StatBox/AgilityBox/Current
@onready var lEndurance : Label					= $Scroll/Margin/Layout/Stats/StatBox/EnduranceBox/Current
@onready var lConcentration : Label				= $Scroll/Margin/Layout/Stats/StatBox/ConcentrationBox/Current
@onready var lAvailablePoints : Label			= $Scroll/Margin/Layout/Stats/StatBox/AvailablePointsBox/Value

@onready var bStrength : Button					= $Scroll/Margin/Layout/Stats/StatBox/StrengthBox/Button
@onready var bVitality : Button					= $Scroll/Margin/Layout/Stats/StatBox/VitalityBox/Button
@onready var bAgility : Button					= $Scroll/Margin/Layout/Stats/StatBox/AgilityBox/Button
@onready var bEndurance : Button				= $Scroll/Margin/Layout/Stats/StatBox/EnduranceBox/Button
@onready var bConcentration : Button			= $Scroll/Margin/Layout/Stats/StatBox/ConcentrationBox/Button

@onready var lAtk : Label						= $Scroll/Margin/Layout/Stats/PreciseStats/AdvancedStatsBox/AtkBox/Value
@onready var lDef : Label						= $Scroll/Margin/Layout/Stats/PreciseStats/AdvancedStatsBox/DefBox/Value
@onready var lAtkRange : Label					= $Scroll/Margin/Layout/Stats/PreciseStats/AdvancedStatsBox/AtkRangeBox/Value
@onready var lCastDelay : Label					= $Scroll/Margin/Layout/Stats/PreciseStats/AdvancedStatsBox/CastDelayBox/Value
@onready var lCooldownDelay : Label				= $Scroll/Margin/Layout/Stats/PreciseStats/AdvancedStatsBox/CooldownDelayBox/Value
@onready var lCritRate : Label					= $Scroll/Margin/Layout/Stats/PreciseStats/AdvancedStatsBox/CritRateBox/Value
@onready var lDodgeRate : Label					= $Scroll/Margin/Layout/Stats/PreciseStats/AdvancedStatsBox/DodgeRateBox/Value
@onready var lWalkSpeed : Label					= $Scroll/Margin/Layout/Stats/PreciseStats/AdvancedStatsBox/WalkBox/Value

#
func IncreaseStrength():
	Launcher.Network.AddAttribute(ActorCommons.Attribute.STRENGTH)

func IncreaseVitality():
	Launcher.Network.AddAttribute(ActorCommons.Attribute.VITALITY)

func IncreaseAgility():
	Launcher.Network.AddAttribute(ActorCommons.Attribute.AGILITY)

func IncreaseEndurance():
	Launcher.Network.AddAttribute(ActorCommons.Attribute.ENDURANCE)

func IncreaseConcentration():
	Launcher.Network.AddAttribute(ActorCommons.Attribute.CONCENTRATION)

#
func Init(entity : Entity):
	Callback.PlugCallback(entity.stat.active_stats_updated, RefreshActiveStats.bind(entity))
	Callback.PlugCallback(entity.stat.attributes_updated, RefreshAttributes.bind(entity))
	Callback.PlugCallback(entity.stat.entity_stats_updated, RefreshEntityStats.bind(entity))

	RefreshActiveStats(entity)
	RefreshAttributes(entity)
	RefreshEntityStats(entity)

func RefreshGender(entity : Entity):
	var texture : Texture2D = null
	match entity.gender:
		ActorCommons.Gender.MALE:
			texture = ActorCommons.GenderMaleTexture
		ActorCommons.Gender.FEMALE:
			texture = ActorCommons.GenderFemaleTexture
		ActorCommons.Gender.NONBINARY:
			texture = ActorCommons.GenderNonBinaryTexture
	tGender.set_texture(texture)

func RefreshActiveStats(entity : Entity):
	if not entity:
		pass

	RefreshGender(entity)
	lName.set_text(entity.nick)
	lLevel.set_text("Lv. %d" % entity.stat.level)
	lSpirit.set_text(entity.stat.spiritShape)

	pExperience.SetStat(entity.stat.experience, Experience.GetNeededExperienceForNextLevel(entity.stat.level))
	pHealth.SetStat(entity.stat.health, entity.stat.current.maxHealth)
	pMana.SetStat(entity.stat.mana, entity.stat.current.maxMana)
	pStamina.SetStat(entity.stat.stamina, entity.stat.current.maxStamina)
	pWeight.SetStat(entity.stat.weight, entity.stat.current.weightCapacity)
	lGP.set_text("%s GP" % Util.GetFormatedText(str(entity.stat.gp)))

func RefreshAttributes(entity : Entity):
	if not entity:
		pass

	lStrength.set_text(str(entity.stat.strength))
	lVitality.set_text(str(entity.stat.vitality))
	lAgility.set_text(str(entity.stat.agility))
	lEndurance.set_text(str(entity.stat.endurance))
	lConcentration.set_text(str(entity.stat.concentration))

	var availablePoints : int = Formula.GetMaxAttributePoints(entity.stat) - Formula.GetAssignedAttributePoints(entity.stat)
	lAvailablePoints.set_text(str(availablePoints))

	bStrength.set_disabled(availablePoints <= 0 or entity.stat.strength >= ActorCommons.MaxPointPerAttributes)
	bVitality.set_disabled(availablePoints <= 0 or entity.stat.vitality >= ActorCommons.MaxPointPerAttributes)
	bAgility.set_disabled(availablePoints <= 0 or entity.stat.agility >= ActorCommons.MaxPointPerAttributes)
	bEndurance.set_disabled(availablePoints <= 0 or entity.stat.endurance >= ActorCommons.MaxPointPerAttributes)
	bConcentration.set_disabled(availablePoints <= 0 or entity.stat.concentration >= ActorCommons.MaxPointPerAttributes)

func RefreshEntityStats(entity : Entity):
	if not entity:
		pass

	lAtk.set_text(str(entity.stat.current.attack))
	lDef.set_text(str(entity.stat.current.defense))
	lAtkRange.set_text(str(entity.stat.current.attackRange))
	lCastDelay.set_text("%0.2fs" % entity.stat.current.castAttackDelay)
	lCooldownDelay.set_text("%0.2fs" % entity.stat.current.cooldownAttackDelay)
	lCritRate.set_text("%.d%%" % (entity.stat.current.critRate * 100.0))
	lDodgeRate.set_text("%.d%%" % (entity.stat.current.dodgeRate * 100.0))
	lWalkSpeed.set_text(GetPercentString(entity.stat.current.walkSpeed, entity.stat.morphStat.walkSpeed))

#
func GetPercentString(current : float, base : float) -> String:
	return "%d%%" % (int(current / base * 100.0) if base > 0 else 100)
