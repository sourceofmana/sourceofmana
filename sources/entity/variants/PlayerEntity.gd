extends BaseEntity
class_name PlayerEntity

var isPlayableController : bool	= false
var target : BaseEntity			= null

#
func SetLocalPlayer():
	isPlayableController = true
	collision_layer |= 2

	if Launcher.Camera:
		Launcher.Camera.mainCamera = Launcher.FileSystem.LoadEntityComponent("Camera")
		if Launcher.Camera.mainCamera:
			add_child(Launcher.Camera.mainCamera)

func Interact():
	target = null
	if isPlayableController && interactive && Launcher.Map:
		var nearestDistance : float = -1
		for nearEntity in interactive.canInteractWith:
			if nearEntity && nearEntity.entityState != EntityCommons.State.DEATH:
				var distance : float = (nearEntity.position - position).length()
				if nearestDistance == -1 || distance < nearestDistance:
					nearestDistance = distance
					target = nearEntity

		if target:
			var entityID = Launcher.Map.entities.find_key(target)
			if entityID != null:
				Launcher.Network.TriggerEntity(entityID)

#
func _physics_process(deltaTime : float):
	super._physics_process(deltaTime)

	if Launcher.Debug && isPlayableController:
		if Launcher.Debug.correctPos:
			Launcher.Debug.correctPos.position = position + entityPosOffset
		if Launcher.Debug.wrongPos:
			Launcher.Debug.wrongPos.position = position
