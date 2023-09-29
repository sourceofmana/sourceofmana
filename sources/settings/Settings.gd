extends ServiceBase

# TODO: add FileSystem support for personal settings file(s) on user://

#
func _post_launch():
	match OS.get_name():
		"Android":
			Launcher.Root.set_content_scale_factor(2)

	isInitialized = true
