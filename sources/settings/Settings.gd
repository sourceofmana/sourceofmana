extends ServiceBase

# TODO: add FileSystem support for personal settings file(s) on user://

var hasUIOverlay : bool			= false

#
func HasUIOverlay() -> bool:
	return hasUIOverlay

func EnableHQ4x():
	Launcher.Root.set_content_scale_factor(2) # [1,2,4] + shader
	Launcher.GUI.HQ4xShader.set_visible(true)

#
func _post_launch():
	match OS.get_name():
		"Android":
			EnableHQ4x()
			Launcher.GUI.shortcuts.add_theme_constant_override("margin_left", 80) # [0;160]
			Launcher.GUI.shortcuts.add_theme_constant_override("margin_right", 80) # [0;160]

			hasUIOverlay = true

	isInitialized = true
