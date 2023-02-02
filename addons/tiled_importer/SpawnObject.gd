@tool
extends Object

class_name SpawnObject

@export var count : int 				= 0
@export var name : String				= ""
@export var type : String				= ""
@export var spawn_position : Vector2i	= Vector2i.ZERO
@export var spawn_offset : Vector2i		= Vector2i.ZERO
@export var is_global : bool			= false
