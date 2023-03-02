extends Node

#
func Disconnect():
	Launcher.FSM.EnterLogin()

func WarpPlayer(map : String, _rpcID : int = -1):
	if Launcher.Map:
		Launcher.Map.ReplaceMapNode(map)

func AddEntity(agentID : int, entityType : String, entityID : String, entityName : String, entityPos : Vector2i, _rpcID : int = -1):
	Launcher.Map.AddEntity(agentID, entityType, entityID, entityName, entityPos)

func UpdateEntity(ridAgent : int, velocity : Vector2, position : Vector2, isSitting : bool):
		Launcher.Map.UpdateEntity(ridAgent, velocity, position, isSitting)

func RemoveEntity(agentID : int, _rpcID : int = -1):
	Launcher.Map.RemoveEntity(agentID)

func UpdateEntity(ridAgent : int, velocity : Vector2, position : Vector2, isSitting : bool):
		Launcher.Map.UpdateEntity(ridAgent, velocity, position, isSitting)

# Player
func SetVelocity(velocity : Vector2):
	Launcher.Player.SetVelocity(velocity)
