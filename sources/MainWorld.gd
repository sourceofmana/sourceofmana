extends Node2D

onready var currentMap		= null
onready var currentPlayer	= load("res://scenes/Presets/PC.tscn").instance()

# Debug
func SetDefaultPlayerPosition():
	var defaultMap = "res://maps/phatina/002-3-4.tmx"
	var defaultPosition = Vector2(47, 37)
	SetPlayerInWorld(defaultMap, defaultPosition)

# Utils	
func SetCameraBoundaries():
	if currentMap && currentPlayer:
		var playerCamera	= currentPlayer.get_node("PlayerCamera")
		var groundLayer		= currentMap.get_node("Ground 1")

		assert(playerCamera, "Player camera not found")
		assert(groundLayer, "Could not find a ground layer on map: " + currentMap.get_name())

		if groundLayer && playerCamera:
			var mapLimits		= groundLayer.get_used_rect()
			var mapCellsize		= groundLayer.cell_size

			playerCamera.limit_left		= mapLimits.position.x * mapCellsize.x
			playerCamera.limit_right	= mapLimits.end.x * mapCellsize.x
			playerCamera.limit_top		= mapLimits.position.y * mapCellsize.y
			playerCamera.limit_bottom	= mapLimits.end.y * mapCellsize.y

func SetPlayerInWorld(map, pos):
	currentMap = load(map).instance()
	if currentPlayer && currentMap:
		var fringeSort = currentMap.get_node("Fringe")
		if fringeSort:
			currentPlayer.set_position(pos * fringeSort.cell_size)
			fringeSort.add_child(currentPlayer)
			add_child(currentMap)

# Network
func ReturnInventoryList(s_inventoryList):
	print(s_inventoryList)

#
func _ready():
	if currentMap == null:
		SetDefaultPlayerPosition()
	SetCameraBoundaries()

func _process(_delta):
	if Input.is_action_just_pressed("ui_inventory"):
		Server.FetchInventoryList("All", get_instance_id())
