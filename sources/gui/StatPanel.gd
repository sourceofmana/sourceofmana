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

@onready var bSave : Button						= $Scroll/Margin/Layout/Stats/StatBox/AvailablePointsBox/SaveButton
@onready var bReset : Button					= $Scroll/Margin/Layout/Stats/StatBox/AvailablePointsBox/ResetButton

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
signal panel_stats_updated

var strengthIncreased: int
var vitalityIncreased: int
var agilityIncreased: int
var enduranceIncreased: int
var concentrationIncreased: int

#
func IncreaseStrength():
	strengthIncreased += 1
	panelStats.AddAttribute(ActorCommons.Attribute.STRENGTH)
	panel_stats_updated.emit()

func ReduceStrength():
	strengthIncreased = max(0, strengthIncreased - 1)
	panelStats.ReduceAttribute(ActorCommons.Attribute.STRENGTH)
	panel_stats_updated.emit()

func IncreaseVitality():
	vitalityIncreased += 1
	panelStats.AddAttribute(ActorCommons.Attribute.VITALITY)
	panel_stats_updated.emit()

func ReduceVitality():
	vitalityIncreased = max(0, vitalityIncreased - 1)
	panelStats.ReduceAttribute(ActorCommons.Attribute.VITALITY)
	panel_stats_updated.emit()

func IncreaseAgility():
	agilityIncreased += 1
	panelStats.AddAttribute(ActorCommons.Attribute.AGILITY)
	panel_stats_updated.emit()
	
func ReduceAgility():
	agilityIncreased = max(0, agilityIncreased - 1)
	panelStats.ReduceAttribute(ActorCommons.Attribute.AGILITY)
	panel_stats_updated.emit()

func IncreaseEndurance():
	enduranceIncreased += 1
	panelStats.AddAttribute(ActorCommons.Attribute.ENDURANCE)
	panel_stats_updated.emit()

func ReduceEndurance():
	enduranceIncreased = max(0, enduranceIncreased - 1)
	panelStats.ReduceAttribute(ActorCommons.Attribute.ENDURANCE)
	panel_stats_updated.emit()

func IncreaseConcentration():
	concentrationIncreased += 1
	panelStats.AddAttribute(ActorCommons.Attribute.CONCENTRATION)
	panel_stats_updated.emit()

func ReduceConcentration():
	concentrationIncreased = max(0, concentrationIncreased - 1)
	panelStats.ReduceAttribute(ActorCommons.Attribute.CONCENTRATION)
	panel_stats_updated.emit()

func SubmitAttributeUpdate():
	Network.SetAttributes(panelStats.strength,
		panelStats.vitality,
		panelStats.agility,
		panelStats.endurance,
		panelStats.concentration)
	ResetIncreased()

#
func Init(entity : Entity):
	Util.DuplicateObject(entity.stat, panelStats)
	panelStats.RefreshAttributes()
	RefreshSaveAndResetButtons()

	Callback.PlugCallback(self.panel_stats_updated, RefreshVitalStats.bind(entity))
	Callback.PlugCallback(self.panel_stats_updated, RefreshAttributes.bind(entity))
	Callback.PlugCallback(self.panel_stats_updated, RefreshEntityStats.bind(entity))
	Callback.PlugCallback(self.panel_stats_updated, RefreshSaveAndResetButtons)
	
	Callback.PlugCallback(entity.stat.vital_stats_updated, RefreshPanelStats.bind(entity))
	Callback.PlugCallback(entity.stat.attributes_updated, RefreshPanelStats.bind(entity))
	Callback.PlugCallback(entity.stat.entity_stats_updated, RefreshPanelStats.bind(entity))
	
	Callback.PlugCallback(self.panel_stats_reset, RefreshPanelStats.bind(entity))

	RefreshVitalStats(entity)
	RefreshAttributes(entity)
	RefreshEntityStats(entity)

func RefreshPanelStats(entity : Entity):
	Util.DuplicateObject(entity.stat, panelStats)
	panelStats.strength += strengthIncreased
	panelStats.agility += agilityIncreased
	panelStats.vitality += vitalityIncreased
	panelStats.endurance += enduranceIncreased
	panelStats.concentration += concentrationIncreased

	panelStats.RefreshAttributes()
	
	RefreshVitalStats(entity)
	RefreshAttributes(entity)
	RefreshEntityStats(entity)

func ResetIncreased():
	strengthIncreased = 0
	vitalityIncreased = 0
	agilityIncreased = 0
	enduranceIncreased = 0
	concentrationIncreased = 0
	self.panel_stats_updated.emit()

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

