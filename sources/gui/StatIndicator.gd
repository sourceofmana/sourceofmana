extends TextureRect

@onready var hpStat				= $Bars/HP
@onready var manaStat			= $Bars/Mana
@onready var staminaStat		= $Bars/Stamina
@onready var expStat			= $Bars/Exp

#
func GetPercentFormat(value : int) -> String:
	return "%.2f%%" % [value]

#
func _process(_dt : float):
	if Launcher.Player:
		assert(hpStat && manaStat && staminaStat && expStat, "Stat controls are missing")

		if hpStat:
			hpStat.SetStat(Launcher.Player.stat.health, Launcher.Player.stat.current.maxHealth)
		if manaStat:
			manaStat.SetStat(Launcher.Player.stat.mana, Launcher.Player.stat.current.maxMana)
		if staminaStat:
			staminaStat.SetStat(Launcher.Player.stat.stamina, Launcher.Player.stat.current.maxStamina)
		if expStat:
			expStat.SetStat(Launcher.Player.stat.experience, 100.00)
