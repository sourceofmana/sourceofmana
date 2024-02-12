extends WindowPanel

var platformSection : String					= OS.get_name()
const defaultSection : String					= "Default"
const userSection : String						= "User"

@onready var accessors : Array						= [
	{
		"Render-MinWindowSize": [init_minwinsize, set_minwinsize, apply_minwinsize, null],
		"Render-Fullscreen": [init_fullscreen, set_fullscreen, apply_fullscreen, $Margin/TabBar/Render/RenderVBox/VisualVBox/Fullscreen],
		"Render-Scaling": [init_scaling, set_scaling, apply_scaling, $Margin/TabBar/Render/RenderVBox/VisualVBox/Scaling/Option],
		"Render-WindowSize": [init_resolution, set_resolution, apply_resolution, $Margin/TabBar/Render/RenderVBox/VisualVBox/WindowResolution/Option],
		"Render-ActionOverlay": [init_actionoverlay, set_actionoverlay, apply_actionoverlay, $Margin/TabBar/Render/RenderVBox/VisualVBox/ActionOverlay],
		"Render-Lighting": [init_lighting, set_lighting, apply_lighting, $Margin/TabBar/Render/RenderVBox/EffectVBox/Lighting],
		"Render-HQ4x": [init_hq4x, set_hq4x, apply_hq4x, $Margin/TabBar/Render/RenderVBox/EffectVBox/HQx4],
		"Render-CRT": [init_crt, set_crt, apply_crt, $Margin/TabBar/Render/RenderVBox/EffectVBox/CRT],
		"Audio-General": [init_audiogeneral, set_audiogeneral, apply_audiogeneral, $"Margin/TabBar/Audio/VBoxContainer/Global Volume/HSlider"],
		"Session-AccountName": [init_sessionaccountname, set_sessionaccountname, apply_sessionaccountname, null],
		"Session-Overlay": [init_sessionoverlay, set_sessionoverlay, apply_sessionoverlay, null],
	}
]

enum CATEGORY { RENDER, SOUND, COUNT }
enum ACC_TYPE { INIT, SET, APPLY, LABEL }

# MinWindowSize
func init_minwinsize(apply : bool):
	if apply:
		var minSize : Vector2 = GetVal("Render-MinWindowSize")
		apply_minwinsize(minSize)
func set_minwinsize(minSize : Vector2):
	SetVal("Render-MinWindowSize", minSize)
	apply_minwinsize(minSize)
func apply_minwinsize(minSize : Vector2):
	DisplayServer.window_set_min_size(minSize, 0)

# FullScreen
func init_fullscreen(apply : bool):
	var pressed : bool = GetVal("Render-Fullscreen")
	accessors[CATEGORY.RENDER]["Render-Fullscreen"][ACC_TYPE.LABEL].set_pressed_no_signal(pressed)
	if apply:
		apply_fullscreen(pressed)
func set_fullscreen(pressed : bool):
	SetVal("Render-Fullscreen", pressed)
	apply_fullscreen(pressed)
func apply_fullscreen(pressed : bool):
	if pressed:
		apply_resolution(DisplayServer.screen_get_size())
		clear_resolution_labels()
		if DisplayServer.window_get_mode(0) != DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		populate_resolution_labels(DisplayServer.screen_get_size())
		if DisplayServer.window_get_mode(0) == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

# Window Resolution
const resolutionEntriesCount : int = 5
func init_resolution(apply : bool):
	var resolution : Vector2i = GetVal("Render-WindowSize")
	populate_resolution_labels(resolution)
	if apply:
		apply_resolution(resolution)
func clear_resolution_labels():
	accessors[CATEGORY.RENDER]["Render-WindowSize"][ACC_TYPE.LABEL].clear()
func populate_resolution_labels(resolution : Vector2i):
	clear_resolution_labels()
	if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN:
		var minScreenSize : Vector2i = GetVal("Render-MinWindowSize")
		var maxScreenSize : Vector2i = DisplayServer.screen_get_size()
		var label : OptionButton = accessors[CATEGORY.RENDER]["Render-WindowSize"][ACC_TYPE.LABEL]
		for i in range(0, resolutionEntriesCount):
			var item : Vector2i = calculate_resolution(i, minScreenSize, maxScreenSize)
			label.add_item(str(item))
		label.add_separator()
		label.add_item(str(resolution))
		label.selected = label.item_count - 1
