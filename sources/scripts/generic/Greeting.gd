extends NpcScript

#
func OnStart():
	Greeting()
	AddTimer(own, 1.0, Callable())
