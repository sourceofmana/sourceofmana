extends Label

# Called when the node enters the scene tree for the first time.
func _ready():
	if !OS.has_feature("editor"):
		set_text("Server mode started, to hide this window run this binary from the terminal as follows: " + OS.get_executable_path() + " --headless --server")
	else:
		set_text("Running in the Godot editor, so this window can not be hidden. Only exported projects can use --headless.")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
