extends AIAgent
class_name MonsterAgent

#
static func GetEntityType() -> ActorCommons.Type: return ActorCommons.Type.MONSTER

func Killed():
	super.Killed()
	Formula.ApplyXp(self)

	for item in inventory.items:
		if item and item.cellID in data._drops:
			var cell : ItemCell = DB.GetItem(item.cellID, item.cellCustomfield)
			if cell:
				inventory.DropItem(cell, item.count)

	var inst : WorldInstance = WorldAgent.GetInstanceFromAgent(self)
	if inst and inst.timers:
		Callback.SelfDestructTimer(inst.timers, ActorCommons.DeathDelay, WorldAgent.RemoveAgent, [self])

func _ready():
	inventory = ActorInventory.new(self)
	super._ready()
	AddSkill(DB.SkillsDB[DB.GetCellHash(SkillCommons.SkillMeleeName)], 1.0)
