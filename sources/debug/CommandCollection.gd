extends RefCounted
class_name CommandCollection

# Catch initialization of the ref counted object
func _init():
	RegisterCommands()

# Catch destruction of the ref counted object
func _notification(what):
	match what:
		NOTIFICATION_PREDELETE:
			UnregisterCommands()

# Dummy registration to be overridden by new collection files
func RegisterCommands():
	pass

# Dummy unregistration to be overridden by new collection files
static func UnregisterCommands():
	pass
