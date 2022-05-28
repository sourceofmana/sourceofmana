extends Node

func SetBoundaries(player):
	if player:
		var playerCamera : Node2D	= player.get_node("PlayerCamera")
		var mapBoundaries : Rect2	= Launcher.Map.GetMapBoundaries()

		playerCamera.limit_left		= mapBoundaries.position.x
		playerCamera.limit_right	= mapBoundaries.end.x
		playerCamera.limit_top		= mapBoundaries.position.y
		playerCamera.limit_bottom	= mapBoundaries.end.y
