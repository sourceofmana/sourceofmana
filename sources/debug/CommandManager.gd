extends RefCounted
class_name CommandManager

# Variables
static var commands : Dictionary[StringName, Command]				= {}

# Handling
static func Register(commandName : StringName, callable : Callable, permission : ActorCommons.Permission, description : String):
	assert(not commands.has(commandName), "Command '%s' could not be registered as it is already registered" % commandName)
	commands[commandName] = Command.new(callable, permission, description)

static func Unregister(commandName : StringName):
	assert(commands.has(commandName), "Command '%s' could not be un-registered as it has not been previously registered" % commandName)
	commands.erase(commandName)

static func Handle(caller : PlayerAgent, commandStr : String):
	var args : Array = Parse(commandStr)
	if args.is_empty():
		Network.CommandFeedback("Invalid command sent", caller.peerID)

	var commandName : StringName = args.pop_front().to_lower()
	var command : Command = commands.get(commandName, null)
	var playerPermission : ActorCommons.Permission = Peers.GetPermission(caller.peerID)
	if not command:
		Network.CommandFeedback("Command '%s' is not registered" % commandName, caller.peerID)
	elif not OS.is_debug_build() and command._permission > playerPermission:
		Network.CommandFeedback("Command '%s' could not be called due to unmet permissions" % commandName, caller.peerID)
	else:
		if not args.is_empty() and args[0] == "?":
			Network.CommandFeedback("Command usage: %s" % command._description, caller.peerID)
		elif not command.Call(caller, args):
			Network.CommandFeedback("Command '%s' could not be called due to incorrect arguments" % commandName, caller.peerID)
		else:
			Network.CommandFeedback("Command '%s' sent" % commandName, caller.peerID)

# Utils
static func Parse(command : String) -> Array:
	var tokens : Array = []
	var current : String = ""
	var withinQuotes : bool = false

	for c in command:
		match c:
			'"':
				withinQuotes = !withinQuotes
			' ':
				if withinQuotes:
					current += c
				elif not current.is_empty():
					tokens.append(current)
					current = ""
			_:
				current += c

	if not current.is_empty():
		tokens.append(current)

	return tokens
