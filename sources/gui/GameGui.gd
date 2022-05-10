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
		hpStat.SetStat(Launcher.World.currentPlayer.stat.health, Launcher.World.currentPlayer.stat.maxHealth)
	if manaStat:
		manaStat.SetStat(Launcher.World.currentPlayer.stat.mana, Launcher.World.currentPlayer.stat.maxMana)
	if staminaStat:
		staminaStat.SetStat(Launcher.World.currentPlayer.stat.stamina, Launcher.World.currentPlayer.stat.maxStamina)

	if weightStat:
		weightStat.SetStat(Launcher.World.currentPlayer.stat.weight, Launcher.World.currentPlayer.stat.maxWeight)

	var levelFormat = String(Launcher.World.currentPlayer.stat.level)
	LevelText.set_text(levelFormat)

	var expFormat = GetPercentFormat(Launcher.World.currentPlayer.stat.experience)
	ExpText.set_text(expFormat)
