extends Node

onready var hpStat			= $VBoxMain/HBoxTop/StatIndicator/Bars/HP
onready var manaStat		= $VBoxMain/HBoxTop/StatIndicator/Bars/Mana
onready var staminaStat		= $VBoxMain/HBoxTop/StatIndicator/Bars/Stamina
onready var weightStat		= $FloatingWindows/Inventory/VBoxContainer/Weight/BgTex/Weight

onready var LevelText		= $VBoxMain/HBoxTop/StatIndicator/LevelText
onready var ExpText			= $VBoxMain/HBoxTop/StatIndicator/ExpText

#
func GetPercentFormat(value : int) -> String:
	return "%.2f%%" % [value]

#
func _ready():
	assert(hpStat && manaStat && staminaStat, "Stat progress bars are missing")

	if hpStat:
		hpStat.SetStat(GlobalWorld.currentPlayer.stat.health, GlobalWorld.currentPlayer.stat.maxHealth)
	if manaStat:
		manaStat.SetStat(GlobalWorld.currentPlayer.stat.mana, GlobalWorld.currentPlayer.stat.maxMana)
	if staminaStat:
		staminaStat.SetStat(GlobalWorld.currentPlayer.stat.stamina, GlobalWorld.currentPlayer.stat.maxStamina)

	if weightStat:
		weightStat.SetStat(GlobalWorld.currentPlayer.stat.weight, GlobalWorld.currentPlayer.stat.maxWeight)

	var levelFormat = String(GlobalWorld.currentPlayer.stat.level)
	LevelText.set_text(levelFormat)

	var expFormat = GetPercentFormat(GlobalWorld.currentPlayer.stat.experience)
	ExpText.set_text(expFormat)
