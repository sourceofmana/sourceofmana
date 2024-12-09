extends PanelContainer

#
@onready var strengthLabel : Label			= $Margin/VBox/Strength/Value
@onready var strengthMinus : Button			= $Margin/VBox/Strength/Minus
@onready var strengthPlus : Button			= $Margin/VBox/Strength/Plus

@onready var vitalityLabel : Label			= $Margin/VBox/Vitality/Value
@onready var vitalityMinus : Button			= $Margin/VBox/Vitality/Minus
@onready var vitalityPlus : Button			= $Margin/VBox/Vitality/Plus

@onready var agilityLabel : Label			= $Margin/VBox/Agility/Value
@onready var agilityMinus : Button			= $Margin/VBox/Agility/Minus
@onready var agilityPlus : Button			= $Margin/VBox/Agility/Plus

@onready var enduranceLabel : Label			= $Margin/VBox/Endurance/Value
@onready var enduranceMinus : Button		= $Margin/VBox/Endurance/Minus
@onready var endurancePlus : Button			= $Margin/VBox/Endurance/Plus

@onready var concentrationLabel : Label		= $Margin/VBox/Concentration/Value
@onready var concentrationMinus : Button	= $Margin/VBox/Concentration/Minus
@onready var concentrationPlus : Button		= $Margin/VBox/Concentration/Plus

var strengthValue : int						= 0
var vitalityValue : int						= 0
var agilityValue : int						= 0
var enduranceValue : int					= 0
var concentrationValue : int				= 0

var usedPoints : int						= 0

# Commons
func RefreshDisabledButtons():
	var disablePlus : bool = usedPoints == Formula.GetMaxAttributePoints(1)

	strengthMinus.set_disabled(strengthValue == 0)
	strengthPlus.set_disabled(disablePlus or strengthValue == ActorCommons.MaxPointPerAttributes)
	vitalityMinus.set_disabled(vitalityValue == 0)
	vitalityPlus.set_disabled(disablePlus or vitalityValue == ActorCommons.MaxPointPerAttributes)
	agilityMinus.set_disabled(agilityValue == 0)
	agilityPlus.set_disabled(disablePlus or agilityValue == ActorCommons.MaxPointPerAttributes)
	enduranceMinus.set_disabled(enduranceValue == 0)
	endurancePlus.set_disabled(disablePlus or enduranceValue == ActorCommons.MaxPointPerAttributes)
	concentrationMinus.set_disabled(concentrationValue == 0)
	concentrationPlus.set_disabled(disablePlus or concentrationValue == ActorCommons.MaxPointPerAttributes)

func Randomize():
	var availablePoints : int = Formula.GetMaxAttributePoints(1)
	var partitions : Array = []

	for i in range(4):
		partitions.append(randi() % availablePoints)

	partitions.append(availablePoints)
	partitions.sort()

	strengthValue = partitions[0]
	strengthLabel.set_text(str(strengthValue))
	vitalityValue = partitions[1] - partitions[0]
	vitalityLabel.set_text(str(vitalityValue))
	agilityValue = partitions[2] - partitions[1]
	agilityLabel.set_text(str(agilityValue))
	enduranceValue = partitions[3] - partitions[2]
	enduranceLabel.set_text(str(enduranceValue))
	concentrationValue = partitions[4] - partitions[3]
	concentrationLabel.set_text(str(concentrationValue))
	usedPoints = partitions[4]

	RefreshDisabledButtons()

func GetValues():
	return {
		"strength" = strengthValue,
		"vitality" = vitalityValue,
		"agility" = agilityValue,
		"endurance" = enduranceValue,
		"concentration" = concentrationValue,
	}

# Strength
func _on_strength_minus_button():
	if strengthValue > 0:
		strengthValue -= 1
		usedPoints -= 1
		strengthLabel.set_text(str(strengthValue))
		RefreshDisabledButtons()

func _on_strength_plus_button():
	if strengthValue < ActorCommons.MaxPointPerAttributes:
		strengthValue += 1
		usedPoints += 1
		strengthLabel.set_text(str(strengthValue))
		RefreshDisabledButtons()

# Vitality
func _on_vitality_minus_button():
	if vitalityValue > 0:
		vitalityValue -= 1
		usedPoints -= 1
		vitalityLabel.set_text(str(vitalityValue))
		RefreshDisabledButtons()

func _on_vitality_plus_button():
	if vitalityValue < ActorCommons.MaxPointPerAttributes:
		vitalityValue += 1
		usedPoints += 1
		vitalityLabel.set_text(str(vitalityValue))
		RefreshDisabledButtons()

# Agility
func _on_agility_minus_button():
	if agilityValue > 0:
		agilityValue -= 1
		usedPoints -= 1
		agilityLabel.set_text(str(agilityValue))
		RefreshDisabledButtons()

func _on_agility_plus_button():
	if agilityValue < ActorCommons.MaxPointPerAttributes:
		agilityValue += 1
		usedPoints += 1
		agilityLabel.set_text(str(agilityValue))
		RefreshDisabledButtons()

# Endurance
func _on_endurance_minus_button():
	if enduranceValue > 0:
		enduranceValue -= 1
		usedPoints -= 1
		enduranceLabel.set_text(str(enduranceValue))
		RefreshDisabledButtons()

func _on_endurance_plus_button():
	if enduranceValue < ActorCommons.MaxPointPerAttributes:
		enduranceValue += 1
		usedPoints += 1
		enduranceLabel.set_text(str(enduranceValue))
		RefreshDisabledButtons()

# Concentration
func _on_concentration_minus_button():
	if concentrationValue > 0:
		concentrationValue -= 1
		usedPoints -= 1
		concentrationLabel.set_text(str(concentrationValue))
		RefreshDisabledButtons()

func _on_concentration_plus_button():
	if concentrationValue < ActorCommons.MaxPointPerAttributes:
		concentrationValue += 1
		usedPoints += 1
		concentrationLabel.set_text(str(concentrationValue))
		RefreshDisabledButtons()

# Override
func _ready():
	strengthValue = ActorCommons.DefaultAttributes["strength"]
	strengthLabel.set_text(str(strengthValue))
	vitalityValue = ActorCommons.DefaultAttributes["vitality"]
	vitalityLabel.set_text(str(vitalityValue))
	agilityValue = ActorCommons.DefaultAttributes["agility"]
	agilityLabel.set_text(str(agilityValue))
	enduranceValue = ActorCommons.DefaultAttributes["endurance"]
	enduranceLabel.set_text(str(enduranceValue))
	concentrationValue = ActorCommons.DefaultAttributes["concentration"]
	concentrationLabel.set_text(str(concentrationValue))
	usedPoints = strengthValue + vitalityValue + agilityValue + enduranceValue + concentrationValue
	assert(usedPoints == Formula.GetMaxAttributePoints(1), "Default attributes are using a wrong amount of attribute points")

	RefreshDisabledButtons()
