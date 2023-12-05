extends WindowPanel

var platformSection : String					= OS.get_name()
const defaultSection : String					= "Default"
const userSection : String						= "User"

@onready var accessors : Array						= [
	{ "Render-Fullscreen": [init_fullscreen, set_fullscreen, apply_fullscreen, $VBoxContainer/Offset/TabBar/Render/RenderVBox/VisualVBox/Fullscreen],
	"Render-MinWindowSize": [init_minwinsize, set_minwinsize, apply_minwinsize, null] }
]

enum CATEGORY { RENDER, SOUND, COUNT }
enum ACC_TYPE { INIT, SET, APPLY, LABEL }

# FullScreen
func init_fullscreen():
	var pressed : bool = GetVal("Render-Fullscreen")
	accessors[CATEGORY.RENDER]["Render-Fullscreen"][ACC_TYPE.LABEL].set_pressed_no_signal(pressed)
	set_fullscreen(pressed)
func set_fullscreen(pressed : bool):
	SetVal("Render-Fullscreen", pressed)
	apply_fullscreen(pressed)
func apply_fullscreen(pressed : bool):
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if pressed else DisplayServer.WINDOW_MODE_WINDOWED)

# MinWindowSize
func init_minwinsize():
	var minSize : Vector2 = GetVal("Render-MinWindowSize")
	set_minwinsize(minSize)
func set_minwinsize(minSize : Vector2):
	SetVal("Render-MinWindowSize", minSize)
	apply_minwinsize(minSize)
func apply_minwinsize(minSize : Vector2):
	if DisplayServer.get_window_list().size() > 0:
		DisplayServer.window_set_min_size(minSize, DisplayServer.get_window_list()[0])

#
func _on_visibility_changed():
	if Launcher.Action:
		Launcher.Action.Enable(not visible)
	RefreshSettings()

func _ready():
	RefreshSettings()

func _exit_tree():
	SaveSettings()

# Conf accessors
func RefreshSettings():
	for category in accessors:
		for option in category:
			category[option][ACC_TYPE.INIT].call_deferred()

func SaveSettings():
	Launcher.Conf.SaveType("settings", Launcher.Conf.Type.USERSETTINGS)

func SetVal(key : String, value):
	Launcher.Conf.SetValue(userSection, key, Launcher.Conf.Type.USERSETTINGS, value)

func GetVal(key : String):
	var value = Launcher.Conf.GetVariant(userSection, key, Launcher.Conf.Type.USERSETTINGS, null)
	if value == null:
		value = Launcher.Conf.GetVariant(platformSection, key, Launcher.Conf.Type.SETTINGS, null)
	if value == null:
		value = Launcher.Conf.GetVariant(defaultSection, key, Launcher.Conf.Type.SETTINGS, null)

	return value
