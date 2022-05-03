extends Node2D

const defaultMap			= "res://data/maps/phatina/002-3-1.tmx"
const defaultPosition		= Vector2(70, 40)

# Custom objects
const WarpObject = preload("res://addons/tiled_importer/WarpObject.gd")
const SpawnObject = preload("res://addons/tiled_importer/SpawnObject.gd")

onready var currentMap		= null
onready var currentPlayer	= load("res://scenes/presets/PC.tscn").instance()

# Debug
func SetDebugPlayerPosition():
	SetPlayerInWorld(defaultMap, defaultPosition)

func SetDebugPlayerInventory():
	currentPlayer.inventory.items += Launcher.DB.ItemsDB

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

func SetPlayerInWorld(map, pos):
	if currentMap:
		var fringeSort = currentMap.get_node("Fringe")
		if fringeSort:
			fringeSort.remove_child(currentPlayer)
		remove_child(currentMap)
		currentMap.queue_free()
	currentMap = load(map).instance()
	if currentPlayer && currentMap:
		var fringeSort = currentMap.get_node("Fringe")
		if fringeSort:
			currentPlayer.set_position(pos * fringeSort.cell_size + fringeSort.cell_size / 2)
			fringeSort.add_child(currentPlayer)
			add_child(currentMap)

# Network
func ReturnInventoryList(s_inventoryList):
	print(s_inventoryList)

#
func _ready():
	if currentMap == null:
		SetDebugPlayerPosition()
	SetCameraBoundaries(currentMap, currentPlayer)
	SetDebugPlayerInventory()

func _process(_delta):
	if currentMap.has_node("Object"):
		for child in currentMap.get_node("Object").get_children():
			if child && child is WarpObject:
				var playerPos = currentPlayer.get_global_position()
				var polygonPool = child.get_polygon()
				if Geometry.is_point_in_polygon(playerPos - child.get_position(), polygonPool):
					SetPlayerInWorld("res://data/maps/phatina/" + child.destinationMap + ".tmx", child.destinationPos)
#	if Input.is_action_just_pressed("ui_inventory"):
#		Server.FetchInventoryList("All", get_instance_id())
#		var dialogue_resource = load("res://data/dialogue/Enora.tres")
#		var dialogue = yield(DialogueManager.get_next_dialogue_line("Enora", dialogue_resource), "completed")
#		if dialogue != null:
#			add_child(dialogue)
	pass
