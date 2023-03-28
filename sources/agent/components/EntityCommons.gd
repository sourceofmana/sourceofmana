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
	IDLE = 0,
	WALK,
	SIT,
	ATTACK,
	DEATH
}

const stateTransitions : Array[Array] = [
	#	IDLE			WALK			SIT				ATTACK			DEATH
	[State.IDLE,	State.WALK,		State.SIT,		State.ATTACK,	State.DEATH],	# IDLE
	[State.IDLE,	State.WALK,		State.WALK,		State.ATTACK,	State.DEATH],	# WALK
	[State.SIT,		State.WALK,		State.IDLE,		State.ATTACK,	State.DEATH],	# SIT
	[State.IDLE,	State.WALK,		State.ATTACK,	State.ATTACK,	State.DEATH],	# ATTACK
	[State.DEATH,	State.DEATH,	State.DEATH,	State.DEATH,	State.DEATH]	# DEATH
]

#
static func UpdateEntityFSM(currentState : State, newState : State) -> State:
	return stateTransitions[currentState][newState]
