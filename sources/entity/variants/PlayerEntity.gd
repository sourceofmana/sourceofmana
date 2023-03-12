extends BaseEntity
class_name PlayerEntity

var isPlayableController		= false
var timer : Timer				= null

#
func SetLocalPlayer():
	isPlayableController = true
	collision_layer |= 2

	Launcher.Camera.mainCamera = Launcher.FileSystem.LoadPreset("cameras/Default")
	if Launcher.Camera.mainCamera:
		add_child(Launcher.Camera.mainCamera)

#
func _physics_process(deltaTime : float):
	super._physics_process(deltaTime)
	if interactive:
		interactive.Update(self, isPlayableController)

	if Launcher.Debug && isPlayableController:
		if Launcher.Debug.correctPos:
			Launcher.Debug.correctPos.position = position + entityPosOffset
		if Launcher.Debug.wrongPos:
			Launcher.Debug.wrongPos.position = position


func _ready():
	super._ready()
	if interactive:
		interactive.Setup(self, isPlayableController)

func _init():
	super._init()
	timer = Timer.new()
	timer.set_name("ClickTimer")
	timer.set_wait_time(0.2)
	timer.set_one_shot(true)
	add_child(timer)
