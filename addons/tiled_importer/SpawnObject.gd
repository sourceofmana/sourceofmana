@tool
extends RefCounted
class_name SpawnObject

@export var count : int 				= 0
@export var id : int					= DB.UnknownHash
@export var nick : String				= ""
@export var type : String				= ""
@export var player_script : String		= ""
@export var own_script : String			= ""
@export var spawn_position : Vector2i	= Vector2i.ZERO
@export var spawn_offset : Vector2i		= Vector2i.ZERO
@export var respawn_delay : float		= 30.0
@export var direction : ActorCommons.Direction	= ActorCommons.Direction.UNKNOWN
@export var state : ActorCommons.State	= ActorCommons.State.UNKNOWN
@export var is_global : bool			= false
@export var is_always_visible : bool	= false
@export var has_trigger : bool			= false
@export var trigger_radius : float		= 0.0

var is_persistant : bool				= false
var map : WorldMap						= null
