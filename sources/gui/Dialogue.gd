extends VBoxContainer

#
@onready var button : TouchScreenButton	= $BottomVbox/Dialogue/Button/TouchButton
@onready var buttonLabel : Label		= $BottomVbox/Dialogue/Button/Label
@onready var scrollable : Scrollable	= $BottomVbox/Dialogue/FixedHBox/Scrollable
@onready var scrollbar: VScrollBar		= $BottomVbox/Dialogue/FixedHBox/Scrollable/Scroll/_v_scroll
var lastName : String					= ""
var lastTween : Tween					= null

const PlayerNameLabel : PackedScene		= preload("res://presets/gui/labels/PlayerNameLabel.tscn")
const NPCNameLabel : PackedScene		= preload("res://presets/gui/labels/NpcNameLabel.tscn")
const PlayerDialogueLabel : PackedScene	= preload("res://presets/gui/labels/PlayerDialogueLabel.tscn")

#
func Toggle(toggle : bool):
	if toggle:
		Launcher.GUI.DisplayInfoContext(["ui_accept", "ui_cancel"])
		Launcher.GUI.dialogueWindow.Clear()
	else:
		Launcher.GUI.infoContext.FadeOut()

	Launcher.GUI.dialogueContainer.set_visible(toggle)

func AddName(text : String):
	if lastName != text:
		lastName = text
		var label : RichTextLabel = PlayerNameLabel.instantiate() if lastName == Launcher.Player.nick else NPCNameLabel.instantiate()
		label.text = "[color=#" + UICommons.LightTextColor.to_html(false) + "]" + lastName + "[/color]"
		scrollable.textContainer.add_child.call_deferred(label)

func AddDialogue(text : String):
	var isPlayer : bool = lastName == Launcher.Player.nick
	var label : RichTextLabel = PlayerDialogueLabel.instantiate() if isPlayer else Scrollable.contentLabel.instantiate()
	label.text = "[color=#" + UICommons.TextColor.to_html(false) + "]" + text + "[/color]"
	scrollable.textContainer.add_child.call_deferred(label)

	if not isPlayer:
		var textSize : int = label.text.length()
		label.visible_characters = 0
		if lastTween:
			lastTween.custom_step(INF)
		lastTween = create_tween()
		lastTween.tween_property(label, "visible_characters", textSize, textSize * UICommons.DialogueTextSpeed)
		lastTween.tween_callback(DialogueDisplayed)

func DialogueDisplayed():
	lastTween = null

func AutoScroll():
	scrollbar.value = scrollbar.max_value

func ToggleButton(enable : bool, text : String):
	if enable and lastTween:
		await lastTween.finished
	button.set_visible(enable)
	buttonLabel.set_text(text)

func ButtonPressed():
	if lastTween:
		lastTween.custom_step(INF)
		return

	if Launcher.Player:
		Network.TriggerNextContext()
	if buttonLabel.text == "Close":
		Launcher.GUI.dialogueContainer.set_visible(false)

func Clear():
	scrollable.Clear()
	lastName = ""
	button.set_visible(false)

func AddChoices(choices : PackedStringArray):
	if lastTween:
		await lastTween.finished

	ToggleButton(false, "")
	Launcher.GUI.choiceContext.Clear()
	if choices.size() > 0:
		Launcher.GUI.choiceContext.Push(ContextData.new("ui_context_validate", choices[0], Network.TriggerChoice.bind(0)))
	if choices.size() > 1:
		Launcher.GUI.choiceContext.Push(ContextData.new("ui_context_cancel", choices[1], Network.TriggerChoice.bind(1)))
	if choices.size() > 2:
		Launcher.GUI.choiceContext.Push(ContextData.new("ui_context_secondary", choices[2], Network.TriggerChoice.bind(2)))
	if choices.size() > 3:
		Launcher.GUI.choiceContext.Push(ContextData.new("ui_context_tertiary", choices[3], Network.TriggerChoice.bind(3)))
	Launcher.GUI.choiceContext.FadeIn(true)

# Overloaded functions
func _ready():
	scrollbar.changed.connect(AutoScroll)

func _input(event : InputEvent):
	if Launcher.GUI and Launcher.GUI.dialogueContainer.is_visible() and not Launcher.GUI.choiceContext.is_visible():
		if Launcher.Action.TryJustPressed(event, "ui_accept", true):
			ButtonPressed()
		if Launcher.Action.TryJustPressed(event, "ui_cancel", true):
			Network.TriggerCloseContext()
