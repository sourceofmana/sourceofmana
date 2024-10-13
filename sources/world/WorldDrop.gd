extends Object
class_name WorldDrop

# Drop management
static func PushDrop(item : Item, agent : BaseAgent):
	if agent:
		var inst : WorldInstance = WorldAgent.GetInstanceFromAgent(agent)
		if inst and inst.map and not inst.map.HasFlags(WorldMap.Flags.NO_DROP):
			var dropPos : Vector2 = agent.position
			dropPos.x += randf_range(-agent.entityRadius, agent.entityRadius)
			dropPos.y += randf_range(-agent.entityRadius, agent.entityRadius)

			var drop : Drop = Drop.new(item, dropPos)
			inst.drops[drop.get_instance_id()] = drop

			var dropID : int = drop.get_instance_id()
			drop.timer = Callback.SelfDestructTimer(inst, ActorCommons.DropDelay, WorldDrop.Timeout, [dropID, inst])
			Launcher.Network.Server.NotifyInstance(inst, "DropAdded", [dropID, item.cell.id, drop.position])

static func PopDrop(dropID : int, inst : WorldInstance) -> bool:
	if inst and inst.drops.has(dropID):
		var drop : Drop = inst.drops[dropID]
		inst.drops.erase(dropID)
		Launcher.Network.Server.NotifyInstance(inst, "DropRemoved", [dropID])
		if drop:
			if drop.timer != null:
				drop.timer.stop()
				drop.timer.queue_free()
			drop.queue_free()
			return true
	return false

static func Timeout(dropID : int, inst : WorldInstance):
	if inst and inst.drops.has(dropID):
		var drop : Drop = inst.drops[dropID]
		if drop:
			drop.timer = null
			PopDrop(dropID, inst)

static func PickupDrop(dropID : int, agent : BaseAgent) -> bool:
	if agent and ActorCommons.IsAlive(agent) and agent.inventory:
		var inst : WorldInstance = WorldAgent.GetInstanceFromAgent(agent)
		if inst and dropID in inst.drops:
			var drop : Drop = inst.drops[dropID]
			if agent.position.distance_squared_to(drop.position) < ActorCommons.PickupSquaredDistance \
			and PopDrop(dropID, inst) \
			and agent.inventory.AddItem(drop.item.cell, drop.item.count):
				return true
	return false
