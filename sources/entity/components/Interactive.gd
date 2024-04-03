extends Node2D
class_name EntityInteractive

#
@onready var visibleNode : Node2D			= $TopOffset
@onready var speechContainer : BoxContainer	= $TopOffset/TopBox/Panel/SpeechContainer
@onready var emoteFx : GPUParticles2D		= $TopOffset/Emote
@onready var healthBar : TextureProgressBar	= $UnderBox/HealthBar
@onready var nameLabel : Label				= $UnderBox/Name

@onready var entity : Entity				= get_parent()

#
func DisplayEmote(emoteID : String):
	Util.Assert(emoteFx != null, "No emote particle found, could not display emote")
	if emoteFx:
		if DB.EmotesDB && DB.EmotesDB[emoteID]:
			emoteFx.texture = DB.EmotesDB[emoteID].icon
			emoteFx.lifetime = ActorCommons.emoteDelay
			emoteFx.restart()

#
func DisplayMorph(callback : Callable):
	var particle : GPUParticles2D = ActorCommons.MorphFx.instantiate()
	if particle:
		Callback.SelfDestructTimer(self, ActorCommons.morphDelay, callback)
		particle.finished.connect(Util.RemoveNode.bind(particle, self))
		particle.emitting = true
		add_child(particle)

#
func DisplayLevelUp():
	var particle : GPUParticles2D = ActorCommons.LevelUpFx.instantiate()
	if particle:
		particle.emitting = true
		add_child(particle)

#
func DisplayCast(emitter : Entity, skillName : String):
	if DB.SkillsDB.has(skillName):
		var skill : SkillCell = DB.SkillsDB[skillName]
		if skill.castPreset:
			var castFx : GPUParticles2D = skill.castPreset.instantiate()
			if castFx:
				castFx.finished.connect(Util.RemoveNode.bind(castFx, self))
				castFx.lifetime = skill.castTime + emitter.stat.current.castAttackDelay
				castFx.texture = skill.castTextureOverride
				if skill.castColor != Color.BLACK:
					castFx.self_modulate = skill.castColor
				castFx.emitting = true
				add_child(castFx)
				if skill.mode == Skill.TargetMode.ZONE:
					Callback.SelfDestructTimer(self, skill.castTime, DisplaySkill.bind(emitter, skill), "ActionTimer")

func DisplaySkill(emitter : Entity, skill : SkillCell):
	if skill and skill.skillPreset:
		var skillFx : GPUParticles2D = skill.skillPreset.instantiate()
		if skillFx:
			skillFx.finished.connect(Util.RemoveNode.bind(skillFx, emitter))
			skillFx.lifetime = skill.skillTime
			if skill.skillColor != Color.BLACK:
				skillFx.process_material.set("color", skill.skillColor)
			skillFx.emitting = true
			emitter.add_child(skillFx)

func DisplayProjectile(emitter : Entity, skill : SkillCell, callable : Callable):
	if Launcher.Map.tilemapNode and skill and skill.projectilePreset:
		var projectileNode : Node2D = skill.projectilePreset.instantiate()
		if projectileNode:
			projectileNode.origin = emitter.interactive.visibleNode.global_position
			projectileNode.origin.y += ActorCommons.interactionDisplayOffset
			projectileNode.destination = get_parent().interactive.visibleNode.global_position
			projectileNode.destination.y += ActorCommons.interactionDisplayOffset
			projectileNode.delay = emitter.stat.current.castAttackDelay
			projectileNode.callable = callable
			Launcher.Map.tilemapNode.add_child(projectileNode)

func DisplayAlteration(target : Entity, emitter : Entity, value : int, alteration : ActorCommons.Alteration, skillName : String):
	if Launcher.Map.tilemapNode:
		if alteration != ActorCommons.Alteration.PROJECTILE:
			var newLabel : Label = ActorCommons.AlterationLabel.instantiate()
			newLabel.SetPosition(visibleNode.get_global_position(), target.get_global_position())
			newLabel.SetValue(emitter, value, alteration)
			Launcher.Map.tilemapNode.add_child(newLabel)
			target.stat.health += value if alteration == ActorCommons.Alteration.HEAL else -value
			target.stat.RefreshActiveStats()

		if DB.SkillsDB.has(skillName):
			var skill : SkillCell = DB.SkillsDB[skillName]
			if skill.mode != Skill.TargetMode.ZONE:
				var callable : Callable = DisplaySkill.bind(target, skill)
				if alteration == ActorCommons.Alteration.PROJECTILE:
					DisplayProjectile(emitter, skill, callable)
				else:
					callable.call()

#
func DisplaySpeech(speech : String):
	Util.Assert(speechContainer != null, "No speech container found, could not display speech bubble")
	if speechContainer:
		var speechLabel : RichTextLabel = ActorCommons.SpeechLabel.instantiate()
		speechLabel.set_text("[center]%s[/center]" % [speech])
		speechLabel.set_visible_ratio(0)
		speechContainer.add_child(speechLabel)
		Callback.SelfDestructTimer(speechLabel, ActorCommons.speechDelay, Util.RemoveNode.bind(speechLabel, speechContainer))

#
func DisplayHP():
	if entity.stat.health == 0 or (entity.stat.current.maxHealth == 0 and healthBar.max_value == 0):
		HideHP()
		return

	Callback.SelfDestructTimer(healthBar, ActorCommons.DisplayHPDelay, HideHP, "HideHP")
	if Launcher.Player and entity.stat.level >= Launcher.Player.stat.level and ActorCommons.LevelDifferenceColor:
		nameLabel.modulate = lerp(Color.WHITE, Color.RED, (entity.stat.level - Launcher.Player.stat.level) / ActorCommons.LevelDifferenceColor)
	healthBar.visible = true
	healthBar.modulate.a = 1
	nameLabel.visible = true
	nameLabel.modulate.a = 1

	if entity.stat.current.maxHealth != 0:
		healthBar.max_value = entity.stat.current.maxHealth
	if healthBar.max_value > 0:
		healthBar.value = entity.stat.health
		var ratio : float = healthBar.value / healthBar.max_value
		if ratio <= 0.33:
			healthBar.tint_progress = Color.RED.lerp(Color.YELLOW, ratio * 3.0)
		elif ratio <= 0.66:
			healthBar.tint_progress = Color.YELLOW.lerp(Color.GREEN, (ratio-0.33) * 3.0)
		else:
			healthBar.tint_progress = Color.GREEN

func HideHP():
	healthBar.modulate.a = 0.99

#
func RefreshVisibleNodeOffset(offset : int):
	visibleNode.position.y = (-ActorCommons.interactionDisplayOffset) + offset

#
func _physics_process(delta):
	if healthBar.visible and healthBar.modulate.a < 1:
		healthBar.modulate.a = max(0, healthBar.modulate.a - delta * 2)
		if not entity.displayName:
			nameLabel.modulate.a = healthBar.modulate.a
		if healthBar.modulate.a == 0:
			healthBar.visible = false
			nameLabel.visible = entity.displayName

func _ready():
	Util.Assert(entity != null, "No Entity is found as parent for this Interactive node")
	if not entity:
		return

	if nameLabel:
		nameLabel.set_text(entity.nick)
		nameLabel.set_visible(entity.displayName)

	if visibleNode and entity.visual:
		entity.visual.spriteOffsetUpdate.connect(RefreshVisibleNodeOffset)
		entity.visual.SyncPlayerOffset()
