extends MessageBox
class_name QuitBox

const QuitText : String = "Any time spent in the real world is less time spent in the mana world!"

#
func Toggle():
	if is_visible():
		Clear()
		Launcher.GUI.messageBox.Restore()
		return

	var quit : Callable = Callable() if LauncherCommons.isWeb else FSM.EnterState.bind(FSM.States.QUIT)
	var logOut : Callable = LogOut if FSM.IsGameState() else Callable()
	if quit.is_valid() or logOut.is_valid():
		Launcher.GUI.messageBox.Suspend()
		Display(QuitText,
			Launcher.GUI.messageBox.Restore, "Stay",
			null, "",
			logOut, "Log Out",
			quit, "Quit")

func LogOut():
	FSM.EnterState(FSM.States.LOGIN_SCREEN)
	Network.DisconnectAccount()
