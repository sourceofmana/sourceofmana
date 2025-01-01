extends AIAgent
class_name MonsterAgent

#
static func GetEntityType() -> ActorCommons.Type: return ActorCommons.Type.MONSTER

func Killed():
	super.Killed()
	Formula.ApplyXp(self)

	for item in inventory.items:
		if item and item.cell and item.cell.id in data._drops:
			WorldDrop.PushDrop(item, self)

	var inst : WorldInstance = WorldAgent.GetInstanceFromAgent(self)
	if inst and inst.timers:
		Callback.SelfDestructTimer(inst.timers, ActorCommons.DeathDelay, WorldAgent.RemoveAgent, [self])

func _ready():
	inventory = ActorInventory.new()
	super._ready()
	AddSkill(DB.SkillsDB[DB.GetCellHash(SkillCommons.SkillMeleeName)], 1.0)
