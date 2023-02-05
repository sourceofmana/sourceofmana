extends WindowPanel

@onready var OfflineButton : Button			= $VBoxContainer/GridContainer/Offline
@onready var OnlineButton : Button			= $VBoxContainer/GridContainer/Online
@onready var HostButton : Button			= $VBoxContainer/GridContainer/Host

#
func _on_offline_pressed():
	set_visible(false)
	Launcher.LaunchMode(true, true)

func _on_online_pressed():
	set_visible(false)
	Launcher.LaunchMode(true, false)

func _on_host_pressed():
	set_visible(false)
	Launcher.LaunchMode(false, true)
