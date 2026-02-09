extends RefCounted
class_name Command

# Variables
var _description : String 						= ""
var _permission : ActorCommons.Permission		= ActorCommons.Permission.NONE
var _callable : Callable

# Default override
func _init(callable : Callable, permission : ActorCommons.Permission, description : String):
	_callable = callable
	_permission = permission
	_description = description

# Handling
func Call(caller : PlayerAgent, args : Array) -> bool:
	if _callable and _callable.get_argument_count() == args.size() + 1:
		return _callable.callv([caller] + args)
	return false
