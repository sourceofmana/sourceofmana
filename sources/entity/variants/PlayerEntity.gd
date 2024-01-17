extends BaseEntity
class_name PlayerEntity

#
func SetLocalPlayer():
	collision_layer |= 2

	if Launcher.Camera:
		Launcher.Camera.mainCamera = FileSystem.LoadEntityComponent("Camera")
		if Launcher.Camera.mainCamera:
			add_child.call_deferred(Launcher.Camera.mainCamera)

func ClearTarget():
	if target != null:
		if target.visual.sprites[EntityCommons.Slot.BODY].material:
			target.visual.sprites[EntityCommons.Slot.BODY].material = null
		target = null

func Target(pos : Vector2):
	if not interactive:
		return

	var nearestDistance : float = -1

	ClearTarget()
	for entityID in Launcher.Map.entities:
		var entity : BaseEntity = Launcher.Map.entities[entityID]
		if entity and entity != self and entity.entityState != EntityCommons.State.DEATH:
			var distance : float = (entity.position - pos).length()
			if nearestDistance == -1 || distance < nearestDistance:
				nearestDistance = distance
				target = entity

	if target:
		if target is NpcEntity:
			target.visual.SetMainMaterial.call_deferred(EntityCommons.AllyTarget)
		elif target is MonsterEntity:
			target.visual.SetMainMaterial.call_deferred(EntityCommons.EnemyTarget)


func Interact(skillID : int = 0):
	if not target or target.entityState == EntityCommons.State.DEATH:
		Target(position)

	if target:
		var entityID = Launcher.Map.entities.find_key(target)
		if entityID != null:
			if target is NpcEntity:
				Launcher.Network.TriggerInteract(entityID)
			elif target is MonsterEntity:
				Launcher.Network.TriggerCast(entityID, skillID)

#
func _process(deltaTime : float):
	super._process(deltaTime)

	if Launcher.Debug and Launcher.Player == self:
		if Launcher.Debug.correctPos:
			Launcher.Debug.correctPos.position = position + entityPosOffset
		if Launcher.Debug.wrongPos:
			Launcher.Debug.wrongPos.position = position
