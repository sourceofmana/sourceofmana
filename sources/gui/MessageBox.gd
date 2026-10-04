extends PanelContainer
class_name MessageBox

#
@onready var label : Label						= $Margin/VBoxContainer/Label
@onready var buttonBox : Control				= $Margin/VBoxContainer/ButtonBoxes

var hasActionLock : bool						= false
var isSuspended : bool							= false
var closeCallback : Callable					= Clear
var previousFocus : Control						= null

#
func Display(text : String, primary = null, primaryText : String = "", cancel = null, cancelText : String = "", secondary = null, secondaryText : String = "", tertiary = null, tertiaryText : String = ""):
	if not hasActionLock:
		previousFocus = get_viewport().gui_get_focus_owner()
	LockActions(true)

	label.set_text(text)
	if primary and primary is Callable:			buttonBox.Bind(UICommons.ButtonBox.PRIMARY, primaryText, Call.bind(primary))
	if cancel and cancel is Callable:			buttonBox.Bind(UICommons.ButtonBox.CANCEL, cancelText, Call.bind(cancel))
	if secondary and secondary is Callable:		buttonBox.Bind(UICommons.ButtonBox.SECONDARY, secondaryText, Call.bind(secondary))
	if tertiary and tertiary is Callable:		buttonBox.Bind(UICommons.ButtonBox.TERTIARY, tertiaryText, Call.bind(tertiary))
	buttonBox.TrapFocus()
	if not isSuspended:
		Show()

func Show():
	set_visible(true)
	buttonBox.Focus.call_deferred(UICommons.ButtonBox.PRIMARY)
	buttonBox.Suggest.call_deferred(UICommons.ButtonBox.PRIMARY)

func Clear():
	LockActions(false)
	isSuspended = false
	closeCallback = Clear

	set_visible(false)
	buttonBox.ReleaseFocus()
	buttonBox.ClearAll()
	label.set_text("")
	RestoreFocus()

func RestoreFocus():
	if is_instance_valid(previousFocus) and previousFocus.is_visible_in_tree():
		previousFocus.grab_focus()
	previousFocus = null

func Suspend():
	isSuspended = true
	set_visible(false)

func Restore():
	isSuspended = false
	if hasActionLock:
		Show()

func LockActions(state : bool):
	if hasActionLock != state:
		hasActionLock = state
		Launcher.Action.Enable(not state)

func Call(callback : Callable):
	Clear()
	callback.call()

#
func _unhandled_input(event : InputEvent):
	if not visible or not Launcher.Action or Launcher.Action.IsEnabled():
		return

	buttonBox.HandleInput(event)

func TryClose() -> bool:
	if not is_visible():
		return false
	if closeCallback.is_valid():
		closeCallback.call()
	return true
