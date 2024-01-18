extends Node2D
class_name EntityInteractive

#
@onready var visibleNode : Node2D			= $Visible
@onready var generalVBox : BoxContainer		= $Visible/VBox
@onready var speechContainer : BoxContainer	= $Visible/VBox/Panel/SpeechContainer
@onready var emoteFx : GPUParticles2D		= $Visible/Emote
@onready var nameLabel : Label				= $Name

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
	if Launcher.DB.SkillsDB.has(skillID):
		var skill : SkillData = Launcher.DB.SkillsDB[skillID]

		var castFx : GPUParticles2D = FileSystem.LoadEffect(skill._castPresetPath)
		if castFx:
			castFx.finished.connect(Util.RemoveNode.bind(castFx, self))
			castFx.lifetime = skill._castTime
			castFx.texture = FileSystem.LoadGfx(skill._castTextureOverride)
			if skill._castColor != Color.BLACK:
				castFx.process_material.set("color", skill._castColor)
			castFx.emitting = true
			add_child(castFx)

func DisplaySkill(node : Node, skill : SkillData):
	if skill and skill._skillPresetPath.length() > 0:
		var skillFx : GPUParticles2D = FileSystem.LoadEffect(skill._skillPresetPath)
		if skillFx:
			skillFx.finished.connect(Util.RemoveNode.bind(skillFx, node))
			skillFx.lifetime = skill._skillTime
			if skill._skillColor != Color.BLACK:
				skillFx.process_material.set("color", skill._skillColor)
			skillFx.emitting = true
			node.add_child(skillFx)

func DisplayAlteration(target : BaseEntity, dealer : BaseEntity, value : int, alteration : EntityCommons.Alteration, skillID : String):
	if Launcher.Map.mapNode:
		var newLabel : Label = EntityCommons.AlterationLabel.instantiate()
		newLabel.SetPosition(visibleNode.get_global_position(), target.get_global_position())
		newLabel.SetValue(dealer, value, alteration)
		Launcher.Map.mapNode.add_child(newLabel)

		if Launcher.DB.SkillsDB.has(skillID):
			var skill : SkillData = Launcher.DB.SkillsDB[skillID]
			DisplaySkill(target, skill)

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

	if visibleNode and entity.visual:
		entity.visual.spriteOffsetUpdate.connect(RefreshVisibleNodeOffset)
		entity.visual.SyncPlayerOffset()
