extends WindowPanel

@onready var lName : Label						= $Layout/Scroll/Margin/Layout/Stats/Information/Name
@onready var tGender : TextureRect				= $Layout/Scroll/Margin/Layout/Stats/Information/Gender
@onready var lLevel : Label						= $Layout/Scroll/Margin/Layout/Stats/Information/Level
@onready var lSpirit : Label					= $Layout/Scroll/Margin/Layout/Stats/Information/Spirit

@onready var pExperience : Control				= $Layout/Scroll/Margin/Layout/Stats/PreciseStats/ActiveStatsBox/ExperienceBox/ProgressBar
@onready var pHealth : Control					= $Layout/Scroll/Margin/Layout/Stats/PreciseStats/ActiveStatsBox/HealthBox/ProgressBar
@onready var pMana : Control					= $Layout/Scroll/Margin/Layout/Stats/PreciseStats/ActiveStatsBox/ManaBox/ProgressBar
@onready var pStamina : Control					= $Layout/Scroll/Margin/Layout/Stats/PreciseStats/ActiveStatsBox/StaminaBox/ProgressBar
@onready var pWeight : Control					= $Layout/Scroll/Margin/Layout/Stats/PreciseStats/ActiveStatsBox/WeightBox/ProgressBar
@onready var lGP : Label						= $Layout/Scroll/Margin/Layout/Stats/PreciseStats/ActiveStatsBox/GPBox/Value

@onready var lStrength : Label					= $Layout/Scroll/Margin/Layout/Stats/StatBox/StrengthBox/Current
@onready var lVitality : Label					= $Layout/Scroll/Margin/Layout/Stats/StatBox/VitalityBox/Current
@onready var lAgility : Label					= $Layout/Scroll/Margin/Layout/Stats/StatBox/AgilityBox/Current
@onready var lEndurance : Label					= $Layout/Scroll/Margin/Layout/Stats/StatBox/EnduranceBox/Current
@onready var lConcentration : Label				= $Layout/Scroll/Margin/Layout/Stats/StatBox/ConcentrationBox/Current
@onready var lStrengthToAdd : Label				= $Layout/Scroll/Margin/Layout/Stats/StatBox/StrengthBox/ToAdd
@onready var lVitalityToAdd : Label				= $Layout/Scroll/Margin/Layout/Stats/StatBox/VitalityBox/ToAdd
@onready var lAgilityToAdd : Label				= $Layout/Scroll/Margin/Layout/Stats/StatBox/AgilityBox/ToAdd
@onready var lEnduranceToAdd : Label			= $Layout/Scroll/Margin/Layout/Stats/StatBox/EnduranceBox/ToAdd
@onready var lConcentrationToAdd : Label		= $Layout/Scroll/Margin/Layout/Stats/StatBox/ConcentrationBox/ToAdd
@onready var lAvailablePoints : Label			= $Layout/Scroll/Margin/Layout/Stats/StatBox/AvailablePointsBox/Value

@onready var bSave : Button						= $Layout/Scroll/Margin/Layout/Stats/StatBox/AvailablePointsBox/SaveButton
@onready var bReset : Button					= $Layout/Scroll/Margin/Layout/Stats/StatBox/AvailablePointsBox/ResetButton

@onready var bStrengthPlus : Button				= $Layout/Scroll/Margin/Layout/Stats/StatBox/StrengthBox/Button
@onready var bVitalityPlus : Button				= $Layout/Scroll/Margin/Layout/Stats/StatBox/VitalityBox/Button
@onready var bAgilityPlus : Button				= $Layout/Scroll/Margin/Layout/Stats/StatBox/AgilityBox/Button
@onready var bEndurancePlus : Button			= $Layout/Scroll/Margin/Layout/Stats/StatBox/EnduranceBox/Button
@onready var bConcentrationPlus : Button		= $Layout/Scroll/Margin/Layout/Stats/StatBox/ConcentrationBox/Button

@onready var bStrengthMinus : Button			= $Layout/Scroll/Margin/Layout/Stats/StatBox/StrengthBox/Minus
@onready var bVitalityMinus : Button			= $Layout/Scroll/Margin/Layout/Stats/StatBox/VitalityBox/Minus
@onready var bAgilityMinus : Button				= $Layout/Scroll/Margin/Layout/Stats/StatBox/AgilityBox/Minus
@onready var bEnduranceMinus : Button			= $Layout/Scroll/Margin/Layout/Stats/StatBox/EnduranceBox/Minus
@onready var bConcentrationMinus : Button		= $Layout/Scroll/Margin/Layout/Stats/StatBox/ConcentrationBox/Minus

