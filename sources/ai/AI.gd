extends Node
class_name AI

static func UpdateWalkPaths(agent : Node2D, map : WorldMap):
	var randAABB : Vector2i = Vector2i(randi_range(30, 200), randi_range(30, 200))
	var newPos : Vector2i = WorldNavigation.GetRandomPositionAABB(map, agent.position, randAABB)
	agent.WalkToward(newPos)

static func Update(agent : BaseAgent, map : WorldMap):
	if not agent.hasCurrentGoal:
		if agent.get_parent() && agent.aiTimer && agent.aiTimer.is_stopped():
			Util.StartTimer(agent.aiTimer, randf_range(5, 15), AI.UpdateWalkPaths.bind(agent, map))
	else:
		if agent.IsStuck():
			agent.ResetNav()
			Util.StartTimer(agent.aiTimer, randf_range(2, 10), AI.UpdateWalkPaths.bind(agent, map))
