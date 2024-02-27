extends Control

@onready var hpStat				= $StatContent/HP
@onready var manaStat			= $StatContent/Mana
@onready var staminaStat		= $StatContent/Stamina
@onready var expStat			= $StatContent/Exp

#
func Refresh():
	if Launcher.Player:
		hpStat.SetStat(Launcher.Player.stat.health, Launcher.Player.stat.current.maxHealth)
		manaStat.SetStat(Launcher.Player.stat.mana, Launcher.Player.stat.current.maxMana)
		staminaStat.SetStat(Launcher.Player.stat.stamina, Launcher.Player.stat.current.maxStamina)
		expStat.SetStat(Launcher.Player.stat.experience, Experience.GetNeededExperienceForNextLevel(Launcher.Player.stat.level))

func Init():
	Callback.PlugCallback(Launcher.Player.stat.active_stats_updated, Refresh)
	Refresh()

#
func _on_button_pressed():
	Launcher.GUI.ToggleControl(Launcher.GUI.statWindow)
