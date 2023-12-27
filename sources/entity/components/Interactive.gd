extends Node2D
class_name EntityInteractive

#
@onready var visibleNode : Node2D			= $Visible
@onready var generalVBox : BoxContainer		= $Visible/VBox
@onready var speechContainer : BoxContainer	= $Visible/VBox/Panel/SpeechContainer
@onready var emoteFx : GPUParticles2D		= $Visible/Emote
@onready var nameLabel : Label				= $Name
@onready var triggerArea : Area2D			= $Area

var canInteractWith : Array[BaseEntity]			= []

#
func DisplayEmote(emoteID : String):
	Util.Assert(emoteFx != null, "No emote particle found, could not display emote")
	if emoteFx:
		if Launcher.DB.EmotesDB && Launcher.DB.EmotesDB[emoteID]:
			emoteFx.texture = FileSystem.LoadGfx(Launcher.DB.EmotesDB[emoteID]._path)
			emoteFx.lifetime = EntityCommons.emoteDelay
			emoteFx.restart()

#
func DisplayMorph(callback : Callable):
	var morphFx : GPUParticles2D = load("res://presets/effects/particles/Morph.tscn").instantiate()
	if morphFx:
		Util.SelfDestructTimer(self, EntityCommons.morphDelay, callback)
		morphFx.finished.connect(Util.RemoveNode.bind(morphFx, self))
		morphFx.emitting = true
		add_child(morphFx)

#
func DisplayCast(skillID : String):
	if Launcher.DB.SkillsDB && Launcher.DB.SkillsDB[skillID]:
		var skillRef : SkillData = Launcher.DB.SkillsDB[skillID]
		var castFx : GPUParticles2D = FileSystem.LoadEffect(skillRef._castPresetPath)
		if castFx:
			castFx.finished.connect(Util.RemoveNode.bind(castFx, self))
			castFx.lifetime = skillRef._castTime
			castFx.texture = FileSystem.LoadGfx(skillRef._castTextureOverride)
			castFx.process_material.set("color", skillRef._castColor)
			castFx.emitting = true
			add_child(castFx)

#
func DisplaySpeech(speech : String):
	Util.Assert(speechContainer != null, "No speech container found, could not display speech bubble")
	if speechContainer:
		var speechLabel : RichTextLabel = EntityCommons.SpeechLabel.instantiate()
		speechLabel.set_text("[center]%s[/center]" % [speech])
		speechLabel.set_visible_ratio(0)
		speechContainer.add_child(speechLabel)
		Util.SelfDestructTimer(speechLabel, EntityCommons.speechDelay, Util.RemoveNode.bind(speechLabel, speechContainer))

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
			if Launcher.GUI.emoteContainer && Launcher.GUI.emoteContainer.ItemClicked.is_connected(DisplayEmote) == false:
				Launcher.GUI.emoteContainer.ItemClicked.connect(DisplayEmote)
			if Launcher.GUI.chatContainer && Launcher.GUI.chatContainer.NewTextTyped.is_connected(Launcher.Network.TriggerChat) == false:
				Launcher.GUI.chatContainer.NewTextTyped.connect(Launcher.Network.TriggerChat)

#
func _physics_process(_delta : float):
	if EntityCommons.speechDecreaseDelay > 0:
		for speechChild in speechContainer.get_children():
			if speechChild && speechChild.has_node("Timer"):
				var timeLeft : float			= speechChild.get_node("Timer").get_time_left()
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
