extends Node2D

onready var currentMap		= null
onready var currentPlayer	= load( "res://scenes/Presets/PC.tscn" ).instance()

# Debug
func SetDefaultPlayerPosition() :
	var defaultMap = "res://scenes/Map/012-3-0.tscn"
	var defaultPosition = Vector2( 60, 30 )

	SetPlayerInWorld( defaultMap, defaultPosition )

# Utils	
func SetCameraBoundaries() :
	if currentMap && currentPlayer :
		var playerCamera	= currentPlayer.get_node( "PlayerCamera" )
		var groundLayer		= currentMap.get_node( "Ground/Ground 1" )

		var mapLimits		= groundLayer.get_used_rect()
		var mapCellsize		= groundLayer.cell_size

		playerCamera.limit_left		= mapLimits.position.x * mapCellsize.x
		playerCamera.limit_right	= mapLimits.end.x * mapCellsize.x
		playerCamera.limit_top		= mapLimits.position.y * mapCellsize.y
		playerCamera.limit_bottom	= mapLimits.end.y * mapCellsize.y

func SetPlayerInWorld( map, pos ) :
	currentMap = load( map ).instance()

	if currentPlayer && currentMap :
		currentPlayer.set_position( pos * 32 )

		var fringeSort = currentMap.get_node( "Fringe" )
		fringeSort.add_child( currentPlayer )
		add_child( currentMap )

# Ready
func _ready():
	if currentMap == null :
		SetDefaultPlayerPosition()

	SetCameraBoundaries()
