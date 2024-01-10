extends Node2D
class_name EntityInteractive

#
@onready var visibleNode : Node2D			= $Visible
@onready var generalVBox : BoxContainer		= $Visible/VBox
@onready var speechContainer : BoxContainer	= $Visible/VBox/Panel/SpeechContainer
@onready var emoteFx : GPUParticles2D		= $Visible/Emote
@onready var nameLabel : Label				= $Name
@onready var triggerArea : Area2D			= $Area

var canInteractWith : Array[BaseEntity]		= []

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
func DisplayAlteration(target : BaseEntity, dealer : BaseEntity, value : int, alteration : EntityCommons.Alteration):
	if Launcher.Map.mapNode:
		var newLabel : Label = EntityCommons.AlterationLabel.instantiate()
		newLabel.SetPosition(visibleNode.get_global_position(), target.get_global_position())
		newLabel.SetValue(dealer, value, alteration)
		Launcher.Map.mapNode.add_child(newLabel)

#
func RefreshVisibleNodeOffset(offset : int):
	visibleNode.position.y = (-EntityCommons.interactionDisplayOffset) + offset

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
		Launcher.GUI.emoteContainer.ItemClicked.connect(DisplayEmote)
		Launcher.GUI.chatContainer.NewTextTyped.connect(Launcher.Network.TriggerChat)
		if triggerArea:
			triggerArea.monitoring = true

	if visibleNode and entity.visual:
		entity.visual.spriteOffsetUpdate.connect(RefreshVisibleNodeOffset)
		entity.visual.SyncPlayerOffset()

#
func _body_entered(body):
	if body and (body is NpcEntity || body is MonsterEntity) && self != body.interactive:
		if canInteractWith.has(body) == false:
			canInteractWith.append(body)

func _body_exited(body):
	if body and (body is NpcEntity || body is MonsterEntity) && self != body.interactive:
		var bodyPos : int = canInteractWith.find(body)
		if bodyPos != -1:
			canInteractWith.remove_at(bodyPos)
