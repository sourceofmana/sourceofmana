extends Node

onready var hpStat			= $VBoxMain/HBoxTop/StatIndicator/Bars/HP
onready var manaStat		= $VBoxMain/HBoxTop/StatIndicator/Bars/Mana
onready var staminaStat		= $VBoxMain/HBoxTop/StatIndicator/Bars/Stamina
onready var weightStat		= $FloatingWindows/Inventory/VBoxContainer/Weight/BgTex/Weight

onready var levelText		= $VBoxMain/HBoxTop/StatIndicator/LevelText
onready var expText			= $VBoxMain/HBoxTop/StatIndicator/ExpText

#
func GetPercentFormat(value : int) -> String:
	return "%.2f%%" % [value]

func ToggleControl(control : Control):
	if control:
		control.set_visible(!control.is_visible())

#
func _ready():
	get_tree().set_auto_accept_quit(false)

	if Launcher.Entities.activePlayer:
		assert(hpStat && manaStat && staminaStat, "Stat progress bars are missing")
		assert(weightStat, "Stat inventory weight bar is missing")

		if hpStat:
			hpStat.SetStat(Launcher.Entities.activePlayer.stat.health, Launcher.Entities.activePlayer.stat.maxHealth)
		if manaStat:
			manaStat.SetStat(Launcher.Entities.activePlayer.stat.mana, Launcher.Entities.activePlayer.stat.maxMana)
		if staminaStat:
			staminaStat.SetStat(Launcher.Entities.activePlayer.stat.stamina, Launcher.Entities.activePlayer.stat.maxStamina)
		if weightStat:
			weightStat.SetStat(Launcher.Entities.activePlayer.stat.weight, Launcher.Entities.activePlayer.stat.maxWeight)

		if levelText:
			levelText.set_text(String(Launcher.Entities.activePlayer.stat.level))
		if expText:
			expText.set_text(GetPercentFormat(Launcher.Entities.activePlayer.stat.experience))

func _process(_delta):
	if Input.is_action_just_pressed(Actions.ACTION_UI_QUIT_GAME):
		ToggleControl($NonFloatingWindows/Quit)

	if Input.is_action_just_pressed(Actions.ACTION_UI_INVENTORY):
		ToggleControl($FloatingWindows/Inventory)

func _notification(notif):
	if notif == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		ToggleControl($NonFloatingWindows/Quit)
