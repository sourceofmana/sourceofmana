extends Node2D
class_name EntityInteractive

#
@onready var visibleNode : Node2D			= $Visible
@onready var generalVBox : BoxContainer		= $Visible/VBox
@onready var speechContainer : BoxContainer	= $Visible/VBox/Panel/SpeechContainer
@onready var emoteFx : GPUParticles2D		= $Visible/Emote
@onready var nameLabel : Label				= $Name

static var MorphFx : PackedScene			= preload("res://presets/effects/particles/Morph.tscn")
static var LevelUpFx : PackedScene			= preload("res://presets/effects/particles/LevelUp.tscn")

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
	var particle : GPUParticles2D = MorphFx.instantiate()
	if particle:
		Callback.SelfDestructTimer(self, EntityCommons.morphDelay, callback)
		particle.finished.connect(Util.RemoveNode.bind(particle, self))
		particle.emitting = true
		add_child(particle)

#
func DisplayLevelUp():
	var particle : GPUParticles2D = LevelUpFx.instantiate()
	if particle:
		particle.emitting = true
		add_child(particle)

#
func DisplayCast(entity : BaseEntity, skillName : String):
	if Launcher.DB.SkillsDB.has(skillName):
		var skill : SkillData = Launcher.DB.SkillsDB[skillName]
		if skill._castPreset:
			var castFx : GPUParticles2D = skill._castPreset.instantiate()
			if castFx:
				castFx.finished.connect(Util.RemoveNode.bind(castFx, self))
				castFx.lifetime = skill._castTime + entity.stat.current.castAttackDelay
				castFx.texture = skill._castTextureOverride
				if skill._castColor != Color.BLACK:
					castFx.process_material.set("color", skill._castColor)
				castFx.emitting = true
				add_child(castFx)
				if skill._mode == Skill.TargetMode.ZONE:
					Callback.SelfDestructTimer(self, skill._castTime, DisplaySkill.bind(entity, skill), "ActionTimer")

func DisplaySkill(entity : BaseEntity, skill : SkillData):
	if skill and skill._skillPreset:
		var skillFx : GPUParticles2D = skill._skillPreset.instantiate()
		if skillFx:
			skillFx.finished.connect(Util.RemoveNode.bind(skillFx, entity))
			skillFx.lifetime = skill._skillTime
			if skill._skillColor != Color.BLACK:
				skillFx.process_material.set("color", skill._skillColor)
			skillFx.emitting = true
			entity.add_child(skillFx)

func DisplayProjectile(dealer : BaseEntity, skill : SkillData, callable : Callable):
	if Launcher.Map.tilemapNode and skill and skill._projectilePreset:
		var projectileNode : Node2D = skill._projectilePreset.instantiate()
		if projectileNode:
			projectileNode.origin = dealer.interactive.visibleNode.global_position
			projectileNode.origin.y += EntityCommons.interactionDisplayOffset
			projectileNode.destination = get_parent().interactive.visibleNode.global_position
			projectileNode.destination.y += EntityCommons.interactionDisplayOffset
			projectileNode.delay = dealer.stat.current.castAttackDelay
			projectileNode.callable = callable
			Launcher.Map.tilemapNode.add_child(projectileNode)

func DisplayAlteration(target : BaseEntity, dealer : BaseEntity, value : int, alteration : EntityCommons.Alteration, skillName : String):
	if Launcher.Map.tilemapNode:
		if alteration != EntityCommons.Alteration.PROJECTILE:
			var newLabel : Label = EntityCommons.AlterationLabel.instantiate()
			newLabel.SetPosition(visibleNode.get_global_position(), target.get_global_position())
			newLabel.SetValue(dealer, value, alteration)
			Launcher.Map.tilemapNode.add_child(newLabel)

		if Launcher.DB.SkillsDB.has(skillName):
			var skill : SkillData = Launcher.DB.SkillsDB[skillName]
			if skill._mode != Skill.TargetMode.ZONE:
				var callable : Callable = DisplaySkill.bind(target, skill)
				if alteration == EntityCommons.Alteration.PROJECTILE:
					DisplayProjectile(dealer, skill, callable)
				else:
					callable.call()

#
func DisplaySpeech(speech : String):
	Util.Assert(speechContainer != null, "No speech container found, could not display speech bubble")
	if speechContainer:
		var speechLabel : RichTextLabel = EntityCommons.SpeechLabel.instantiate()
		speechLabel.set_text("[center]%s[/center]" % [speech])
		speechLabel.set_visible_ratio(0)
		speechContainer.add_child(speechLabel)
		Callback.SelfDestructTimer(speechLabel, EntityCommons.speechDelay, Util.RemoveNode.bind(speechLabel, speechContainer))

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
