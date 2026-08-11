@tool
extends Resource
class_name MapServerData

@export var name : String					= ""
@export var nav_poly : NavigationPolygon	= null
@export var spawns : Array[SpawnObject]		= []
@export var flags : WorldMap.Flags			= WorldMap.Flags.NONE
