@tool
extends BaseCell
class_name SkillCell

enum Category
{
	SPELL    = 0,
	PHYSICAL = 1,
	ABILITY  = 2,
}

@export var category : Category					= Category.SPELL
@export var state : ActorCommons.State			= ActorCommons.State.IDLE
@export var cellRange : int						= 0
@export var mode : Skill.TargetMode				= Skill.TargetMode.SINGLE
@export var repeat : bool						= false
@export var cooldownTime : float				= 0.0
@export_category("Cast")
@export var castPreset : PackedScene			= null
@export var castTime : float					= 0.0
@export var castWalk : bool						= false
@export_category("Skill")
@export var skillPreset : PackedScene			= null
@export var skillTime : float					= 0.0
@export_category("Projectile")
@export var projectilePreset : PackedScene		= null
@export_category("Ability")
@export var abilityScript : Script				= null

#
func Instantiate():
	if castPreset:
		castPreset.instantiate()
	if skillPreset:
		skillPreset.instantiate()
	if projectilePreset:
		projectilePreset.instantiate()

func Hover(hovering : bool):
	super.Hover(hovering)
	if Launcher.Player and Launcher.Player.interactive:
			Launcher.Player.interactive.DisplaySkillRange(self if hovering else null)
