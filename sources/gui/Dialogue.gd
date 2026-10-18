extends WindowPanel

#
@onready var button : TouchScreenButton	= $Button/TouchButton
@onready var buttonLabel : Label		= $Button/Label
@onready var scrollable : Scrollable	= $FixedHBox/Scrollable
@onready var scroll : ScrollContainer	= $FixedHBox/Scrollable/Scroll
@onready var scrollMargin : MarginContainer	= $FixedHBox/Scrollable/Scroll/Margin
@onready var scrollbar: VScrollBar		= $FixedHBox/Scrollable/Scroll/_v_scroll

var lastName : String					= ""
var lastTween : Tween					= null
var defaultHeight : float				= 0.0
var autoGrowHeight : float				= 0.0
var autoGrowFloor : float				= 0.0

const PlayerNameLabel : PackedScene		= preload("res://presets/gui/labels/PlayerNameLabel.tscn")
const NPCNameLabel : PackedScene		= preload("res://presets/gui/labels/NpcNameLabel.tscn")
const PlayerDialogueLabel : PackedScene	= preload("res://presets/gui/labels/PlayerDialogueLabel.tscn")

#
func Toggle(toggle : bool):
	if toggle:
		Launcher.GUI.DisplayActions(["ui_accept", "ui_cancel"])
		Clear()
		autoGrowFloor = minf(defaultHeight, autoGrowHeight)
		SetHeight(autoGrowFloor)
	else:
		Launcher.GUI.infoContext.FadeOut()
		Launcher.GUI.choiceContext.FadeOut()

	EnableControl(toggle)

func AddName(text : String):
	if lastName != text and not text.is_empty():
		var newName : bool = not lastName.is_empty()
		lastName = text
		var label : RichTextLabel = PlayerNameLabel.instantiate() if lastName == Launcher.Player.nick else NPCNameLabel.instantiate()
		label.set_text("%s[color=#%s]%s[/color]" % ["\n" if newName else "", UICommons.LightTextColor.to_html(false), lastName])
		scrollable.textContainer.add_child.call_deferred(label)

func AddDialogue(text : String):
	var isPlayer : bool = lastName == Launcher.Player.nick
	var label : RichTextLabel = PlayerDialogueLabel.instantiate() if isPlayer else Scrollable.contentLabel.instantiate()
	label.set_text("[color=#%s]%s[/color]" % [UICommons.TextColor.to_html(false), text])
	scrollable.textContainer.add_child.call_deferred(label)
	if not isPlayer:
		TweenText(label)

func AddThink(text : String):
	var label : RichTextLabel = Scrollable.contentLabel.instantiate()
	label.set_text("[color=#%s]%s[/color]" % [UICommons.WarnTextColor.to_html(false), text])
	label.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER)
	scrollable.textContainer.add_child.call_deferred(label)
	TweenText(label)

func TweenText(label : RichTextLabel):
	var textSize : int = label.get_total_character_count()
	label.visible_characters = 0
	if lastTween:
		lastTween.custom_step(INF)
	lastTween = create_tween()
	lastTween.tween_property(label, "visible_characters", textSize, textSize * UICommons.DialogueTextSpeed)
	lastTween.tween_callback(DialogueDisplayed)

func DialogueDisplayed():
	lastTween = null

func SetHeight(height : float):
	var bottom : float = position.y + size.y
	size.y = height
	position.y = bottom - size.y

func GetPaddingHeight() -> float:
	return get_theme_stylebox("panel").get_minimum_size().y + scrollable.get_theme_stylebox("panel").get_minimum_size().y + scroll.get_theme_stylebox("panel").get_minimum_size().y

func AutoGrow():
	var maxHeight : float = minf(autoGrowHeight, position.y + size.y)
	if maxSize.y != -1:
		maxHeight = minf(maxHeight, maxSize.y)
	var contentHeight : float = scrollMargin.get_combined_minimum_size().y + GetPaddingHeight()
	var height : float = clampf(contentHeight, autoGrowFloor, maxf(autoGrowFloor, maxHeight))
	if not is_equal_approx(height, size.y):
		SetHeight(height)

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
	if buttonLabel.get_text() == "Close":
		set_visible(false)

func Clear():
	scrollable.Clear()
	lastName = ""
	button.set_visible(false)

func AddChoices(choices : PackedStringArray):
	if lastTween:
		await lastTween.finished

	ToggleButton(false, "")
	Launcher.GUI.choiceContext.Clear()

	var choicesCount : int = choices.size()
	if choicesCount > 0:
		Launcher.GUI.choiceContext.Push(ContextData.new("ui_context_validate", choices[0], Network.TriggerChoice.bind(0)))
		if choicesCount > 1:
			Launcher.GUI.choiceContext.Push(ContextData.new("ui_context_cancel", choices[1], Network.TriggerChoice.bind(1)))
		if choicesCount > 2:
			Launcher.GUI.choiceContext.Push(ContextData.new("ui_context_secondary", choices[2], Network.TriggerChoice.bind(2)))
		if choicesCount > 3:
			Launcher.GUI.choiceContext.Push(ContextData.new("ui_context_tertiary", choices[3], Network.TriggerChoice.bind(3)))
		Launcher.GUI.choiceContext.FadeIn(true)

# Overloaded functions
func ResizeWindow(pos : Vector2, globalPos : Vector2):
	super.ResizeWindow(pos, globalPos)
	autoGrowHeight = size.y
	autoGrowFloor = size.y

func _ready():
	defaultHeight = size.y
	autoGrowHeight = defaultHeight
	autoGrowFloor = defaultHeight
	scrollbar.changed.connect(AutoGrow)
	scrollbar.changed.connect(AutoScroll)

func _input(event : InputEvent):
	if Launcher.GUI and Launcher.GUI.IsDialogueContextOpened() and not Launcher.GUI.choiceContext.is_visible():
		if Launcher.Action.TryJustPressed(event, "ui_accept", true):
			ButtonPressed()
		if Launcher.Action.TryJustPressed(event, "ui_cancel", true):
			Network.TriggerCloseContext()
