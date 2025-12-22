@tool
extends Resource
class_name MapServerData

@export var name : String					= ""
@export var nav_poly : NavigationPolygon	= null
@export var spawns : Array					= []
@export var warps : Array					= []
@export var ports : Array					= []
@export var flags : WorldMap.Flags			= WorldMap.Flags.NONE
