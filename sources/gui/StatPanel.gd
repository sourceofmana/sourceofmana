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
@onready var lStrengthToAdd : Label				= $Scroll/Margin/Layout/Stats/StatBox/StrengthBox/ToAdd
@onready var lVitalityToAdd : Label				= $Scroll/Margin/Layout/Stats/StatBox/VitalityBox/ToAdd
@onready var lAgilityToAdd : Label				= $Scroll/Margin/Layout/Stats/StatBox/AgilityBox/ToAdd
@onready var lEnduranceToAdd : Label			= $Scroll/Margin/Layout/Stats/StatBox/EnduranceBox/ToAdd
@onready var lConcentrationToAdd : Label		= $Scroll/Margin/Layout/Stats/StatBox/ConcentrationBox/ToAdd
@onready var lAvailablePoints : Label			= $Scroll/Margin/Layout/Stats/StatBox/AvailablePointsBox/Value

@onready var bStrengthPlus : Button				= $Scroll/Margin/Layout/Stats/StatBox/StrengthBox/Button
@onready var bVitalityPlus : Button				= $Scroll/Margin/Layout/Stats/StatBox/VitalityBox/Button
@onready var bAgilityPlus : Button				= $Scroll/Margin/Layout/Stats/StatBox/AgilityBox/Button
@onready var bEndurancePlus : Button			= $Scroll/Margin/Layout/Stats/StatBox/EnduranceBox/Button
@onready var bConcentrationPlus : Button		= $Scroll/Margin/Layout/Stats/StatBox/ConcentrationBox/Button

@onready var bStrengthMinus : Button			= $Scroll/Margin/Layout/Stats/StatBox/StrengthBox/Minus
@onready var bVitalityMinus : Button			= $Scroll/Margin/Layout/Stats/StatBox/VitalityBox/Minus
@onready var bAgilityMinus : Button				= $Scroll/Margin/Layout/Stats/StatBox/AgilityBox/Minus
@onready var bEnduranceMinus : Button			= $Scroll/Margin/Layout/Stats/StatBox/EnduranceBox/Minus
@onready var bConcentrationMinus : Button		= $Scroll/Margin/Layout/Stats/StatBox/ConcentrationBox/Minus

@onready var lAtk : Label						= $Scroll/Margin/Layout/Stats/PreciseStats/AdvancedStatsBox/AtkBox/Value
@onready var lDef : Label						= $Scroll/Margin/Layout/Stats/PreciseStats/AdvancedStatsBox/DefBox/Value
@onready var lMAtk : Label						= $Scroll/Margin/Layout/Stats/PreciseStats/AdvancedStatsBox/MAtkBox/Value
@onready var lMDef : Label						= $Scroll/Margin/Layout/Stats/PreciseStats/AdvancedStatsBox/MDefBox/Value
@onready var lAtkRange : Label					= $Scroll/Margin/Layout/Stats/PreciseStats/AdvancedStatsBox/AtkRangeBox/Value
@onready var lCastDelay : Label					= $Scroll/Margin/Layout/Stats/PreciseStats/AdvancedStatsBox/CastDelayBox/Value
@onready var lCooldownDelay : Label				= $Scroll/Margin/Layout/Stats/PreciseStats/AdvancedStatsBox/CooldownDelayBox/Value
@onready var lCritRate : Label					= $Scroll/Margin/Layout/Stats/PreciseStats/AdvancedStatsBox/CritRateBox/Value
@onready var lDodgeRate : Label					= $Scroll/Margin/Layout/Stats/PreciseStats/AdvancedStatsBox/DodgeRateBox/Value
@onready var lWalkSpeed : Label					= $Scroll/Margin/Layout/Stats/PreciseStats/AdvancedStatsBox/WalkBox/Value

var panelStats: ActorStats = ActorStats.new()
signal panel_stats_reset

var strengthIncreased: int
var vitalityIncreased: int
var agilityIncreased: int
var enduranceIncreased: int
var concentrationIncreased: int

#
func IncreaseStrength():
	strengthIncreased += 1
	panelStats.AddAttribute(ActorCommons.Attribute.STRENGTH)

