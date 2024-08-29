extends PanelContainer

#
@onready var button : Button			= $Button
@onready var scrollable : Scrollable	= $FixedHBox/Scrollable
@onready var scrollbar: VScrollBar		= $FixedHBox/Scrollable/Scroll/_v_scroll
var lastName : String					= ""

#
func AddName(text : String):
	if lastName != text:
		lastName = text
		var label : RichTextLabel = Scrollable.titleLabel.instantiate()
		label.text = "[color=#" + UICommons.LightTextColor.to_html(false) + "]" + text + "[/color]"
		scrollable.textContainer.add_child(label)

func AddDialogue(text : String):
	var label : RichTextLabel = Scrollable.contentLabel.instantiate()
	label.text = "[color=#" + UICommons.TextColor.to_html(false) + "]\t" + text + "[/color]"
	scrollable.textContainer.add_child(label)

func AutoScroll():
	scrollbar.value = scrollbar.max_value

func ToggleButton(enable : bool, text : String):
	button.set_visible(enable)
	button.set_text(text)

func ButtonPressed():
	if Launcher.Player:
		Launcher.Player.Interact()
	if button.text == "Close":
		set_visible(false)
#	ToggleButton(false, "")

func Clear():
	scrollable.Clear()
	lastName = ""
	button.set_visible(false)

# Overloaded functions
func _ready():
	scrollbar.changed.connect(AutoScroll)

func _input(event : InputEvent):
	if is_visible():
		if Launcher.Action.TryJustPressed(event, "ui_accept", true):
			ButtonPressed()
		if Launcher.Action.TryJustPressed(event, "ui_cancel", true):
			Launcher.Network.TriggerCloseContext()
