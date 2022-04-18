extends Node

onready var HPBar			= $VBoxMain/HBoxTop/StatIndicator/Bars/HP/HPBar
onready var HPText			= $VBoxMain/HBoxTop/StatIndicator/Bars/HP/HPText
onready var ManaBar			= $VBoxMain/HBoxTop/StatIndicator/Bars/Mana/ManaBar

onready var ManaText		= $VBoxMain/HBoxTop/StatIndicator/Bars/Mana/ManaText
onready var StaminaBar		= $VBoxMain/HBoxTop/StatIndicator/Bars/Stamina/StaminaBar
onready var StaminaText		= $VBoxMain/HBoxTop/StatIndicator/Bars/Stamina/StaminaText

onready var LevelText		= $VBoxMain/HBoxTop/StatIndicator/LevelText
onready var ExpText			= $VBoxMain/HBoxTop/StatIndicator/ExpText

func GetRatio(currentValue : int, maxValue : int) -> float:
	var ratio = 0.0
	if maxValue > 0:
		ratio = float(currentValue) / maxValue * 100
	return ratio

func GetFormatedText(value : String) -> String:
	var i : int = value.length() - 3
	while i > 0:
		value = value.insert(i, ",")
		i = i - 3
	return value

func GetBarFormat(currentValue : int, maxValue : int) -> String:
	var currentValueText = GetFormatedText(currentValue as String)
	var maxValueText = GetFormatedText(maxValue as String)
	return currentValueText + " / " + maxValueText

func GetPercentFormat(value : int) -> String:
	return "%.2f%%" % [value]

func _ready():
		var hpRatio = GetRatio(GlobalWorld.currentPlayer.stat.health, GlobalWorld.currentPlayer.stat.maxHealth)
		var manaRatio = GetRatio(GlobalWorld.currentPlayer.stat.mana, GlobalWorld.currentPlayer.stat.maxMana)
		var staminaRatio = GetRatio(GlobalWorld.currentPlayer.stat.stamina, GlobalWorld.currentPlayer.stat.maxStamina)

		var hpFormat = GetBarFormat(GlobalWorld.currentPlayer.stat.health, GlobalWorld.currentPlayer.stat.maxHealth)
		var manaFormat = GetBarFormat(GlobalWorld.currentPlayer.stat.mana, GlobalWorld.currentPlayer.stat.maxMana)
		var staminaFormat = GetBarFormat(GlobalWorld.currentPlayer.stat.stamina, GlobalWorld.currentPlayer.stat.maxStamina)

		var levelFormat = String(GlobalWorld.currentPlayer.stat.level)
		var expFormat = GetPercentFormat(GlobalWorld.currentPlayer.stat.experience)

		HPBar.set_value(hpRatio)
		HPText.set_text(hpFormat)

		ManaBar.set_value(manaRatio)
		ManaText.set_text(manaFormat)

		StaminaBar.set_value(staminaRatio)
		StaminaText.set_text(staminaFormat)
		
		LevelText.set_text(levelFormat)
		ExpText.set_text(expFormat)
