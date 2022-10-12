extends Node

#
var speechInstance : PackedScene	= Launcher.FileSystem.LoadGui("chat/SpeechBubble", false)
var speechContainer : BoxContainer	= null
var emoteSprite : Sprite2D			= null
var emoteTimer : Timer				= null
var speechTimers : Array			= []

var currentEmoteID : int			= -1
var emoteDelay : float				= 0
var speechDelay : float				= 0
var speechDecreaseDelay : float		= 0

#
func AddTimer(parent : Node, delay : float, callable: Callable) -> Timer:
	var timer = Timer.new()
	timer.set_name("Timer")
	parent.add_child(timer)
	timer.start(delay)
	timer.autostart = true
	timer.timeout.connect(callable)
	return timer

#
func RemoveEmoteResources():
	currentEmoteID = -1
	if emoteSprite:
		if emoteTimer:
			emoteTimer.queue_free()
			emoteTimer = null
		if emoteSprite.get_texture() != null:
			emoteSprite.texture = null

func AddEmoteResources(emoteID : int):
	var emoteStringID : String = str(emoteID)
	currentEmoteID = emoteID
	if Launcher.DB.EmotesDB && Launcher.DB.EmotesDB[emoteStringID]:
		var emoteIcon : Resource = Launcher.FileSystem.LoadGfx(Launcher.DB.EmotesDB[emoteStringID]._path)
		if emoteSprite && emoteIcon:
			emoteSprite.set_texture(emoteIcon)
		emoteTimer = AddTimer(emoteSprite, emoteDelay, RemoveEmoteResources)

func DisplayEmote(emoteID : int):
	Launcher.Util.Assert(emoteSprite != null, "No emote sprite found, could not display emote")
	if emoteSprite:
		if currentEmoteID != emoteID:
			RemoveEmoteResources()
			AddEmoteResources(emoteID)
		elif emoteTimer && emoteTimer.get_time_left() > 0:
			emoteTimer.stop()
			emoteTimer.start(emoteDelay)

#
func RemoveSpeechLabel():
	if speechContainer && speechContainer.get_child_count() > 0:
		speechContainer.get_child(0).queue_free()
		speechTimers.pop_back().queue_free()

func AddSpeechLabel(speech : String):
	var speechLabel : RichTextLabel = speechInstance.instantiate()
	speechLabel.append_text("[center]" + speech + "[/center]")
	speechContainer.add_child(speechLabel)
	speechTimers.push_front(AddTimer(speechLabel, speechDelay, RemoveSpeechLabel))

func DisplaySpeech(speech : String):
	Launcher.Util.Assert(speechContainer != null, "No speech container found, could not display speech bubble")
	if speechContainer:
		AddSpeechLabel(speech)

func UpdateDelay():
	if speechDecreaseDelay > 0:
		for speechChild in speechContainer.get_children():
			if speechChild.has_node("Timer"):
				var timeLeft : float = speechChild.get_node("Timer").get_time_left()
				if timeLeft > 0 && timeLeft < speechDecreaseDelay:
					var ratio : float = (timeLeft / speechDecreaseDelay)
					speechChild.modulate.a = ratio
					if timeLeft < speechDecreaseDelay / 2:
						speechChild.visible_ratio = ratio

func UpdateActions():
	if Input.is_action_just_pressed(Actions.ACTION_IM_3): DisplayEmote(3)
	if Input.is_action_just_pressed(Actions.ACTION_IM_5): DisplayEmote(5)
	if Input.is_action_just_pressed(Actions.ACTION_IM_12): DisplayEmote(12)
	if Input.is_action_just_pressed(Actions.ACTION_IM_21): DisplayEmote(21)
	if Input.is_action_just_pressed(Actions.ACTION_IM_22): DisplayEmote(22)
	if Input.is_action_just_pressed(Actions.ACTION_IM_26): DisplayEmote(26)

func Update():
	UpdateDelay()
	UpdateActions()

func EmoteWindowClicked(selectedEmote : String):
	DisplayEmote(selectedEmote.to_int())

func SpeechTextTyped(speech : String):
	DisplaySpeech(speech)

#
func _ready():
	if Launcher.Entities && Launcher.Entities.activePlayer:
		if Launcher.Entities.activePlayer.has_node("Interactions/Emote"):
			emoteSprite = Launcher.Entities.activePlayer.get_node("Interactions/Emote")
		if Launcher.Entities.activePlayer.has_node("Interactions/SpeechContainer"):
			speechContainer = Launcher.Entities.activePlayer.get_node("Interactions/SpeechContainer")

	if Launcher.GUI:
		if Launcher.GUI.emoteList && Launcher.GUI.emoteList.ItemClicked.is_connected(EmoteWindowClicked) == false:
			Launcher.GUI.emoteList.ItemClicked.connect(EmoteWindowClicked)
		if Launcher.GUI.chatContainer && Launcher.GUI.chatContainer.NewTextTyped.is_connected(SpeechTextTyped) == false:
			Launcher.GUI.chatContainer.NewTextTyped.connect(SpeechTextTyped)

	emoteDelay = Launcher.Conf.GetFloat("Gameplay", "emoteDelay", Launcher.Conf.Type.PROJECT)
	speechDelay = Launcher.Conf.GetFloat("Gameplay", "speechDelay", Launcher.Conf.Type.PROJECT)
	speechDecreaseDelay = Launcher.Conf.GetFloat("Gameplay", "speechDecreaseDelay", Launcher.Conf.Type.PROJECT)
