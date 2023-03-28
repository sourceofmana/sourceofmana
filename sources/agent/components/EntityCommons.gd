extends Object
class_name EntityCommons

#
enum Gender { MALE = 0, FEMALE, NONBINARY, COUNT }
enum State { IDLE = 0, WALK, SIT }

#
static func GetNextState(currentState : State, currentVelocity : Vector2, isSitting : bool):
	var newState : State	= currentState
	var isWalking : bool	= currentVelocity.length_squared() > 1

	match currentState:
		State.IDLE:
			if isWalking:
				newState = State.WALK
			elif isSitting:
				newState = State.SIT
		State.WALK:
			if not isWalking:
				newState = State.IDLE
		State.SIT:
			if not isSitting:
				if isWalking:
					newState = State.WALK
				else:
					newState = State.IDLE

	return newState
