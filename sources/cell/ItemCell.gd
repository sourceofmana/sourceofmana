extends BaseCell
class_name ItemCell

@export var slot : ActorCommons.Slot			= ActorCommons.Slot.NONE
@export var textures : Array[Texture2D]			= []
@export var shader : Resource					= null

#
func _init():
	super._init()
	textures.resize(ActorCommons.Gender.COUNT)
