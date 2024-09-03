extends PanelContainer

#
@onready var button : TouchScreenButton	= $Button/TouchButton
@onready var buttonLabel : Label		= $Button/Label
@onready var scrollable : Scrollable	= $FixedHBox/Scrollable
@onready var scrollbar: VScrollBar		= $FixedHBox/Scrollable/Scroll/_v_scroll
var lastName : String					= ""

const PlayerNameLabel : PackedScene		= preload("res://presets/gui/labels/PlayerNameLabel.tscn")
const NPCNameLabel : PackedScene		= preload("res://presets/gui/labels/NpcNameLabel.tscn")
const PlayerDialogueLabel : PackedScene	= preload("res://presets/gui/labels/PlayerDialogueLabel.tscn")

#
func AddName(text : String):
	if lastName != text:
		lastName = text
		var label : RichTextLabel = PlayerNameLabel.instantiate() if lastName == Launcher.Player.nick else NPCNameLabel.instantiate()
		label.text = "[color=#" + UICommons.LightTextColor.to_html(false) + "]" + lastName + "[/color]"
		scrollable.textContainer.add_child(label)

func AddDialogue(text : String):
	var label : RichTextLabel = PlayerDialogueLabel.instantiate() if lastName == Launcher.Player.nick else Scrollable.contentLabel.instantiate()
	label.text = "[color=#" + UICommons.TextColor.to_html(false) + "]" + text + "[/color]"
	scrollable.textContainer.add_child(label)

func AutoScroll():
	scrollbar.value = scrollbar.max_value

func ToggleButton(enable : bool, text : String):
	button.set_visible(enable)
	buttonLabel.set_text(text)

func ButtonPressed():
	if Launcher.Player:
		Launcher.Player.Interact()
	if buttonLabel.text == "Close":
		set_visible(false)

func Clear():
	scrollable.Clear()
	lastName = ""
	button.set_visible(false)

# Overloaded functions
func _ready():
	scrollbar.changed.connect(AutoScroll)

func _input(event : InputEvent):
	if is_visible() and not Launcher.GUI.choiceContext.is_visible():
		if Launcher.Action.TryJustPressed(event, "ui_accept", true):
			ButtonPressed()
		if Launcher.Action.TryJustPressed(event, "ui_cancel", true):
			Launcher.Network.TriggerCloseContext()
