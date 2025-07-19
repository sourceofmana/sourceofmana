extends Node2D
class_name EntityInteractive

#
@onready var visibleNode : Node2D			= $TopOffset
@onready var speechContainer : BoxContainer	= $TopOffset/TopBox/Panel/SpeechContainer
@onready var emoteFx : GPUParticles2D		= $TopOffset/Emote
@onready var healthBar : TextureProgressBar	= $UnderBox/HealthBar
@onready var nameLabel : Label				= $UnderBox/Name

@onready var entity : Entity				= get_parent()

var displayName : bool						= false
var selectionFx : GPUParticles2D			= null
var visualOffset : int						= -1

#
func DisplaySelection(hue : float, alpha : float = 1.0):
	if selectionFx == null:
		selectionFx = ActorCommons.SelectionFx.instantiate()
		selectionFx.finished.connect(remove_child.bind(selectionFx))
		add_child(selectionFx)

		if selectionFx and ActorCommons.interactionDisplayOffset > 0:
			var sizeRatio : float = float(visualOffset) / float(ActorCommons.interactionDisplayOffset)
			var emissionShapeScale : Vector3 = selectionFx.process_material.get("emission_shape_scale")
			if emissionShapeScale != Vector3.ZERO:
				emissionShapeScale *= sizeRatio
				selectionFx.process_material.set("emission_shape_scale", emissionShapeScale)
			selectionFx.amount_ratio = sizeRatio

	if selectionFx:
		var colorRamp : GradientTexture1D = selectionFx.process_material.get("color_ramp")
		if colorRamp and colorRamp.gradient.colors.size() > 1:
			colorRamp.gradient.colors[1].h = hue
			colorRamp.gradient.colors[1].a = alpha
			selectionFx.process_material.set("color_ramp", colorRamp)

func DisplayTarget(type : ActorCommons.Target):
	match type:
		ActorCommons.Target.NONE:
			if selectionFx and selectionFx.emitting:
				DisplaySelection(0.0, 0.0)
				selectionFx.emitting = false
				selectionFx = null
			if nameLabel and nameLabel.material:
				nameLabel.material = null
			return
		ActorCommons.Target.ALLY:
			nameLabel.material = ActorCommons.AllyTarget
			DisplaySelection(ActorCommons.PlayerColor)
		ActorCommons.Target.ENEMY:
			nameLabel.material = ActorCommons.EnemyTarget
			DisplaySelection(ActorCommons.MonsterColor)

func DisplayEmote(emoteID : int):
	assert(emoteFx != null, "No emote particle found, could not display emote")
	if emoteFx:
		if DB.EmotesDB and emoteID in DB.EmotesDB:
			var emote : BaseCell = DB.EmotesDB[emoteID]
			emoteFx.texture = emote.icon
			emoteFx.lifetime = ActorCommons.emoteDelay
			emoteFx.restart()
			if entity == Launcher.Player:
				emote.used.emit()

#
func DisplayMorph(callback : Callable, args : Array):
	var particle : GPUParticles2D = ActorCommons.MorphFx.instantiate()
	if particle:
		Callback.SelfDestructTimer(self, ActorCommons.morphDelay, callback, args)
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
func DisplayCast(emitter : Entity, skillID : int):
	if DB.SkillsDB.has(skillID):
		var skill : SkillCell = DB.SkillsDB[skillID]
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

func DisplaySkill(emitter : Entity, skillID : int, cooldown : float):
	if DB.SkillsDB.has(skillID):
		var skill : SkillCell = DB.SkillsDB[skillID]
		if skill:
			if emitter == Launcher.Player and cooldown > 0.0:
				skill.used.emit(cooldown)
			if skill.skillPreset:
				var skillFx : GPUParticles2D = skill.skillPreset.instantiate()
				if skillFx:
					skillFx.finished.connect(Util.RemoveNode.bind(skillFx, emitter))
					skillFx.lifetime = skill.skillTime
					if skill.skillColor != Color.BLACK:
						skillFx.process_material.set("color", skill.skillColor)
					skillFx.emitting = true
					emitter.add_child(skillFx)