func RefreshVitalStats(entity : Entity):
	if not entity:
		pass

	RefreshGender(entity)
	lName.set_text(entity.nick)
	lLevel.set_text("Lv. %d" % panelStats.level)
	var spiritData : EntityData = DB.EntitiesDB.get(panelStats.spirit, null)
	if spiritData:
		lSpirit.set_text(spiritData._name)

	pExperience.SetStat(panelStats.experience, Experience.GetNeededExperienceForNextLevel(panelStats.level))
	pHealth.SetStat(panelStats.health, panelStats.current.maxHealth)
	pMana.SetStat(panelStats.mana, panelStats.current.maxMana)
	pStamina.SetStat(panelStats.stamina, panelStats.current.maxStamina)
	pWeight.SetStat(panelStats.weight, panelStats.current.weightCapacity)
	lGP.set_text("%s GP" % Util.GetFormatedText(str(panelStats.gp)))

func RefreshAttributes(entity : Entity):
	if not entity:
		pass

	lStrength.set_text(str(entity.stat.strength))
	lVitality.set_text(str(entity.stat.vitality))
	lAgility.set_text(str(entity.stat.agility))
	lEndurance.set_text(str(entity.stat.endurance))
	lConcentration.set_text(str(entity.stat.concentration))
	
	lStrengthToAdd.set_text(GetAttributePointsToAddStr(strengthIncreased))
	lVitalityToAdd.set_text(GetAttributePointsToAddStr(vitalityIncreased))
	lAgilityToAdd.set_text(GetAttributePointsToAddStr(agilityIncreased))
	lEnduranceToAdd.set_text(GetAttributePointsToAddStr(enduranceIncreased))
	lConcentrationToAdd.set_text(GetAttributePointsToAddStr(concentrationIncreased))

	var availablePoints : int = Formula.GetMaxAttributePoints(panelStats.level) - Formula.GetAssignedAttributePoints(panelStats)
	lAvailablePoints.set_text(str(availablePoints))

	bStrengthPlus.set_disabled(availablePoints <= 0 or panelStats.strength >= ActorCommons.MaxPointPerAttributes)
	bVitalityPlus.set_disabled(availablePoints <= 0 or panelStats.vitality >= ActorCommons.MaxPointPerAttributes)
	bAgilityPlus.set_disabled(availablePoints <= 0 or panelStats.agility >= ActorCommons.MaxPointPerAttributes)
	bEndurancePlus.set_disabled(availablePoints <= 0 or panelStats.endurance >= ActorCommons.MaxPointPerAttributes)
	bConcentrationPlus.set_disabled(availablePoints <= 0 or panelStats.concentration >= ActorCommons.MaxPointPerAttributes)

	bStrengthMinus.set_disabled(strengthIncreased == 0)
	bVitalityMinus.set_disabled(vitalityIncreased == 0)
	bAgilityMinus.set_disabled(agilityIncreased == 0)
	bEnduranceMinus.set_disabled(enduranceIncreased == 0)
	bConcentrationMinus.set_disabled(concentrationIncreased == 0)

func RefreshSaveAndResetButtons():
	var cannotSaveOrReset : bool = (strengthIncreased == 0
			and vitalityIncreased == 0
			and agilityIncreased == 0
			and enduranceIncreased == 0
			and concentrationIncreased == 0)
	bSave.set_disabled(cannotSaveOrReset)
	bReset.set_disabled(cannotSaveOrReset)
	

func GetAttributePointsToAddStr(attributePointsToAdd : int) -> String:
	if attributePointsToAdd == 0:
		return ""
	else:
		return "+" + str(attributePointsToAdd)

func RefreshEntityStats(entity : Entity):
	if not entity:
		pass

	lAtk.set_text(str(panelStats.current.attack))
	lDef.set_text(str(panelStats.current.defense))
	lMAtk.set_text(str(panelStats.current.mattack))
	lMDef.set_text(str(panelStats.current.mdefense))
	lAtkRange.set_text(str(panelStats.current.attackRange))
	lCastDelay.set_text("%0.2fs" % panelStats.current.castAttackDelay)
	lCooldownDelay.set_text("%0.2fs" % panelStats.current.cooldownAttackDelay)
	lCritRate.set_text("%.d%%" % (panelStats.current.critRate * 100.0))
	lDodgeRate.set_text("%.d%%" % (panelStats.current.dodgeRate * 100.0))
	lWalkSpeed.set_text(GetPercentString(panelStats.current.walkSpeed, panelStats.morphStat.walkSpeed))

#
func GetPercentString(current : float, base : float) -> String:
	return "%d%%" % (int(current / base * 100.0) if base > 0 else 100)
