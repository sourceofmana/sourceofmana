extends Label

# TODO: add a GUI to display various server stats
func _ready():
	if !OS.has_feature("editor"):
		set_text("Server mode started, to hide this window run this binary from the terminal as follows: " + OS.get_executable_path() + " --headless --server")
	else:
		set_text("Running in the Godot editor, so this window can not be hidden. Only exported projects can use --headless.")
