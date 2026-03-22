extends FileData
class_name HairstyleData

@export var _animationOverrides : AnimationLibrary	= null
@export var _spriteHframes : int					= 0
@export var _spriteVframes : int					= 0

#
static func CreateHairstyle(key : String, path : String, overrides : AnimationLibrary = null, hframes : int = 0, vframes : int = 0) -> HairstyleData:
	var data : HairstyleData = HairstyleData.new()
	data._id = key.hash()
	data._name = key
	data._path = path
	data._animationOverrides = overrides
	data._spriteHframes = hframes
	data._spriteVframes = vframes

	return data
