extends PanelContainer
class_name WindowPanel

#
signal MoveFloatingWindowToTop

#
enum EdgeOrientation { NONE, RIGHT, BOTTOM_RIGHT, BOTTOM, BOTTOM_LEFT, LEFT, TOP_LEFT, TOP, TOP_RIGHT }

#
@export var blockActions : bool		= false
@export var saveOverlayState : bool	= false
@export var maxSize : Vector2		= Vector2(-1, -1)
const edgeSize : int				= 5
const cornerSize : int				= 15
var clickPosition : Vector2			= Vector2.INF
var isResizing : bool				= false
var selectedEdge : EdgeOrientation	= EdgeOrientation.NONE

#
func ClampFloatingWindow(globalPos : Vector2, moveLimit : Vector2):
	if selectedEdge == EdgeOrientation.BOTTOM_LEFT || selectedEdge == EdgeOrientation.LEFT || selectedEdge == EdgeOrientation.TOP_LEFT:
		moveLimit.x -= custom_minimum_size.x
	elif selectedEdge == EdgeOrientation.TOP_LEFT || selectedEdge == EdgeOrientation.TOP || selectedEdge == EdgeOrientation.TOP_RIGHT:
		moveLimit.y -= custom_minimum_size.y
	return Vector2( clampf(globalPos.x, 0.0, moveLimit.x), clampf(globalPos.y, 0.0, moveLimit.y))

func ClampToMargin(marginSize : Vector2):
	if anchors_preset != LayoutPreset.PRESET_CENTER:
		position = ClampFloatingWindow(position, marginSize - size)

func ResizeWindow(pos : Vector2, globalPos : Vector2):
	var rectSize = size
	var rectPos = position

	match selectedEdge:
		EdgeOrientation.RIGHT:
			rectSize.x = pos.x
		EdgeOrientation.BOTTOM_RIGHT:
			rectSize = pos
		EdgeOrientation.BOTTOM:
			rectSize.y = pos.y
		EdgeOrientation.BOTTOM_LEFT:
			rectSize.x -= globalPos.x - rectPos.x
			rectPos.x = globalPos.x
			rectSize.y = pos.y
		EdgeOrientation.LEFT:
			rectSize.x -= globalPos.x - rectPos.x
			rectPos.x = globalPos.x
		EdgeOrientation.TOP_LEFT:
			rectSize.x -= globalPos.x - rectPos.x
			rectPos.x = globalPos.x
			rectSize.y -= globalPos.y - rectPos.y
			rectPos.y = globalPos.y
		EdgeOrientation.TOP:
			rectSize.y -= globalPos.y - rectPos.y
			rectPos.y = globalPos.y
		EdgeOrientation.TOP_RIGHT:
			rectSize.y -= globalPos.y - rectPos.y
			rectPos.y = globalPos.y
			rectSize.x = pos.x

	if maxSize.x != -1:
		rectSize.x = clamp(rectSize.x, custom_minimum_size.x, maxSize.x)
	if maxSize.y != -1:
		rectSize.y = clamp(rectSize.y, custom_minimum_size.y, maxSize.y)

	if rectPos.x < 0:
		rectPos.x = 0
	if rectPos.y < 0:
		rectPos.y = 0

	size = rectSize
	position = rectPos

func GetEdgeOrientation(pos : Vector2):
	var cornersArray = []
	var edgesArray = []

	if pos.y >= size.y - cornerSize:
		cornersArray.append(EdgeOrientation.BOTTOM)
		if pos.y >= size.y - edgeSize:
			edgesArray.append(EdgeOrientation.BOTTOM)
	elif pos.y <= cornerSize:
		cornersArray.append(EdgeOrientation.TOP)
		if pos.y <= edgeSize:
			edgesArray.append(EdgeOrientation.TOP)

	if pos.x >= size.x - cornerSize:
		cornersArray.append(EdgeOrientation.RIGHT)
		if pos.x >= size.x - edgeSize:
			edgesArray.append(EdgeOrientation.RIGHT)
	elif pos.x <= cornerSize:
		cornersArray.append(EdgeOrientation.LEFT)
		if pos.x <= edgeSize:
			edgesArray.append(EdgeOrientation.LEFT)

	if cornersArray.size() >= 2 && edgesArray.size() >= 1:
		match cornersArray[1]:
			EdgeOrientation.LEFT:
				match cornersArray[0]:
					EdgeOrientation.BOTTOM:	selectedEdge = EdgeOrientation.BOTTOM_LEFT
					EdgeOrientation.TOP:	selectedEdge = EdgeOrientation.TOP_LEFT
			EdgeOrientation.RIGHT:
				match cornersArray[0]:
					EdgeOrientation.BOTTOM:	selectedEdge = EdgeOrientation.BOTTOM_RIGHT
					EdgeOrientation.TOP:	selectedEdge = EdgeOrientation.TOP_RIGHT
	elif edgesArray.size() >= 1:
		selectedEdge = edgesArray[0]

	isResizing = selectedEdge != EdgeOrientation.NONE

func ResetWindowModifier():
	clickPosition	= Vector2.INF
	isResizing		= false
	selectedEdge 	= EdgeOrientation.NONE

func ToggleControl():
	EnableControl(!is_visible())

func EnableControl(state : bool):
	set_visible(state)
	if state:
		SetFloatingWindowToTop()

	if Launcher.Action && blockActions:
		Launcher.Action.Enable(!state)

func SetFloatingWindowToTop():
	set_draw_behind_parent(false)
	emit_signal('MoveFloatingWindowToTop', self)

func CanBlockActions():
	return blockActions

#
func OnGuiInput(event : InputEvent):
	if event is InputEventMouseButton:
		var isInPanel = event.position >= Vector2.ZERO && event.position <= size
		if isInPanel:
			if event.pressed:
				clickPosition = event.position
				GetEdgeOrientation(event.position)
				SetFloatingWindowToTop()
			else:
				ResetWindowModifier()
		else:
			ResetWindowModifier()

	if event is InputEventMouseMotion:
		if clickPosition != Vector2.INF:
			UpdateWindow(event.position)

func UpdateWindow(eventPosition : Vector2 = Vector2.ZERO):
	var floatingWindowSize : Vector2 = Launcher.GUI.windows.get_size()

	if isResizing:
		ResizeWindow(ClampFloatingWindow(eventPosition, floatingWindowSize), eventPosition + position)
	else:
		if clickPosition != Vector2.INF:
			position += eventPosition - clickPosition

		if get_minimum_size().x > 0 and get_minimum_size().y > 0:
			size.x = clamp(size.x, get_minimum_size().x, max(get_minimum_size().x, Launcher.GUI.windows.get_size().x))
			size.y = clamp(size.y, get_minimum_size().y, max(get_minimum_size().y, Launcher.GUI.windows.get_size().y))
			ClampToMargin(Launcher.GUI.windows.get_size())

func Center():
	reset_size()
	global_position = get_viewport_rect().size / 2 - get_rect().size / 2

#
func _on_CloseButton_pressed():
	set_visible(false)
