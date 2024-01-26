extends Object
class_name AI

#
const minDistance : int = 30
const maxDistance : int = 200

const minWalkTimer : int = 5
const maxWalkTimer : int = 20

const minUnstuckTimer : int = 2
const maxUnstuckTimer : int = 10

#
static func GetOffset() -> Vector2i:
	return Vector2i(
		randi_range(minDistance, maxDistance),
		randi_range(minDistance, maxDistance))
static func GetWalkTimer() -> float:
	return randf_range(minWalkTimer, maxWalkTimer)
static func GetUnstuckTimer() -> float:
	return randf_range(minUnstuckTimer, maxUnstuckTimer)
static func IsStuck(agent : BaseAgent) -> bool:
	return agent.lastPositions.size() >= 5 and Vector2i(agent.lastPositions[0] - agent.lastPositions[4]).length_squared() < 1

#
static func RandomWalk(agent : Node2D, map : WorldMap):
	var position : Vector2i = WorldNavigation.GetRandomPositionAABB(map, agent.position, GetOffset())
	agent.WalkToward(position)

static func Update(agent : BaseAgent, map : WorldMap):
	if not agent.hasCurrentGoal:
		if agent.get_parent() && agent.aiTimer && agent.aiTimer.is_stopped():
			Util.StartTimer(agent.aiTimer, GetWalkTimer(), AI.RandomWalk.bind(agent, map))
	else:
		if IsStuck(agent):
			agent.ResetNav()
			Util.StartTimer(agent.aiTimer, GetUnstuckTimer(), AI.RandomWalk.bind(agent, map))
