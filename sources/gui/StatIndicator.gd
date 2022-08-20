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
func _ready():
	if Launcher.Entities.activePlayer:
		assert(hpStat && manaStat && staminaStat, "Stat progress bars are missing")

		if hpStat:
			hpStat.SetStat(Launcher.Entities.activePlayer.stat.health, Launcher.Entities.activePlayer.stat.maxHealth)
		if manaStat:
			manaStat.SetStat(Launcher.Entities.activePlayer.stat.mana, Launcher.Entities.activePlayer.stat.maxMana)
		if staminaStat:
			staminaStat.SetStat(Launcher.Entities.activePlayer.stat.stamina, Launcher.Entities.activePlayer.stat.maxStamina)
		if levelText:
			levelText.set_text(String.num_int64(Launcher.Entities.activePlayer.stat.level))
		if expText:
			expText.set_text(GetPercentFormat(Launcher.Entities.activePlayer.stat.experience))
