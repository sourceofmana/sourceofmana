extends Object
class_name WorldDrop

# Drop management
static func PushDrop(item : Item, agent : BaseAgent):
	if agent:
		var inst : WorldInstance = agent.get_parent()
		if inst:
			var drop : Drop = Drop.new(item, agent.position)
			inst.drops.append(drop)
			drop.timer = Callback.SelfDestructTimer(inst, ActorCommons.DropDelay, WorldDrop.PopDrop.bind(drop, inst))
			Launcher.Network.Server.NotifyInstance(inst, "DropAdded", [drop])

static func PopDrop(drop : Drop, inst : WorldInstance) -> bool:
	if inst and inst.drops.find(drop) >= 0:
		inst.drops.erase(drop)
		Launcher.Network.Server.NotifyInstance(inst, "DropRemoved", [drop])
		if drop.timer:
			drop.timer.stop()
			drop.timer.queue_free()
		drop.queue_free()
		return true
	return false

static func RetrieveDrop(drop : Drop, agent : BaseAgent) -> bool:
	if agent:
		var inst : WorldInstance = agent.get_parent()
		if PopDrop(drop, inst) and agent.inventory.AddItem(drop.item.cell, drop.item.count):
			return true
	return false
