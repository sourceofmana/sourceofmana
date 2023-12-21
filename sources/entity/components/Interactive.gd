extends Node2D
class_name EntityInteractive

#
var speechInstance : PackedScene	= FileSystem.LoadGui("chat/SpeechBubble", false)

@onready var visibleNode : Node2D			= $Visible
@onready var generalVBox : BoxContainer		= $Visible/VBox
@onready var speechContainer : BoxContainer	= $Visible/VBox/Panel/SpeechContainer
@onready var emoteSprite : TextureRect		= $Visible/VBox/Emote
@onready var nameLabel : Label				= $Name
@onready var triggerArea : Area2D			= $Area

var emoteTimer : Timer				= null
var speechTimers : Array[Timer]		= []

var currentEmoteID : int			= -1
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

func RemoveParticle(particle : GPUParticles2D):
	if particle != null:
		remove_child(particle)
		particle.queue_free()

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
		emoteTimer = AddTimer(emoteSprite, EntityCommons.emoteDelay, RemoveEmoteResources)

func DisplayEmote(emoteID : int):
	Util.Assert(emoteSprite != null, "No emote sprite found, could not display emote")
	if emoteSprite:
		if currentEmoteID != emoteID:
			RemoveEmoteResources()
			AddEmoteResources(emoteID)
		elif emoteTimer && emoteTimer.get_time_left() > 0:
			emoteTimer.stop()
			emoteTimer.start(EntityCommons.emoteDelay)

func EmoteWindowClicked(selectedEmote : String):
	DisplayEmote(selectedEmote.to_int())

#
func DisplayMorph(callback : Callable):
	var morphFx : GPUParticles2D = load("res://presets/effects/particles/Morph.tscn").instantiate()
	if morphFx:
		Util.SelfDestructTimer(self, EntityCommons.morphDelay, callback)
		morphFx.finished.connect(RemoveParticle.bind(morphFx))
		morphFx.emitting = true
		add_child(morphFx)

#
func DisplayCast(castID : int, color : Color, delay : float):
	var castFx : GPUParticles2D = load("res://presets/effects/particles/CastSpell.tscn").instantiate()
	if castFx:
		castFx.finished.connect(RemoveParticle.bind(castFx))
		castFx.lifetime = delay
		castFx.texture = load("res://data/graphics/effects/particles/cast" + str(castID) + ".png")
		Util.Assert(castFx.texture != null, "Could not initialize the cast fx texture for this cast ID: " + str(castID))
		if color != Color.BLACK:
			castFx.process_material.set("color", color)
		castFx.emitting = true
		add_child(castFx)

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
		speechTimers.push_front(AddTimer(speechLabel, EntityCommons.speechDelay, RemoveSpeechLabel))

#
func DisplayDamage(target : BaseEntity, dealer : BaseEntity, damage : int, isCrit : bool = false):
	if Launcher.Map.mapNode:
		var newLabel : Label = EntityCommons.DamageLabel.instantiate()
		newLabel.SetPosition(visibleNode.get_global_position(), target.get_global_position())
		newLabel.SetDamage(damage, target == Launcher.Player, dealer == Launcher.Player, isCrit)
		Launcher.Map.mapNode.add_child(newLabel)

#
func _ready():
	var entity : BaseEntity = get_parent()
	Util.Assert(entity != null, "No BaseEntity is found as parent for this Interactive node")
	if not entity:
		return

	if nameLabel:
		nameLabel.set_text(entity.entityName)
		nameLabel.set_visible(entity.displayName)

	if entity == Launcher.Player:
		if triggerArea:
			triggerArea.monitoring = true

		if Launcher.GUI:
			if Launcher.GUI.emoteContainer && Launcher.GUI.emoteContainer.ItemClicked.is_connected(EmoteWindowClicked) == false:
				Launcher.GUI.emoteContainer.ItemClicked.connect(EmoteWindowClicked)
			if Launcher.GUI.chatContainer && Launcher.GUI.chatContainer.NewTextTyped.is_connected(Launcher.Network.TriggerChat) == false:
				Launcher.GUI.chatContainer.NewTextTyped.connect(Launcher.Network.TriggerChat)

#
func _physics_process(_delta : float):
	if EntityCommons.speechDecreaseDelay > 0:
		for speechChild in speechContainer.get_children():
			if speechChild && speechChild.has_node("InteractiveTimer"):
				var timeLeft : float			= speechChild.get_node("InteractiveTimer").get_time_left()
				var speechIncreaseDelay : float	= EntityCommons.speechDecreaseDelay
				var textLength : int			= speechChild.get_total_character_count()

				if textLength < EntityCommons.speechIncreaseThreshold:
					speechIncreaseDelay = EntityCommons.speechDecreaseDelay / (EntityCommons.speechIncreaseThreshold - textLength)

				if timeLeft > EntityCommons.speechDelay - speechIncreaseDelay:
					var ratio : float = ((EntityCommons.speechDelay - timeLeft) / speechIncreaseDelay)
					speechChild.set_visible_characters_behavior(TextServer.VC_GLYPHS_LTR)
					speechChild.visible_ratio = ratio
				elif timeLeft > 0 && timeLeft < EntityCommons.speechDecreaseDelay:
					var ratio : float = (timeLeft / EntityCommons.speechDecreaseDelay)
					speechChild.modulate.a = ratio
					speechChild.set_visible_characters_behavior(TextServer.VC_GLYPHS_RTL)
					speechChild.visible_ratio = ratio
				else:
					speechChild.visible_ratio = 1

			var speechContent : String = speechChild.get_parsed_text()
			var speechLength : float = speechChild.get_theme_font("normal_font").get_string_size(speechContent).x
			if speechLength > EntityCommons.speechMaxWidth:
				speechLength = EntityCommons.speechMaxWidth
			speechChild.custom_minimum_size.x = speechLength as int + EntityCommons.speechExtraWidth

func _body_entered(body):
	if body && (body is NpcEntity || body is MonsterEntity) && self != body.interactive:
		if canInteractWith.has(body) == false:
			canInteractWith.append(body)

func _body_exited(body):
	if body && (body is NpcEntity || body is MonsterEntity) && self != body.interactive:
		var bodyPos : int = canInteractWith.find(body)
		if bodyPos != -1:
			canInteractWith.remove_at(bodyPos)
