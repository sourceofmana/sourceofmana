extends Node
class_name EntityInteractive

#
var speechInstance : PackedScene	= Launcher.FileSystem.LoadGui("chat/SpeechBubble", false)
var speechContainer : BoxContainer	= null
var emoteSprite : Sprite2D			= null
var emoteTimer : Timer				= null
var speechTimers : Array[Timer]		= []
var nameLabel : Label				= null
var triggerArea : Area2D			= null

var currentEmoteID : int			= -1
var emoteDelay : float				= 0
var speechDelay : float				= 0
var speechDecreaseDelay : float		= 0
var speechIncreaseThreshold : int	= 0

var canInteractWith : Array[BaseEntity]			= []

#
func AddTimer(parent : Node, delay : float, callable: Callable) -> Timer:
	var timer = Timer.new()
	timer.set_name("InteractiveTimer")
	timer.set_autostart(true)
	timer.set_wait_time(delay)
	timer.timeout.connect(callable)
	parent.add_child(timer)
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
	speechLabel.set_text("[center]%s[/center]" % [speech])
	speechLabel.set_fit_content(true)
	speechContainer.add_child(speechLabel)
	speechTimers.push_front(AddTimer(speechLabel, speechDelay, RemoveSpeechLabel))

func AddDebugSpeech(speech : String):
	RemoveSpeechLabel()
	AddSpeechLabel(speech)

func DisplaySpeech(text : String):
	Launcher.Util.Assert(speechContainer != null, "No speech container found, could not display speech bubble")
	if speechContainer:
		AddSpeechLabel(text)

func UpdateDelay():
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

func UpdateActions(entity : BaseEntity):
	if Launcher.Action.IsActionJustPressed("gp_interact"): Interact(entity)

func Update(entity : BaseEntity, isPC : bool = false):
	UpdateDelay()
	if isPC:
		UpdateActions(entity)

func EmoteWindowClicked(selectedEmote : String):
	DisplayEmote(selectedEmote.to_int())

#
func Setup(entity : Node2D, isPC : bool = false):
	if entity.has_node("Interactions/Emote"):
		emoteSprite = entity.get_node("Interactions/Emote")
	if entity.has_node("Interactions/SpeechContainer"):
		speechContainer = entity.get_node("Interactions/SpeechContainer")
	if entity.has_node("Interactions/Name"):
		nameLabel = entity.get_node("Interactions/Name")
		nameLabel.set_text(entity.entityName)
		nameLabel.set_visible(entity.displayName)
	if entity.has_node("Interactions/Area"):
		triggerArea = entity.get_node("Interactions/Area")
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

	emoteDelay				= Launcher.Conf.GetFloat("Gameplay", "emoteDelay", Launcher.Conf.Type.PROJECT)
	speechDelay				= Launcher.Conf.GetFloat("Gameplay", "speechDelay", Launcher.Conf.Type.PROJECT)
	speechDecreaseDelay		= Launcher.Conf.GetFloat("Gameplay", "speechDecreaseDelay", Launcher.Conf.Type.PROJECT)
	speechIncreaseThreshold	= Launcher.Conf.GetInt("Gameplay", "speechIncreaseThreshold", Launcher.Conf.Type.PROJECT)

func Interact(selfEntity : BaseEntity):
	if Launcher.Map:
		var nearestEntity : BaseEntity = null
		var nearestDistance : float = -1
		for nearEntity in canInteractWith:
			var distance : float = (nearEntity.position - selfEntity.position).length()
			if nearestDistance == -1 || distance < nearestDistance:
				nearestDistance = distance
				nearestEntity = nearEntity
		if nearestEntity:
			var entityID = Launcher.Map.entities.find_key(nearestEntity)
			if entityID != null:
				Launcher.Network.TriggerEntity(entityID)

#
func _body_entered(body):
	if body && (body is NpcEntity || body is MonsterEntity) && self != body.interactive:
		if canInteractWith.has(body) == false:
			canInteractWith.append(body)

func _body_exited(body):
	if body && (body is NpcEntity || body is MonsterEntity) && self != body.interactive:
		var bodyPos : int = canInteractWith.find(body)
		if bodyPos != -1:
			canInteractWith.remove_at(bodyPos)
