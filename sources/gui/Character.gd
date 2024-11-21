extends WindowPanel

#
@onready var warningLabel : RichTextLabel	= $Margin/VBoxContainer/Warning

#
func FillWarningLabel(err : NetworkCommons.CharacterError):
	var warn : String = ""
	match err:
		NetworkCommons.CharacterError.ERR_OK:
			warn = ""
		NetworkCommons.CharacterError.ERR_ALREADY_LOGGED_IN:
			warn = "Character is already logged in."
		NetworkCommons.CharacterError.ERR_TIMEOUT:
			warn = "Could not connect to the server (Error %d)." % err
		NetworkCommons.CharacterError.ERR_MISSING_PARAMS:
			warn = "Some character information are missing."
		NetworkCommons.CharacterError.ERR_NAME_AVAILABLE:
			warn = "Character name not available."
		NetworkCommons.CharacterError.ERR_NAME_VALID:
			warn = "Name should should only include alpha-numeric characters and symbols."
		NetworkCommons.CharacterError.ERR_NAME_SIZE:
			warn = "Name length should be inbetween %d and %d character long." % [NetworkCommons.PlayerNameMinSize, NetworkCommons.PlayerNameMaxSize]
		_:
			warn = "Unknown character issue (Error %d).\nPlease contact us via our [url=%s][color=#%s]Discord server[/color][/url].\n" % [err, LauncherCommons.SocialLink, UICommons.DarkTextColor]

	if not warn.is_empty():
		warn = "[color=#%s]%s[/color]" % [UICommons.WarnTextColor.to_html(false), warn]
	warningLabel.set_text(warn)

#
func AddCharacter(info : Dictionary):
	if "nickname" not in info or "level" not in info:
		assert(false, "Missing character information")
	else:
		Util.PrintLog("Character", "Character: %s (Level %d)" % [info["nickname"], info["level"]])

#
func _ready():
	FillWarningLabel(NetworkCommons.CharacterError.ERR_OK)
