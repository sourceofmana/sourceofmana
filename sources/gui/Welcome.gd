extends WindowPanel

@onready var welcomeTextLabel : RichTextLabel	= $Scroll/Margin/VBox/WelcomeText

#
func _ready():
	var welcomeFilePath : String = Launcher.Conf.GetString("Default", "welcomeFilePath", Launcher.Conf.Type.PROJECT)
	var content : String = Launcher.FileSystem.LoadFile(welcomeFilePath)
	welcomeTextLabel.set_text(content)
