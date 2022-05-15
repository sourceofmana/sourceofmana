extends Node2D

var currentMap				= null
var currentPlayer			= Launcher.FileSystem.LoadScene("presets/PC.tscn")

# Debug
func SetDebugPlayerInventory():
	currentPlayer.inventory.items = Launcher.DB.ItemsDB

# Utils	
func SetCameraBoundaries(map, player):
	if map && player:
		var playerCamera	= player.get_node("PlayerCamera")
		var collisionLayer	= map.get_node("Collision")

		assert(playerCamera, "Player camera not found")
		assert(collisionLayer, "Could not find a collision layer on map: " + currentMap.get_name())

		if collisionLayer && playerCamera:
			var mapLimits		= collisionLayer.get_used_rect()
			var mapCellsize		= collisionLayer.cell_size

			playerCamera.limit_left		= mapLimits.position.x * mapCellsize.x
			playerCamera.limit_right	= mapLimits.end.x * mapCellsize.x
			playerCamera.limit_top		= mapLimits.position.y * mapCellsize.y
			playerCamera.limit_bottom	= mapLimits.end.y * mapCellsize.y

# Network
func ReturnInventoryList(s_inventoryList):
	print(s_inventoryList)

#
func _ready():
	#Move progressively to Launcher.gd
	Launcher.FSM.Login()
	SetCameraBoundaries(currentMap, currentPlayer)
	SetDebugPlayerInventory()

func _process(_delta):
#	if Input.is_action_just_pressed("ui_inventory"):
#		Server.FetchInventoryList("All", get_instance_id())

#		var dialogue_resource = load("res://data/dialogue/Enora.tres")
#		var dialogue = yield(DialogueManager.get_next_dialogue_line("Enora", dialogue_resource), "completed")
#		if dialogue != null:
#			add_child(dialogue)
	pass
