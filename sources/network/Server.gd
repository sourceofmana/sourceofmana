extends Node

var playerMap : Dictionary = {}

#
func ConnectPlayer(playerName : String, rpcID : int = -1):
	if not playerMap.has(rpcID):

		if not Launcher.World.HasAgent(playerName):
			var player : BaseAgent = Launcher.DB.Instantiate.CreateAgent("Player", "Default Entity", playerName)
			var map : String	= Launcher.Conf.GetString("Default", "startMap", Launcher.Conf.Type.MAP)
			player.set_position(Launcher.Conf.GetVector2i("Default", "startPos", Launcher.Conf.Type.MAP))

			playerMap[rpcID] = player.get_rid().get_id()
			Launcher.World.Spawn(map, player)
			Launcher.Network.SetPlayerInWorld(map, rpcID)

func DisconnectPlayer(playerName : String, rpcID : int = -1):
	if playerMap.has(rpcID):
		playerMap.erase(rpcID)
		Launcher.World.RemoveEntity(playerName)

#
func GetAgents(mapName : String, entityName : String):
	var agents : Array[BaseAgent] = Launcher.World.GetAgents(mapName, entityName)
	Launcher.Network.Client.SetAgents(agents)

func SetWarp(entityName : String, oldMapName : String, newMapName : String, newPos : Vector2i):
	Launcher.World.Warp(entityName, oldMapName, newMapName, newPos)

func UpdatePlayerInput(currentInput : Vector2, deltaTime : float, rpcID : int = -1):
	var velocity : Vector2	= Vector2.ZERO
	var agent : BaseAgent	= Launcher.World.GetAgent(rpcID)
	if agent:
		if currentInput != Vector2.ZERO:
			var normalizedInput : Vector2 = currentInput.normalized()
			velocity = agent.velocity.move_toward(normalizedInput * agent.stat.moveSpeed, agent.stat.moveAcceleration * deltaTime)
		else:
			velocity = agent.velocity.move_toward(Vector2.ZERO, agent.stat.moveFriction * deltaTime)
	Launcher.Network.Client.SetVelocity(velocity)

func UpdateEntity(_playerID : int, agentID : int, velocity : Vector2, position : Vector2):
	Launcher.Network.Client.UpdateEntity(agentID, velocity, position)

#
func ConnectPeer(id : int):
	Launcher.Util.PrintLog("[Server] Peer connected: %s" % id)

func DisconnectPeer(id : int):
	Launcher.Util.PrintLog("[Server] Peer disconnected: %s" % id)
