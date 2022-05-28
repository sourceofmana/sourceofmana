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
		hpStat.SetStat(Launcher.Entities.activePlayer.stat.health, Launcher.Entities.activePlayer.stat.maxHealth)
	if manaStat:
		manaStat.SetStat(Launcher.Entities.activePlayer.stat.mana, Launcher.Entities.activePlayer.stat.maxMana)
	if staminaStat:
		staminaStat.SetStat(Launcher.Entities.activePlayer.stat.stamina, Launcher.Entities.activePlayer.stat.maxStamina)

	if weightStat:
		weightStat.SetStat(Launcher.Entities.activePlayer.stat.weight, Launcher.Entities.activePlayer.stat.maxWeight)

	var levelFormat = String(Launcher.Entities.activePlayer.stat.level)
	LevelText.set_text(levelFormat)

	var expFormat = GetPercentFormat(Launcher.Entities.activePlayer.stat.experience)
	ExpText.set_text(expFormat)
