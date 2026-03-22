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

func Connect():
	if Launcher.Player:
		if not Launcher.Player.stat.vital_stats_updated.is_connected(Refresh):
			Launcher.Player.stat.vital_stats_updated.connect(Refresh)

#
func _post_launch():
	if Launcher.Map:
		if not Launcher.Map.PlayerWarped.is_connected(Connect):
			Launcher.Map.PlayerWarped.connect(Connect)

func _ready():
	_post_launch()

func _on_button_pressed():
	Launcher.GUI.ToggleControl(Launcher.GUI.statWindow)