func calculate_resolution(index : int, minScreenSize : Vector2, maxScreenSize : Vector2) -> Vector2i:
	return lerp(minScreenSize, maxScreenSize, index / maxf(resolutionEntriesCount - 1, 1.0))
func set_resolutionIdx(resolutionIdx : int):
	var minScreenSize : Vector2i = GetVal("Render-MinWindowSize")
	var maxScreenSize : Vector2i = DisplayServer.screen_get_size()
	var resolution : Vector2i = calculate_resolution(resolutionIdx, minScreenSize, maxScreenSize)
	set_resolution(resolution)
func set_resolution(resolution : Vector2i):
	SetVal("Render-WindowSize", resolution)
	apply_resolution(resolution)
func apply_resolution(resolution : Vector2i):
	var windowSize : Vector2i = DisplayServer.screen_get_size()
	var minScreenSize : Vector2i = DisplayServer.window_get_min_size()

	var newSize : Vector2i = clamp(resolution, minScreenSize, windowSize)
	var currentPos : Vector2i = get_viewport().get_position()
	var newPosition : Vector2i = Vector2i(clampi(currentPos.x, 0, (windowSize - resolution).x), clampi(currentPos.y, 0, (windowSize - resolution).y))
	DisplayServer.window_set_size(newSize)
	DisplayServer.window_set_position(newPosition)
	init_actionoverlay(true)
	populate_resolution_labels(resolution)

# DoubleResolution
func init_scaling(apply : bool):
	var mode : int = GetVal("Render-Scaling")
	accessors[CATEGORY.RENDER]["Render-Scaling"][ACC_TYPE.LABEL].selected = mode
	if apply:
		apply_scaling(mode)
func set_scaling(mode : int):
	SetVal("Render-Scaling", mode)
	apply_scaling(mode)
func apply_scaling(mode : int):
	Launcher.Root.set_content_scale_factor(mode + 1)
	init_actionoverlay(true)

# ActionOverlay
func init_actionoverlay(apply : bool):
	var enable : bool = GetVal("Render-ActionOverlay")
	accessors[CATEGORY.RENDER]["Render-ActionOverlay"][ACC_TYPE.LABEL].set_pressed_no_signal(enable)
	if apply:
		apply_actionoverlay(enable)
func set_actionoverlay(enable : bool):
	SetVal("Render-ActionOverlay", enable)
	apply_actionoverlay(enable)
func apply_actionoverlay(enable : bool):
	if Launcher.GUI:
		if enable:
			Launcher.GUI.shortcuts.add_theme_constant_override("margin_left", 80) # [0;160]
			Launcher.GUI.shortcuts.add_theme_constant_override("margin_right", 80) # [0;160]
			Launcher.GUI.sticks.set_visible(true)
			Launcher.GUI.boxes.set_visible(false)
			Launcher.Action.supportMouse = false
		else:
			Launcher.GUI.shortcuts.add_theme_constant_override("margin_left", 0) # [0;160]
			Launcher.GUI.shortcuts.add_theme_constant_override("margin_right", 0) # [0;160]
			Launcher.GUI.sticks.set_visible(false)
			Launcher.GUI.boxes.set_visible(true)
			Launcher.Action.supportMouse = true

# Lighting
func init_lighting(apply : bool):
	var enable : bool = GetVal("Render-Lighting")
	accessors[CATEGORY.RENDER]["Render-Lighting"][ACC_TYPE.LABEL].set_pressed_no_signal(enable)
	if apply:
		apply_lighting(enable)
func set_lighting(enable : bool):
	SetVal("Render-Lighting", enable)
	apply_lighting(enable)
func apply_lighting(enable : bool):
	Effects.EnableLighting(enable)

# HQ4x
func init_hq4x(apply : bool):
	var enable : bool = GetVal("Render-HQ4x")
	accessors[CATEGORY.RENDER]["Render-HQ4x"][ACC_TYPE.LABEL].set_pressed_no_signal(enable)
	if apply:
		apply_hq4x(enable)
func set_hq4x(enable : bool):
	SetVal("Render-HQ4x", enable)
	apply_hq4x(enable)
func apply_hq4x(enable : bool):
	Launcher.GUI.HQ4xShader.set_visible(enable)

# CRT
func init_crt(apply : bool):
	var enable : bool = GetVal("Render-CRT")
	accessors[CATEGORY.RENDER]["Render-CRT"][ACC_TYPE.LABEL].set_pressed_no_signal(enable)
	if apply:
		apply_crt(enable)