func ReduceStrength():
	if strengthIncreased > 0:
		strengthIncreased = max(0, strengthIncreased - 1)
		panelStats.ReduceAttribute(ActorCommons.Attribute.STRENGTH)

func IncreaseVitality():
	vitalityIncreased += 1
	panelStats.AddAttribute(ActorCommons.Attribute.VITALITY)

func ReduceVitality():
	if vitalityIncreased > 0:
		vitalityIncreased = max(0, vitalityIncreased - 1)
		panelStats.ReduceAttribute(ActorCommons.Attribute.VITALITY)

func IncreaseAgility():
	agilityIncreased += 1
	panelStats.AddAttribute(ActorCommons.Attribute.AGILITY)
	
func ReduceAgility():
	if agilityIncreased > 0:
		agilityIncreased = max(0, agilityIncreased - 1)
		panelStats.ReduceAttribute(ActorCommons.Attribute.AGILITY)

func IncreaseEndurance():
	enduranceIncreased += 1
	panelStats.AddAttribute(ActorCommons.Attribute.ENDURANCE)

func ReduceEndurance():
	if enduranceIncreased > 0:
		enduranceIncreased = max(0, enduranceIncreased - 1)
		panelStats.ReduceAttribute(ActorCommons.Attribute.ENDURANCE)

func IncreaseConcentration():
	concentrationIncreased += 1
	panelStats.AddAttribute(ActorCommons.Attribute.CONCENTRATION)

func ReduceConcentration():
	if concentrationIncreased > 0:
		concentrationIncreased = max(0, concentrationIncreased - 1)
		panelStats.ReduceAttribute(ActorCommons.Attribute.CONCENTRATION)

func SubmitAttributeUpdate():
	Network.AddAttributes({
		ActorCommons.Attribute.STRENGTH: strengthIncreased,
		ActorCommons.Attribute.VITALITY: vitalityIncreased,
		ActorCommons.Attribute.AGILITY: agilityIncreased,
		ActorCommons.Attribute.ENDURANCE: enduranceIncreased,
		ActorCommons.Attribute.CONCENTRATION: concentrationIncreased
	})
	ResetIncreased()

#
func Init(entity : Entity):
	CopyStats(entity.stat, panelStats)

	Callback.PlugCallback(panelStats.vital_stats_updated, RefreshVitalStats.bind(entity, panelStats))
	Callback.PlugCallback(panelStats.attributes_updated, RefreshAttributes.bind(entity, panelStats))
	Callback.PlugCallback(panelStats.entity_stats_updated, RefreshEntityStats.bind(entity, panelStats))
	
	Callback.PlugCallback(entity.stat.vital_stats_updated, RefreshPanelStats.bind(entity))
	Callback.PlugCallback(entity.stat.attributes_updated, RefreshPanelStats.bind(entity))
	Callback.PlugCallback(entity.stat.entity_stats_updated, RefreshPanelStats.bind(entity))
	
	Callback.PlugCallback(self.panel_stats_reset, RefreshPanelStats.bind(entity))

	RefreshVitalStats(entity, panelStats)
	RefreshAttributes(entity, panelStats)
	RefreshEntityStats(entity, panelStats)

func RefreshPanelStats(entity : Entity):
	CopyStats(entity.stat, panelStats)
	
	RefreshVitalStats(entity, panelStats)
	RefreshAttributes(entity, panelStats)
	RefreshEntityStats(entity, panelStats)

func CopyStats(source : ActorStats, target : ActorStats):
	target.strength = source.strength + strengthIncreased
	target.vitality = source.vitality + vitalityIncreased
	target.agility = source.agility + agilityIncreased
	target.endurance = source.endurance + enduranceIncreased
	target.concentration = source.concentration + concentrationIncreased

	target.level = source.level
	target.modifiers = source.modifiers
	target.morphStat.walkSpeed = source.morphStat.walkSpeed

	target.RefreshAttributes()

func ResetIncreased():
	strengthIncreased = 0
	vitalityIncreased = 0
	agilityIncreased = 0
	enduranceIncreased = 0
	concentrationIncreased = 0

func ResetPanel():
	ResetIncreased()
	self.panel_stats_reset.emit()

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

