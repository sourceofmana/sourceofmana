extends Node2D
class_name EntityInteractive

#
var speechInstance : PackedScene	= FileSystem.LoadGui("chat/SpeechBubble", false)

@onready var visibleNode : Node2D			= $Visible
@onready var generalVBox : BoxContainer		= $Visible/VBox
@onready var speechContainer : BoxContainer	= $Visible/VBox/Panel/SpeechContainer
@onready var emoteSprite : TextureRect		= $Visible/VBox/Emote
@onready var morphFx : CPUParticles2D		= $MorphParticles
@onready var nameLabel : Label				= $Name
@onready var triggerArea : Area2D			= $Area

var emoteTimer : Timer				= null
var morphTimer : Timer				= null
var speechTimers : Array[Timer]		= []

var currentEmoteID : int			= -1
var emoteDelay : float				= 0
var morphDelay : float				= 0
var speechDelay : float				= 0
var speechDecreaseDelay : float		= 0
var speechIncreaseThreshold : int	= 0
var speechMaxWidth : int			= 0
var speechExtraWidth : int			= 0

var canInteractWith : Array[BaseEntity]			= []

#
func AddTimer(parent : Node, delay : float, callable: Callable) -> Timer:
	var timer = Timer.new()
	timer.set_name("InteractiveTimer")
	timer.set_one_shot(true)
	timer.set_autostart(true)
	timer.set_wait_time(delay)
	timer.timeout.connect(callable)
	parent.add_child.call_deferred(timer)
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
		var emoteIcon : Texture2D = FileSystem.LoadGfx(Launcher.DB.EmotesDB[emoteStringID]._path)
		if emoteSprite && emoteIcon:
			emoteSprite.set_texture(emoteIcon)
		emoteTimer = AddTimer(emoteSprite, emoteDelay, RemoveEmoteResources)

func DisplayEmote(emoteID : int):
	Util.Assert(emoteSprite != null, "No emote sprite found, could not display emote")
	if emoteSprite:
		if currentEmoteID != emoteID:
			RemoveEmoteResources()
			AddEmoteResources(emoteID)
		elif emoteTimer && emoteTimer.get_time_left() > 0:
			emoteTimer.stop()
			emoteTimer.start(emoteDelay)

func EmoteWindowClicked(selectedEmote : String):
	DisplayEmote(selectedEmote.to_int())

#
func RemoveMorphResource():
	if morphTimer != null:
		morphTimer.queue_free()
		morphTimer = null

func DisplayMorph(callback : Callable):
	Util.Assert(morphFx != null, "No emote sprite found, could not display emote")
	if morphFx:
		morphFx.restart()
		morphFx.emitting = true
		RemoveMorphResource()
		morphTimer = AddTimer(morphFx, morphDelay, callback)

#
func RemoveSpeechLabel():
	if speechContainer && speechContainer.get_child_count() > 0:
		speechContainer.get_child(0).queue_free()
		speechTimers.pop_back().queue_free()

func DisplaySpeech(speech : String):
	Util.Assert(speechContainer != null, "No speech container found, could not display speech bubble")
	if speechContainer:
		var speechLabel : RichTextLabel = speechInstance.instantiate()
		speechLabel.set_text("[center]%s[/center]" % [speech])
		speechLabel.set_visible_ratio(0)
		speechContainer.add_child(speechLabel)
		speechTimers.push_front(AddTimer(speechLabel, speechDelay, RemoveSpeechLabel))

#
func DisplayDamage(target : BaseEntity, dealer : BaseEntity, damage : int, isCrit : bool = false):
	if Launcher.Map.mapNode:
		var newLabel : Label = EntityCommons.DamageLabel.instantiate()
		newLabel.SetPosition(visibleNode.get_global_position(), target.get_global_position())
		newLabel.SetDamage(damage, target == Launcher.Player, dealer == Launcher.Player, isCrit)
		Launcher.Map.mapNode.add_child(newLabel)

