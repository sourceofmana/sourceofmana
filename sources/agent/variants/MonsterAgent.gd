extends BaseAgent
class_name MonsterAgent

#
static func GetEntityType() -> ActorCommons.Type: return ActorCommons.Type.MONSTER

func Killed():
	super.Killed()
	Formula.ApplyXp(self)

	for item in inventory.items:
		WorldDrop.PushDrop(item, self)

	Callback.SelfDestructTimer(self, ActorCommons.DeathDelay, WorldAgent.RemoveAgent, [self])

func _ready():
	inventory = ActorInventory.new()
	aiTimer = Timer.new()
	aiTimer.set_name("AiTimer")
	Callback.OneShotCallback(aiTimer.tree_entered, AI.Reset, [self])
	add_child.call_deferred(aiTimer)

	super._ready()
	AddSkill(DB.SkillsDB[DB.GetCellHash(SkillCommons.SkillMeleeName)], 1.0)
