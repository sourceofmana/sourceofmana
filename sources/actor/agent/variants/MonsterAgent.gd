extends AIAgent
class_name MonsterAgent

#
static func GetActorType() -> ActorCommons.Type: return ActorCommons.Type.MONSTER

func Killed():
	super.Killed()
	Formula.ApplyXp(self)

	for item in inventory.items:
		if item:
			var cell : ItemCell = DB.GetItem(item.cellID, item.cellCustomfield)
			if cell and cell.name in data._drops:
				inventory.DropItem(cell, item.count)

	var inst : WorldInstance = WorldAgent.GetInstanceFromAgent(self)
	if inst and inst.timers:
		Callback.SelfDestructTimer(inst.timers, ActorCommons.DeathDelay, WorldAgent.RemoveAgent, [self])

func _ready():
	inventory = ActorInventory.new(self)
	super._ready()
	AddSkill(DB.SkillsDB[DB.GetCellHash(SkillCommons.SkillMeleeName)], 1.0)
