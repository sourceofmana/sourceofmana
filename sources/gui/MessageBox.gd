extends PanelContainer

#
@onready var label : Label						= $Margin/VBoxContainer/Label
@onready var buttonBox : Control				= $Margin/VBoxContainer/ButtonBoxes

var wasActionEnabled : bool						= true

#
func Display(text : String, primary = null, primaryText : String = "", cancel = null, cancelText : String = "", secondary = null, secondaryText : String = "", tertiary = null, tertiaryText : String = ""):
	wasActionEnabled = Launcher.Action.IsEnabled()
	if wasActionEnabled:
		Launcher.Action.Enable(false)

	label.set_text(text)
	if primary and primary is Callable:			buttonBox.Bind(UICommons.ButtonBox.PRIMARY, primaryText, Call.bind(primary))
	if cancel and cancel is Callable:			buttonBox.Bind(UICommons.ButtonBox.CANCEL, cancelText, Call.bind(cancel))
	if secondary and secondary is Callable:		buttonBox.Bind(UICommons.ButtonBox.SECONDARY, secondaryText, Call.bind(secondary))
	if tertiary and tertiary is Callable:		buttonBox.Bind(UICommons.ButtonBox.TERTIARY, tertiaryText, Call.bind(tertiary))
	set_visible(true)

func Clear():
	if  wasActionEnabled:
		Launcher.Action.Enable(true)

	set_visible(false)
	buttonBox.ClearAll()
	label.set_text("")

func Call(callback : Callable):
	Clear()
	callback.call()

#
func _unhandled_input(event : InputEvent):
	if not visible or Launcher.Action.IsEnabled():
		return

	buttonBox.HandleInput(event)
