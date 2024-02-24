extends TextureRect

@onready var hpStat				= $HP
@onready var manaStat			= $Mana
@onready var staminaStat		= $Stamina
@onready var expStat			= $Exp

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
			expStat.SetStat(Launcher.Player.stat.experience, Experience.GetNeededExperienceForNextLevel(Launcher.Player.stat.level))
