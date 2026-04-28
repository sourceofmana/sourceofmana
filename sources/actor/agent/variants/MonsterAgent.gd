extends AIAgent
class_name MonsterAgent

#
static func GetActorType() -> ActorCommons.Type: return ActorCommons.Type.MONSTER

func Killed():
	super.Killed()
	Formula.ApplyXp(self)

	# Iterate from last to first to keep idx linear even with dropped items
	for idx in range(inventory.items.size() - 1, -1, -1):
		var item : Item = inventory.items[idx]
		if item:
			var cell : ItemCell = DB.GetItem(item.cellID, item.cellCustomfield)
			if cell and cell in data._drops:
				inventory.DropItem(cell, item.count, idx)

	var inst : WorldInstance = WorldAgent.GetInstanceFromAgent(self)
	if inst and inst.timers:
		Callback.SelfDestructTimer(inst.timers, ActorCommons.DeathDelay, WorldAgent.RemoveAgent, [self])

func _ready():
	inventory = ActorInventory.new(self)
	super._ready()
	AddSkill(DB.SkillsDB[DB.GetCellHash(SkillCommons.SkillMeleeName)], 1.0)
