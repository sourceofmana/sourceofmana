extends Object
class_name EntityCommons

#
enum Gender
{
	MALE = 0,
	FEMALE,
	NONBINARY,
	COUNT
}

enum State
{
	UNKNOWN = -1,
	IDLE = 0,
	WALK,
	SIT,
	ATTACK,
	DEATH
}

enum Slot
{
	BODY = 0,
	CHEST,
	LEGS,
	FEET,
	HANDS,
	HEAD,
	FACE,
	WEAPON,
	SHIELD,
	COUNT
}

#
const stateTransitions : Array[Array] = [
	#	IDLE			WALK			SIT				ATTACK			DEATH
	[State.IDLE,	State.WALK,		State.SIT,		State.ATTACK,	State.DEATH],	# IDLE
	[State.IDLE,	State.WALK,		State.WALK,		State.ATTACK,	State.DEATH],	# WALK
	[State.SIT,		State.WALK,		State.IDLE,		State.ATTACK,	State.DEATH],	# SIT
	[State.IDLE,	State.WALK,		State.ATTACK,	State.ATTACK,	State.DEATH],	# ATTACK
	[State.DEATH,	State.DEATH,	State.DEATH,	State.DEATH,	State.DEATH]	# DEATH
]

#
static func GetNextTransition(currentState : State, newState : State) -> State:
	return stateTransitions[currentState][newState]

static func GetStateName(state : State):
	var stateName : String = ""
	match state:
		State.IDLE:		stateName = "Idle"
		State.WALK:		stateName = "Walk"
		State.SIT:		stateName = "Sit"
		State.ATTACK:	stateName = "Attack"
		State.DEATH:	stateName = "Death"
		_:				stateName = "Idle"
	return stateName

# Guardband static vars
static var StartGuardbandDist : int				= 0
static var PatchGuardband : int					= 0
static var MaxGuardbandDist : int				= 0

static func InitVars():
	EntityCommons.StartGuardbandDist = Launcher.Conf.GetInt("Guardband", "StartGuardbandDist", Launcher.Conf.Type.NETWORK)
	EntityCommons.PatchGuardband = Launcher.Conf.GetInt("Guardband", "PatchGuardband", Launcher.Conf.Type.NETWORK)
	EntityCommons.MaxGuardbandDist = Launcher.Conf.GetInt("Guardband", "MaxGuardbandDist", Launcher.Conf.Type.NETWORK)
