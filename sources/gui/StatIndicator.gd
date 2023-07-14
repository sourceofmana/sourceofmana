extends TextureRect

@onready var hpStat				= $Bars/HP
@onready var manaStat			= $Bars/Mana
@onready var staminaStat		= $Bars/Stamina
@onready var levelText			= $LevelText
@onready var expText			= $ExpText

#
func GetPercentFormat(value : int) -> String:
	return "%.2f%%" % [value]

#
func _process(_dt : float):
	if Launcher.Player:
		assert(hpStat && manaStat && staminaStat && expText, "Stat controls are missing")

		if hpStat:
			hpStat.SetStat(Launcher.Player.stat.health, Launcher.Player.stat.current.health)
		if manaStat:
			manaStat.SetStat(Launcher.Player.stat.mana, Launcher.Player.stat.current.mana)
		if staminaStat:
			staminaStat.SetStat(Launcher.Player.stat.stamina, Launcher.Player.stat.current.stamina)
		if levelText:
			levelText.set_text(String.num_int64(Launcher.Player.stat.level))
		if expText:
			expText.set_text(GetPercentFormat(Launcher.Player.stat.experience))
