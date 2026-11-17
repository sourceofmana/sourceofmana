extends Control

#
const RefreshDelay : float					= 1.0

@onready var tabs : TabContainer			= $HSections
var timer : Timer							= null
var tickCount : int							= 0

#
func RefreshCurrentTab(force : bool):
	var tab : ServerTab = tabs.get_current_tab_control() as ServerTab
	if not tab:
		return

	tickCount += 1
	if not force and tickCount < tab.refreshTicks:
		return
	tickCount = 0

	if tab.CanRefresh():
		tab.Refresh()

func _on_timer_timeout():
	RefreshCurrentTab(false)

func _on_tab_changed(_tab : int):
	RefreshCurrentTab(true)

#
func _ready():
	if DisplayServer.get_name() == "headless":
		return

	tabs.tab_changed.connect(_on_tab_changed)
	timer = Timer.new()
	timer.set_name("ServerTimer")
	add_child(timer)
	Callback.StartTimer(timer, RefreshDelay, _on_timer_timeout)
	RefreshCurrentTab(true)
