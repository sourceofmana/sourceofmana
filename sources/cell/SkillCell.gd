extends BaseCell
class_name SkillCell

@export var state : ActorCommons.State			= ActorCommons.State.IDLE
@export var cellRange : int						= 0
@export var mode : Skill.TargetMode				= Skill.TargetMode.SINGLE
@export var repeat : bool						= false
@export var cooldownTime : float				= 0.0
@export_category("Cast")
@export var castPreset : PackedScene			= null
@export var castTextureOverride : Resource		= null
@export var castColor : Color					= Color.BLACK
@export var castTime : float					= 0.0
@export_category("Skill")
@export var skillPreset : PackedScene			= null
@export var skillColor : Color					= Color.BLACK
@export var skillTime : float					= 0.0
@export_category("Projectile")
@export var projectilePreset : PackedScene		= null

#
func Use():
	if usable:
		Launcher.Player.Cast(self.id)
