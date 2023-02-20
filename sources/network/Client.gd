extends Node

#
func Disconnect():
	Launcher.FSM.EnterLogin()

func SetPlayerInWorld(map : String, _rpcID : int = -1):
	if Launcher.Map:
		Launcher.Map.ReplaceMapNode(map)

		if Launcher.FSM:
			Launcher.FSM.emit_signal("enter_game")

func GetAgents(mapName : String):
	if Launcher.Network.Server:
		Launcher.Network.Server.GetAgents(mapName, Launcher.FSM.playerName)

func SetAgents(agents : Array[BaseAgent]):
	for agent in agents:
		Launcher.Map.AddEntity(agent.get_rid().get_id(), agent.agentType, agent.agentID, agent.agentName, agent.position)

func UpdateEntity(ridAgent : int, velocity : Vector2, position : Vector2):
		Launcher.Map.UpdateEntity(ridAgent, velocity, position)

# Player
func SetWarp(oldMapName : String, newMapName : String, newPos : Vector2i):
	if Launcher.Network.Server:
		Launcher.Network.Server.SetWarp(Launcher.Player.entityName, oldMapName, newMapName, newPos)

func SetVelocity(velocity : Vector2):
	Launcher.Player.SetVelocity(velocity)

func SetClickPos(pos : Vector2):
	if Launcher.Network.Server:
		Launcher.Network.Server.SetClickPos(pos)

func SetMovePos(pos : Vector2, delta : float):
	if Launcher.Network.Server:
		Launcher.Network.Server.SetMovePos(pos, delta)
