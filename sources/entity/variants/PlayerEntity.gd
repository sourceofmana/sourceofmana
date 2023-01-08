extends BaseEntity
class_name PlayerEntity

var isPlayableController		= false
var camera : Camera2D				= null

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

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT && event.pressed:
			WalkToward(Launcher.Camera.mainCamera.get_global_mouse_position())
			return

	currentInput = Launcher.Action.GetMove()
	if currentInput.length() > 0:
		SwitchInputMode(false)


func _physics_process(deltaTime : float):
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

	if isPlayableController:
		camera = Launcher.FileSystem.LoadPreset("cameras/Default")
		add_child(camera)
		Launcher.Camera.mainCamera = camera