func set_crt(enable : bool):
	SetVal("Render-CRT", enable)
	apply_crt(enable)
func apply_crt(enable : bool):
	Launcher.GUI.CRTShader.set_visible(enable)

# Audio General
func init_audiogeneral(apply : bool):
	var volumeRatio : float = GetVal("Audio-General")
	accessors[CATEGORY.RENDER]["Audio-General"][ACC_TYPE.LABEL].value = volumeRatio
	if apply:
		apply_audiogeneral(volumeRatio)
func set_audiogeneral(volumeRatio : float):
	SetVal("Audio-General", volumeRatio)
	apply_audiogeneral(volumeRatio)
func apply_audiogeneral(volumeRatio : float):
	if Launcher.Audio:
		var interpolation : float = clamp((log(clampf(volumeRatio, 0.0, 1.0)) + 5.0) / 5.0, 0.0, 1.06)
		Launcher.Audio.SetVolume((1.0 - interpolation) * -80.0)

# Session Account Name
func init_sessionaccountname(apply : bool):
	if apply:
		var accountName : String = GetVal("Session-AccountName")
		apply_sessionaccountname(accountName)
func set_sessionaccountname(accountName : String):
	SetVal("Session-AccountName", accountName)
	apply_sessionaccountname(accountName)
func apply_sessionaccountname(accountName : String):
	if Launcher.GUI and Launcher.GUI.loginWindow:
		Launcher.GUI.loginWindow.nameTextControl.set_text(accountName)

# Session Windows Overlay placement
enum ESessionOverlay { NAME = 0, POSITION, SIZE, COUNT}
func init_sessionoverlay(apply : bool):
	if apply:
		var overlay : Array = GetVal("Session-Overlay")
		apply_sessionoverlay(overlay)
func save_sessionoverlay():
	var overlay : Array = []
	if Launcher.GUI and Launcher.GUI.windows:
		for window in Launcher.GUI.windows.get_children():
			if window.is_visible() and not window.blockActions:
				overlay.append([window.get_name().get_file(), window.get_position(), window.get_size()])
		set_sessionoverlay(overlay)
func set_sessionoverlay(overlay : Array):
	SetVal("Session-Overlay", overlay)
	apply_sessionoverlay(overlay)
func apply_sessionoverlay(overlay : Array):
	if Launcher.GUI and Launcher.GUI.windows:
		for window in overlay:
			if window.size() >= ESessionOverlay.COUNT:
				var floatingWindow : WindowPanel = Launcher.GUI.windows.get_node(window[ESessionOverlay.NAME])
				if floatingWindow:
					floatingWindow.set_visible(true)
					floatingWindow.set_size(window[ESessionOverlay.SIZE])
					floatingWindow.set_position(window[ESessionOverlay.POSITION])
					floatingWindow.UpdateWindow()

#
func _on_visibility_changed():
	if Launcher.Action:
		Launcher.Action.Enable(not visible)
	RefreshSettings(false)

func _ready():
	RefreshSettings(true)
	Launcher.FSM.enter_game.connect(RefreshSettings.bind(true))

	if OS.get_name() == "Android" or OS.get_name() == "iOS" or OS.get_name() == "Web":
		accessors[CATEGORY.RENDER]["Render-WindowSize"][ACC_TYPE.LABEL].get_parent().set_visible(false)
		accessors[CATEGORY.RENDER]["Render-Fullscreen"][ACC_TYPE.LABEL].set_visible(false)

func _exit_tree():
	save_sessionoverlay()
	SaveSettings()

# Conf accessors
func RefreshSettings(apply : bool):
	for category in accessors:
		for option in category:
			category[option][ACC_TYPE.INIT].call_deferred(apply)

func SaveSettings():
	Conf.SaveType("settings", Conf.Type.USERSETTINGS)

func SetVal(key : String, value):
	Conf.SetValue(userSection, key, Conf.Type.USERSETTINGS, value)

func GetVal(key : String):
	var value = Conf.GetVariant(userSection, key, Conf.Type.USERSETTINGS, null)
	if value == null:
		value = Conf.GetVariant(platformSection, key, Conf.Type.SETTINGS, null)
	if value == null:
		value = Conf.GetVariant(defaultSection, key, Conf.Type.SETTINGS, null)

	return value
