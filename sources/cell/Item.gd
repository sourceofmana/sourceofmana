extends Object
class_name Item

var cellID : int					= DB.UnknownHash
var cellCustomfield : String		= ""
var count : int						= 0

func _init(_cell : ItemCell, _count : int = 1):
	cellID = _cell.id
	cellCustomfield = _cell.customfield
	count = _count

func Export() -> Dictionary:
	return {
		"item_id": cellID,
		"customfield": cellCustomfield,
		"count": count,
	}
