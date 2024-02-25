extends TextureRect

@onready var hpStat				= $HP
@onready var manaStat			= $Mana
@onready var staminaStat		= $Stamina
@onready var expStat			= $Exp

#
func Refresh():
	if Launcher.Player:
		hpStat.SetStat(Launcher.Player.stat.health, Launcher.Player.stat.current.maxHealth)
		manaStat.SetStat(Launcher.Player.stat.mana, Launcher.Player.stat.current.maxMana)
		staminaStat.SetStat(Launcher.Player.stat.stamina, Launcher.Player.stat.current.maxStamina)
		expStat.SetStat(Launcher.Player.stat.experience, Experience.GetNeededExperienceForNextLevel(Launcher.Player.stat.level))
