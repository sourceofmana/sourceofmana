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
	if Launcher.Entities.playerEntity:
		assert(hpStat && manaStat && staminaStat, "Stat progress bars are missing")

		if hpStat:
			hpStat.SetStat(Launcher.Entities.playerEntity.stat.health, Launcher.Entities.playerEntity.stat.maxHealth)
		if manaStat:
			manaStat.SetStat(Launcher.Entities.playerEntity.stat.mana, Launcher.Entities.playerEntity.stat.maxMana)
		if staminaStat:
			staminaStat.SetStat(Launcher.Entities.playerEntity.stat.stamina, Launcher.Entities.playerEntity.stat.maxStamina)
		if levelText:
			levelText.set_text(String.num_int64(Launcher.Entities.playerEntity.stat.level))
		if expText:
			expText.set_text(GetPercentFormat(Launcher.Entities.playerEntity.stat.experience))
