extends Node
class_name AI

static func UpdateWalkPaths(agent : Node2D, map : World.Map):
	var randAABB : Vector2i = Vector2i(randi_range(30, 200), randi_range(30, 200))
	var newPos : Vector2i = WorldNavigation.GetRandomPositionAABB(map, agent.position, randAABB)
	agent.WalkToward(newPos)

static func Update(agent : BaseAgent, map : World.Map):
	if not agent.hasCurrentGoal:
		if agent.aiTimer && agent.aiTimer.is_stopped():
			Util.StartTimer(agent.aiTimer, randf_range(5, 15), AI.UpdateWalkPaths.bind(agent, map))
	else:
		if agent.IsStuck():
			agent.ResetNav()
			Util.StartTimer(agent.aiTimer, randf_range(2, 10), AI.UpdateWalkPaths.bind(agent, map))
