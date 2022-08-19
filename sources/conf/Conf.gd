extends Node


enum Type \
{ \
	NONE = -1, \
	PROJECT = 0, \
	MAP, \
	WINDOW \
}

var ConfHandler				= null

#
func GetVariant(category : String, param : String, type : int, default):
	var ret = default
	if ConfHandler:
		ret = ConfHandler.GetValue(category, param, type, default)
	return ret

func GetBool(category : String, param : String, type : int = Type.NONE) -> bool:
	return GetVariant(category, param, type, false)

func GetInt(category : String, param : String, type : int = Type.NONE) -> int:
	return GetVariant(category, param, type, 0)

func GetFloat(category : String, param : String, type : int = Type.NONE) -> float:
	return GetVariant(category, param, type, 0.0)

func GetVector2(category : String, param : String, type : int = Type.NONE) -> Vector2:
	return GetVariant(category, param, type, Vector2.ZERO)

func GetString(category : String, param : String, type : int = Type.NONE) -> String:
	return GetVariant(category, param, type, "")

#
func _init():
	notification(NOTIFICATION_READY) 

func _ready():
	ConfHandler = Launcher.FileSystem.LoadSource("conf/ConfHandler.gd")

func _post_ready():
	DisplayServer.window_set_min_size(GetVector2("PresetPC", "minWindowSize", Type.WINDOW), DisplayServer.get_window_list()[0])