#
func Ready(entity : BaseEntity, isPC : bool = false):
	if nameLabel:
		nameLabel.set_text(entity.entityName)
		nameLabel.set_visible(entity.displayName)

	if triggerArea:
		triggerArea.body_entered.connect(_body_entered)
		triggerArea.body_exited.connect(_body_exited)

	if isPC:
		if triggerArea:
			triggerArea.monitoring = true

		if Launcher.GUI:
			if Launcher.GUI.emoteContainer && Launcher.GUI.emoteContainer.ItemClicked.is_connected(EmoteWindowClicked) == false:
				Launcher.GUI.emoteContainer.ItemClicked.connect(EmoteWindowClicked)
			if Launcher.GUI.chatContainer && Launcher.GUI.chatContainer.NewTextTyped.is_connected(Launcher.Network.TriggerChat) == false:
				Launcher.GUI.chatContainer.NewTextTyped.connect(Launcher.Network.TriggerChat)

	emoteDelay				= Launcher.Conf.GetFloat("Interactive", "emoteDelay", Launcher.Conf.Type.GAMEPLAY)
	morphDelay				= Launcher.Conf.GetFloat("Interactive", "morphDelay", Launcher.Conf.Type.GAMEPLAY)
	speechDelay				= Launcher.Conf.GetFloat("Interactive", "speechDelay", Launcher.Conf.Type.GAMEPLAY)
	speechDecreaseDelay		= Launcher.Conf.GetFloat("Interactive", "speechDecreaseDelay", Launcher.Conf.Type.GAMEPLAY)
	speechIncreaseThreshold	= Launcher.Conf.GetInt("Interactive", "speechIncreaseThreshold", Launcher.Conf.Type.GAMEPLAY)
	speechMaxWidth			= Launcher.Conf.GetInt("Interactive", "speechMaxWidth", Launcher.Conf.Type.GAMEPLAY)
	speechExtraWidth		= Launcher.Conf.GetInt("Interactive", "speechExtraWidth", Launcher.Conf.Type.GAMEPLAY)

#
func _physics_process(_delta : float):
	if speechDecreaseDelay > 0:
		for speechChild in speechContainer.get_children():
			if speechChild && speechChild.has_node("InteractiveTimer"):
				var timeLeft : float			= speechChild.get_node("InteractiveTimer").get_time_left()
				var speechIncreaseDelay : float	= speechDecreaseDelay
				var textLength : int			= speechChild.get_total_character_count()

				if textLength < speechIncreaseThreshold:
					speechIncreaseDelay = speechDecreaseDelay / (speechIncreaseThreshold - textLength)

				if timeLeft > speechDelay - speechIncreaseDelay:
					var ratio : float = ((speechDelay - timeLeft) / speechIncreaseDelay)
					speechChild.set_visible_characters_behavior(TextServer.VC_GLYPHS_LTR)
					speechChild.visible_ratio = ratio
				elif timeLeft > 0 && timeLeft < speechDecreaseDelay:
					var ratio : float = (timeLeft / speechDecreaseDelay)
					speechChild.modulate.a = ratio
					speechChild.set_visible_characters_behavior(TextServer.VC_GLYPHS_RTL)
					speechChild.visible_ratio = ratio
				else:
					speechChild.visible_ratio = 1

			var speechContent : String = speechChild.get_parsed_text()
			var speechLength : float = speechChild.get_theme_font("normal_font").get_string_size(speechContent).x
			if speechLength > speechMaxWidth:
				speechLength = speechMaxWidth
			speechChild.custom_minimum_size.x = speechLength as int + speechExtraWidth

func _body_entered(body):
	if body && (body is NpcEntity || body is MonsterEntity) && self != body.interactive:
		if canInteractWith.has(body) == false:
			canInteractWith.append(body)

func _body_exited(body):
	if body && (body is NpcEntity || body is MonsterEntity) && self != body.interactive:
		var bodyPos : int = canInteractWith.find(body)
		if bodyPos != -1:
			canInteractWith.remove_at(bodyPos)
