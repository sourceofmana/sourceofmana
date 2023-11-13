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
	DEATH,
	TO_TRIGGER,
	TRIGGER,
	FROM_TRIGGER,
	COUNT
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

static var playbackParameter : String = "parameters/playback"

# Skip TO_TRIGGER & FROM_TRIGGER as they are only used as transition steps between idle/trigger.
const stateTransitions : Array[Array] = [
#	IDLE			WALK			SIT				ATTACK			DEATH			TO_TRIGGER		TRIGGER			FROM_TRIGGER		< To/From v
	[State.IDLE,	State.WALK,		State.SIT,		State.ATTACK,	State.DEATH,	State.IDLE,		State.TRIGGER,	State.IDLE],		# IDLE
	[State.IDLE,	State.WALK,		State.WALK,		State.ATTACK,	State.DEATH,	State.IDLE,		State.TRIGGER,	State.IDLE],		# WALK
	[State.SIT,		State.WALK,		State.IDLE,		State.ATTACK,	State.DEATH,	State.IDLE,		State.TRIGGER,	State.IDLE],		# SIT
	[State.IDLE,	State.WALK,		State.ATTACK,	State.ATTACK,	State.DEATH,	State.IDLE,		State.TRIGGER,	State.IDLE],		# ATTACK
	[State.DEATH,	State.DEATH,	State.DEATH,	State.DEATH,	State.DEATH,	State.DEATH,	State.DEATH,	State.DEATH],		# DEATH
	[],																																	# TO_TRIGGER
	[State.TRIGGER,	State.TRIGGER,	State.SIT,		State.ATTACK,	State.DEATH,	State.TRIGGER,	State.IDLE,		State.TRIGGER],		# TRIGGER
	[]																																	# FROM_TRIGGER
]

#
static func GetNextTransition(currentState : State, newState : State) -> State:
	return stateTransitions[currentState][newState]

static func GetStateName(state : State):
	var stateName : String = ""
	match state:
		State.IDLE:			stateName = "Idle"
		State.WALK:			stateName = "Walk"
		State.SIT:			stateName = "Sit"
		State.ATTACK:		stateName = "Attack"
		State.DEATH:		stateName = "Death"
		State.TO_TRIGGER:	stateName = "To Trigger"
		State.TRIGGER:		stateName = "Trigger"
		State.FROM_TRIGGER:	stateName = "From Trigger"
		_:					stateName = "Idle"
	return stateName

# Guardband static vars
static var StartGuardbandDist : int				= 0
static var PatchGuardband : int					= 0
static var MaxGuardbandDist : int				= 0
static var MaxGuardbandDistVec : Vector2		= Vector2.ZERO

static func InitVars():
	EntityCommons.StartGuardbandDist = Launcher.Conf.GetInt("Guardband", "StartGuardbandDist", Launcher.Conf.Type.NETWORK)
	EntityCommons.PatchGuardband = Launcher.Conf.GetInt("Guardband", "PatchGuardband", Launcher.Conf.Type.NETWORK)
	EntityCommons.MaxGuardbandDist = Launcher.Conf.GetInt("Guardband", "MaxGuardbandDist", Launcher.Conf.Type.NETWORK)
	EntityCommons.MaxGuardbandDistVec = Vector2(EntityCommons.MaxGuardbandDist, EntityCommons.MaxGuardbandDist)
