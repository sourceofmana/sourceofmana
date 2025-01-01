extends Object
class_name Item

var cell : BaseCell			= null
var count : int				= 0

func _init(_cell : BaseCell, _count : int = 1):
	cell = _cell
	count = _count
