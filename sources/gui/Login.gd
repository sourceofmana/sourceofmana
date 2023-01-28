extends WindowPanel

#
func _on_sign_in_pressed():
	SetFloatingWindowToTop()
	Launcher.GUI.CloseCurrentWindow()
	Launcher.FSM.ExitLogin()