func DisplayProjectile(targetPos : Vector2, skill : SkillCell):
	if Launcher.Map.currentFringe and skill and skill.projectilePreset:
		var projectileNode : Node2D = skill.projectilePreset.instantiate()
		if not projectileNode:
			return
		if projectileNode is Projectile:
			projectileNode.origin = entity.interactive.visibleNode.global_position
			projectileNode.origin.y += ActorCommons.interactionDisplayOffset
			projectileNode.destination = targetPos
			projectileNode.destination.y -= ActorCommons.interactionDisplayOffset
			projectileNode.delay = entity.stat.current.castAttackDelay
			Launcher.Map.currentFringe.add_child(projectileNode)
		else:
			projectileNode.global_position = targetPos
			projectileNode.finished.connect(Util.RemoveNode.bind(projectileNode, Launcher.Map.currentFringe))
			projectileNode.emitting = true
			Launcher.Map.currentFringe.add_child(projectileNode)

func DisplayAlteration(target : Entity, emitter : Entity, value : int, alteration : ActorCommons.Alteration, skillID : int):
	if Launcher.Map.currentFringe:
		var newLabel : Label = ActorCommons.AlterationLabel.instantiate()
		newLabel.SetPosition(visibleNode.get_global_position(), target.get_global_position())
		newLabel.SetValue(emitter, value, alteration)
		Launcher.Map.currentFringe.add_child(newLabel)

		if entity.type != ActorCommons.Type.PLAYER:
			if alteration == ActorCommons.Alteration.HEAL:
				target.stat.health += value
				target.stat.RefreshVitalStats()
			elif alteration == ActorCommons.Alteration.HIT or alteration == ActorCommons.Alteration.CRIT:
				target.stat.health -= value
				target.stat.RefreshVitalStats()

		if emitter != target and Launcher.Player == emitter:
			var skill : SkillCell = DB.SkillsDB.get(skillID, null)
			if skill and skill.mode == Skill.TargetMode.SINGLE:
				DisplayHP()

#
func DisplaySpeech(speech : String):
	assert(speechContainer != null, "No speech container found, could not display speech bubble")
	if speechContainer:
		var speechLabel : RichTextLabel = ActorCommons.SpeechLabel.instantiate()
		speechLabel.set_text("[center]%s[/center]" % [speech])
		speechLabel.set_visible_ratio(0)
		speechContainer.add_child(speechLabel)
		Callback.SelfDestructTimer(speechLabel, ActorCommons.speechDelay, Util.RemoveNode, [speechLabel, speechContainer])

#
func DisplayHP():
	if not ActorCommons.IsAlive(entity) or entity.stat.health == 0 or (entity.stat.current.maxHealth == 0 and healthBar.max_value == 0):
		HideHP()
		return

	if Launcher.Player:
		if Launcher.Player.target != entity:
			Callback.SelfDestructTimer(healthBar, ActorCommons.DisplayHPDelay, HideHP, [], "HideHP")
		if entity.stat.level >= Launcher.Player.stat.level and ActorCommons.LevelDifferenceColor:
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

func RefreshHP():
	if healthBar.visible:
		DisplayHP()

func HideHP():
	healthBar.modulate.a = 0.99

func DisplaySailContext():
	Launcher.GUI.choiceContext.Clear()
	Launcher.GUI.choiceContext.Push(ContextData.new("ui_context_validate", "Explore", Network.TriggerExplore.bind()))
	Launcher.GUI.choiceContext.Push(ContextData.new("ui_context_cancel", "Cancel", Callback.Empty.bind()))
	Launcher.GUI.choiceContext.FadeIn(true)

#
func RefreshVisibleNodeOffset():
	if entity.visual:
		var offset : int = entity.visual.GetPlayerOffset()

		visibleNode.position.y = -1 * (offset + ActorCommons.interactionDisplayOffset)
		visualOffset = clampi(offset, 20, 256)

#
func _physics_process(delta : float):
	if healthBar.visible and healthBar.modulate.a < 1:
		healthBar.modulate.a = max(0, healthBar.modulate.a - delta * 2)
		if not displayName:
			nameLabel.modulate.a = healthBar.modulate.a
		if healthBar.modulate.a == 0:
			healthBar.visible = false
			nameLabel.visible = displayName

func Init(data : EntityData):
	displayName = entity.type == ActorCommons.Type.PLAYER or data._displayName

	if nameLabel:
		nameLabel.set_text(entity.nick)
		nameLabel.set_visible(displayName)
		match entity.type:
			ActorCommons.Type.NPC:
				nameLabel.set("theme_override_colors/font_color", ActorCommons.NPCTextColor)
			ActorCommons.Type.MONSTER:
				nameLabel.set("theme_override_colors/font_color", ActorCommons.MonsterTextColor)

	if entity.visual:
		entity.visual.spriteOffsetUpdate.connect(RefreshVisibleNodeOffset)
		RefreshVisibleNodeOffset()