@onready var lAtk : RichTextLabel				= $Layout/Scroll/Margin/Layout/Stats/PreciseStats/AdvancedStatsBox/AtkBox/Value
@onready var lDef : RichTextLabel				= $Layout/Scroll/Margin/Layout/Stats/PreciseStats/AdvancedStatsBox/DefBox/Value
@onready var lMAtk : RichTextLabel				= $Layout/Scroll/Margin/Layout/Stats/PreciseStats/AdvancedStatsBox/MAtkBox/Value
@onready var lMDef : RichTextLabel				= $Layout/Scroll/Margin/Layout/Stats/PreciseStats/AdvancedStatsBox/MDefBox/Value
@onready var lAtkRange : RichTextLabel			= $Layout/Scroll/Margin/Layout/Stats/PreciseStats/AdvancedStatsBox/AtkRangeBox/Value
@onready var lCastDelay : RichTextLabel			= $Layout/Scroll/Margin/Layout/Stats/PreciseStats/AdvancedStatsBox/CastDelayBox/Value
@onready var lCooldownDelay : RichTextLabel		= $Layout/Scroll/Margin/Layout/Stats/PreciseStats/AdvancedStatsBox/CooldownDelayBox/Value
@onready var lCritRate : RichTextLabel			= $Layout/Scroll/Margin/Layout/Stats/PreciseStats/AdvancedStatsBox/CritRateBox/Value
@onready var lDodgeRate : RichTextLabel			= $Layout/Scroll/Margin/Layout/Stats/PreciseStats/AdvancedStatsBox/DodgeRateBox/Value
@onready var lWalkSpeed : RichTextLabel			= $Layout/Scroll/Margin/Layout/Stats/PreciseStats/AdvancedStatsBox/WalkBox/Value

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
func RefreshPanelStats():
	Util.DuplicateObject(Launcher.Player.stat, panelStats)
	panelStats.strength += strengthIncreased
	panelStats.agility += agilityIncreased
	panelStats.vitality += vitalityIncreased
	panelStats.endurance += enduranceIncreased
	panelStats.concentration += concentrationIncreased

	panelStats.RefreshAttributes()
	
	RefreshVitalStats()
	RefreshAttributes()
	RefreshEntityStats()

func ResetIncreased():
	strengthIncreased = 0
	vitalityIncreased = 0
	agilityIncreased = 0
	enduranceIncreased = 0
	concentrationIncreased = 0
	panel_stats_updated.emit()

func ResetPanel():
	ResetIncreased()
	panel_stats_reset.emit()

func RefreshGender():
	var texture : Texture2D = null
	match Launcher.Player.stat.gender:
		ActorCommons.Gender.MALE:
			texture = ActorCommons.GenderMaleTexture
		ActorCommons.Gender.FEMALE:
			texture = ActorCommons.GenderFemaleTexture
		ActorCommons.Gender.NONBINARY:
			texture = ActorCommons.GenderNonBinaryTexture
	tGender.set_texture(texture)

func RefreshVitalStats():
	if not Launcher.Player:
		pass

	RefreshGender()
	lName.set_text(Launcher.Player.nick)
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

func RefreshAttributes():
	if not Launcher.Player:
		pass

	lStrength.set_text(str(Launcher.Player.stat.strength))
	lVitality.set_text(str(Launcher.Player.stat.vitality))
	lAgility.set_text(str(Launcher.Player.stat.agility))
	lEndurance.set_text(str(Launcher.Player.stat.endurance))
	lConcentration.set_text(str(Launcher.Player.stat.concentration))
	
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

