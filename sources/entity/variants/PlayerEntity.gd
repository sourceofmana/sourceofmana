extends BaseEntity
class_name PlayerEntity

var isPlayableController		= false
var camera : Camera2D			= null
var timer : Timer				= null

#
func SetLocalPlayer():
	isPlayableController = true
	camera = Launcher.FileSystem.LoadPreset("cameras/Default")
	if camera:
		add_child(camera)
		Launcher.Camera.mainCamera = camera

#
func _physics_process(deltaTime : float):
	super._physics_process(deltaTime)
	if interactive:
		interactive.Update(self, isPlayableController)

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