func RefreshVitalStats(entity : Entity, stats : ActorStats):
	if not entity:
		pass

	RefreshGender(entity)
	lName.set_text(entity.nick)
	lLevel.set_text("Lv. %d" % stats.level)
	var spiritData : EntityData = DB.EntitiesDB.get(stats.spirit, null)
	if spiritData:
		lSpirit.set_text(spiritData._name)

	pExperience.SetStat(stats.experience, Experience.GetNeededExperienceForNextLevel(stats.level))
	pHealth.SetStat(stats.health, stats.current.maxHealth)
	pMana.SetStat(stats.mana, stats.current.maxMana)
	pStamina.SetStat(stats.stamina, stats.current.maxStamina)
	pWeight.SetStat(stats.weight, stats.current.weightCapacity)
	lGP.set_text("%s GP" % Util.GetFormatedText(str(stats.gp)))

func RefreshAttributes(entity : Entity, stats : ActorStats):
	if not entity:
		pass

	lStrength.set_text(str(entity.stat.strength))
	lVitality.set_text(str(entity.stat.vitality))
	lAgility.set_text(str(entity.stat.agility))
	lEndurance.set_text(str(entity.stat.endurance))
	lConcentration.set_text(str(entity.stat.concentration))
	
	lStrengthToAdd.set_text(ToAddString(strengthIncreased))
	lVitalityToAdd.set_text(ToAddString(vitalityIncreased))
	lAgilityToAdd.set_text(ToAddString(agilityIncreased))
	lEnduranceToAdd.set_text(ToAddString(enduranceIncreased))
	lConcentrationToAdd.set_text(ToAddString(concentrationIncreased))

	var availablePoints : int = Formula.GetMaxAttributePoints(stats.level) - Formula.GetAssignedAttributePoints(stats)
	lAvailablePoints.set_text(str(availablePoints))

	bStrengthPlus.set_disabled(availablePoints <= 0 or stats.strength >= ActorCommons.MaxPointPerAttributes)
	bVitalityPlus.set_disabled(availablePoints <= 0 or stats.vitality >= ActorCommons.MaxPointPerAttributes)
	bAgilityPlus.set_disabled(availablePoints <= 0 or stats.agility >= ActorCommons.MaxPointPerAttributes)
	bEndurancePlus.set_disabled(availablePoints <= 0 or stats.endurance >= ActorCommons.MaxPointPerAttributes)
	bConcentrationPlus.set_disabled(availablePoints <= 0 or stats.concentration >= ActorCommons.MaxPointPerAttributes)

	bStrengthMinus.set_disabled(strengthIncreased == 0)
	bVitalityMinus.set_disabled(vitalityIncreased == 0)
	bAgilityMinus.set_disabled(agilityIncreased == 0)
	bEnduranceMinus.set_disabled(enduranceIncreased == 0)
	bConcentrationMinus.set_disabled(concentrationIncreased == 0)
	

func ToAddString(attributePointsToAdd : int) -> String:
	if attributePointsToAdd == 0:
		return ""
	else:
		return "+" + str(attributePointsToAdd)

func RefreshEntityStats(entity : Entity, stats : ActorStats):
	if not entity:
		pass

	lAtk.set_text(str(stats.current.attack))
	lDef.set_text(str(stats.current.defense))
	lMAtk.set_text(str(stats.current.mattack))
	lMDef.set_text(str(stats.current.mdefense))
	lAtkRange.set_text(str(stats.current.attackRange))
	lCastDelay.set_text("%0.2fs" % stats.current.castAttackDelay)
	lCooldownDelay.set_text("%0.2fs" % stats.current.cooldownAttackDelay)
	lCritRate.set_text("%.d%%" % (stats.current.critRate * 100.0))
	lDodgeRate.set_text("%.d%%" % (stats.current.dodgeRate * 100.0))
	lWalkSpeed.set_text(GetPercentString(stats.current.walkSpeed, stats.morphStat.walkSpeed))

#
func GetPercentString(current : float, base : float) -> String:
	return "%d%%" % (int(current / base * 100.0) if base > 0 else 100)
