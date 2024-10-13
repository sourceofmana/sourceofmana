@tool
extends Node

class_name MapServerData

@export var nav_poly : NavigationPolygon	= null
@export var spawns : Array					= []
@export var warps : Array					= []
@export var ports : Array					= []
@export var flags : WorldMap.Flags			= WorldMap.Flags.NONE