func RefreshEntityStats():
	if not Launcher.Player:
		pass

	var liveCurrent : BaseStats = Launcher.Player.stat.current
	var liveMorph : BaseStats = Launcher.Player.stat.morphStat

	lAtk.set_text(GetStatBBCode(str(panelStats.current.attack), CellCommons.GetModifierDiffBBCode(CellCommons.Modifier.Attack, panelStats.current.attack - liveCurrent.attack)))
	lDef.set_text(GetStatBBCode(str(panelStats.current.defense), CellCommons.GetModifierDiffBBCode(CellCommons.Modifier.Defense, panelStats.current.defense - liveCurrent.defense)))
	lMAtk.set_text(GetStatBBCode(str(panelStats.current.mattack), CellCommons.GetModifierDiffBBCode(CellCommons.Modifier.MAttack, panelStats.current.mattack - liveCurrent.mattack)))
	lMDef.set_text(GetStatBBCode(str(panelStats.current.mdefense), CellCommons.GetModifierDiffBBCode(CellCommons.Modifier.MDefense, panelStats.current.mdefense - liveCurrent.mdefense)))
	lAtkRange.set_text(GetStatBBCode(str(panelStats.current.attackRange), CellCommons.GetModifierDiffBBCode(CellCommons.Modifier.AttackRange, panelStats.current.attackRange - liveCurrent.attackRange)))
	lCastDelay.set_text(GetStatBBCode("%0.2fs" % panelStats.current.castAttackDelay, CellCommons.GetModifierDiffBBCode(CellCommons.Modifier.CastDelay, panelStats.current.castAttackDelay - liveCurrent.castAttackDelay)))
	lCooldownDelay.set_text(GetStatBBCode("%0.2fs" % panelStats.current.cooldownAttackDelay, CellCommons.GetModifierDiffBBCode(CellCommons.Modifier.CooldownDelay, panelStats.current.cooldownAttackDelay - liveCurrent.cooldownAttackDelay)))
	lCritRate.set_text(GetStatBBCode("%.2f%%" % (panelStats.current.critRate * 100.0), CellCommons.GetModifierDiffBBCode(CellCommons.Modifier.CritRate, panelStats.current.critRate - liveCurrent.critRate)))
	lDodgeRate.set_text(GetStatBBCode("%.2f%%" % (panelStats.current.dodgeRate * 100.0), CellCommons.GetModifierDiffBBCode(CellCommons.Modifier.DodgeRate, panelStats.current.dodgeRate - liveCurrent.dodgeRate)))

	var newWalkPercent : float = GetPercent(panelStats.current.walkSpeed, panelStats.morphStat.walkSpeed)
	var liveWalkPercent : float = GetPercent(liveCurrent.walkSpeed, liveMorph.walkSpeed)
	lWalkSpeed.set_text(GetStatBBCode("%.2f%%" % newWalkPercent, CellCommons.GetPercentDiffBBCode(newWalkPercent - liveWalkPercent)))

#
func GetStatBBCode(valueText : String, diffBBCode : String) -> String:
	var baseColor : String = "#" + UICommons.LightTextColor.to_html(false)
	return "[right][color=%s]%s[/color]%s[/right]" % [baseColor, valueText, diffBBCode]

func GetPercent(current : float, base : float) -> float:
	return current / base * 100.0 if base > 0 else 100.0

#
func Connect():
	if not Launcher.Player:
		return

	Util.DuplicateObject(Launcher.Player.stat, panelStats)
	panelStats.RefreshAttributes()
	panelStats.RefreshEntityStats()
	RefreshSaveAndResetButtons()

	Callback.PlugCallback(panel_stats_updated, RefreshVitalStats)
	Callback.PlugCallback(panel_stats_updated, RefreshAttributes)
	Callback.PlugCallback(panel_stats_updated, RefreshEntityStats)
	Callback.PlugCallback(panel_stats_updated, RefreshSaveAndResetButtons)

	Callback.PlugCallback(Launcher.Player.stat.vital_stats_updated, RefreshPanelStats)
	Callback.PlugCallback(Launcher.Player.stat.attributes_updated, RefreshPanelStats)
	Callback.PlugCallback(Launcher.Player.stat.entity_stats_updated, RefreshPanelStats)

	Callback.PlugCallback(panel_stats_reset, RefreshPanelStats)

	RefreshVitalStats()
	RefreshAttributes()
	RefreshEntityStats()

#
func _post_launch():
	if Launcher.Map:
		if not Launcher.Map.PlayerWarped.is_connected(Connect):
			Launcher.Map.PlayerWarped.connect(Connect)

func _ready():
	_post_launch()
