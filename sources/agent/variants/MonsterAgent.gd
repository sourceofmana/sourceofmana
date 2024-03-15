extends BaseAgent
class_name MonsterAgent

#
static func GetEntityType() -> ActorCommons.Type: return ActorCommons.Type.MONSTER

#
func SetData(data : EntityData):
	super.SetData(data)
	stat.FillRandomAttributes()

#
func _ready():
	aiTimer = Timer.new()
	aiTimer.set_name("AiTimer")
	Callback.OneShotCallback(aiTimer.tree_entered, AI.Reset, [self])
	add_child.call_deferred(aiTimer)

	super._ready()

	AddSkill(DB.SkillsDB["Melee"], 1.0)
