extends BaseEntity
class_name PlayerEntity

var isPlayableController		= false
var camera : Camera2D			= null
var timer : Timer				= null

#
func GetNextState():
	var newEnumState			= currentState
	var isWalking				= currentVelocity.length_squared() > 1
	var actionSitPressed		= Launcher.Action.IsActionPressed("gp_sit") if isPlayableController else false
	var actionSitJustPressed	= Launcher.Action.IsActionJustPressed("gp_sit") if isPlayableController else false

	match currentState:
		State.IDLE:
			if isWalking:
				newEnumState = State.WALK
			elif actionSitJustPressed:
				newEnumState = State.SIT
		State.WALK:
			if isWalking == false:
				newEnumState = State.IDLE
		State.SIT:
			if actionSitPressed == false && isWalking:
				newEnumState = State.WALK
			elif actionSitJustPressed:
				newEnumState = State.IDLE

	return newEnumState

func SetLocalPlayer():
	isPlayableController = true
	camera = Launcher.FileSystem.LoadPreset("cameras/Default")
	if camera:
		add_child(camera)
		Launcher.Camera.mainCamera = camera

#
func _move_process():
	if Launcher.Action.IsActionPressed("gp_move_to"):
		if timer.get_time_left() == 0:
			_update_walk_path()
	else:
		if timer.get_time_left() > 0:
			timer.stop()

		currentInput = Launcher.Action.GetMove()
		if currentInput.length() > 0:
			SwitchInputMode(false)

func _update_walk_path():
	WalkToward(Launcher.Camera.mainCamera.get_global_mouse_position())
	timer.start()

func _physics_process(deltaTime : float):
	_move_process()
	if interactive:
		interactive.Update(isPlayableController)
	
	super._physics_process(deltaTime)

func _ready():
	set_process_input(isPlayableController)
	set_process_unhandled_input(isPlayableController)
	
	if interactive:
		interactive.Setup(self, isPlayableController)
	
	_setup_nav_agent()
	_enable_warp()

func _init():
	timer = Timer.new()
	timer.set_name("ClickTimer")
	timer.set_wait_time(0.2)
	timer.set_one_shot(true)
	add_child(timer)
