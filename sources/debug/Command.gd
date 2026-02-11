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
	var argCount : int = args.size() + _callable.get_bound_arguments_count() + 1
	var minArgCount : int = 0
	var maxArgCount : int = 0
	var obj : Object = _callable.get_object()
	var method_name : String = _callable.get_method()

	for method in obj.get_method_list():
		if method.name == method_name:
			minArgCount = method.default_args.size()
			maxArgCount = method.args.size()
			break

	if _callable and argCount >= minArgCount and argCount <= maxArgCount:
		return _callable.callv([caller] + args)
	return false
