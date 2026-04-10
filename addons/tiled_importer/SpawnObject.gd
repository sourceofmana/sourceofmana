@tool
extends Resource
class_name SpawnObject

#
@export var count : int 				= 1
@export var id : int					= DB.UnknownHash
@export var nick : String				= ""
@export var type : String				= ""
@export var player_script : String		= ""
@export var own_script : String			= ""
@export var spawn_position : Vector2i	= Vector2i.ZERO
@export var spawn_offset : Vector2i		= Vector2i.ZERO
@export var respawn_delay : float		= 30.0
@export var is_persistant : bool		= false
@export_category("Visual")
@export var direction : ActorCommons.Direction	= ActorCommons.Direction.UNKNOWN
@export var state : ActorCommons.State	= ActorCommons.State.UNKNOWN
@export var is_global : bool			= false
@export var is_always_visible : bool	= false
@export_category("Area")
@export var trigger_radius : float		= 0.0
@export var trigger_polygon : PackedVector2Array	= []
@export_category("Warp")
@export var destination_map : int		= DB.UnknownHash
@export var destination_pos : Vector2	= Vector2.ZERO
@export var auto_warp : bool			= true
@export var sailing_pos : Vector2		= Vector2.ZERO

#
var map : WorldMap						= null
