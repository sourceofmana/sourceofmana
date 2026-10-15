extends PanelContainer
class_name WindowPanel

#
signal MoveFloatingWindowToTop

#
enum EdgeOrientation { NONE, RIGHT, BOTTOM_RIGHT, BOTTOM, BOTTOM_LEFT, LEFT, TOP_LEFT, TOP, TOP_RIGHT }
enum ResizableEdge { LEFT = 1, TOP = 2, RIGHT = 4, BOTTOM = 8 }

#
@export var blockActions : bool		= false
@export var saveOverlayState : bool	= false
@export var allowAutomaticResize : bool = false
@export var maxSize : Vector2		= Vector2(-1, -1)
@export var floating : bool			= true
@export var draggable : bool		= true
@export_flags("Left", "Top", "Right", "Bottom") var resizableEdges : int = 15
const edgeSize : int				= 6
const cornerSize : int				= 10
var clickPosition : Vector2			= Vector2.INF
var isResizing : bool				= false
var selectedEdge : EdgeOrientation	= EdgeOrientation.NONE

#
func ClampFloatingWindow(globalPos : Vector2, moveLimit : Vector2):
	if selectedEdge == EdgeOrientation.BOTTOM_LEFT || selectedEdge == EdgeOrientation.LEFT || selectedEdge == EdgeOrientation.TOP_LEFT:
		moveLimit.x -= custom_minimum_size.x
	if selectedEdge == EdgeOrientation.TOP_LEFT || selectedEdge == EdgeOrientation.TOP || selectedEdge == EdgeOrientation.TOP_RIGHT:
		moveLimit.y -= custom_minimum_size.y
	return Vector2( clampf(globalPos.x, 0.0, moveLimit.x), clampf(globalPos.y, 0.0, moveLimit.y))

func ClampToMargin(marginSize : Vector2):
	position = ClampFloatingWindow(position, marginSize - size)

func ResizeWindow(pos : Vector2, globalPos : Vector2):
	var previousSize : Vector2 = size
	var previousPosition : Vector2 = position
	var rectSize = previousSize
	var rectPos = previousPosition
	var isLeftEdge : bool = selectedEdge in [EdgeOrientation.LEFT, EdgeOrientation.TOP_LEFT, EdgeOrientation.BOTTOM_LEFT]
	var isTopEdge : bool = selectedEdge in [EdgeOrientation.TOP, EdgeOrientation.TOP_LEFT, EdgeOrientation.TOP_RIGHT]

	match selectedEdge:
		EdgeOrientation.RIGHT:
			rectSize.x = pos.x
		EdgeOrientation.BOTTOM_RIGHT:
			rectSize = pos
		EdgeOrientation.BOTTOM:
			rectSize.y = pos.y
		EdgeOrientation.BOTTOM_LEFT:
			rectSize.x -= globalPos.x - rectPos.x
			rectSize.y = pos.y
		EdgeOrientation.LEFT:
			rectSize.x -= globalPos.x - rectPos.x
		EdgeOrientation.TOP_LEFT:
			rectSize.x -= globalPos.x - rectPos.x
			rectSize.y -= globalPos.y - rectPos.y
		EdgeOrientation.TOP:
			rectSize.y -= globalPos.y - rectPos.y
		EdgeOrientation.TOP_RIGHT:
			rectSize.y -= globalPos.y - rectPos.y
			rectSize.x = pos.x

	if maxSize.x != -1:
		rectSize.x = min(rectSize.x, maxSize.x)
	if maxSize.y != -1:
		rectSize.y = min(rectSize.y, maxSize.y)

	size = rectSize
	var appliedSize : Vector2 = size

	if isLeftEdge:
		rectPos.x = previousPosition.x + previousSize.x - appliedSize.x
	if isTopEdge:
		rectPos.y = previousPosition.y + previousSize.y - appliedSize.y

	if rectPos.x < 0:
		rectPos.x = 0
	if rectPos.y < 0:
		rectPos.y = 0

	position = rectPos

func GetEdgeOrientation(pos : Vector2) -> EdgeOrientation:
	var cornersArray = []
	var edgesArray = []
	var edge : EdgeOrientation = EdgeOrientation.NONE

	if pos.y >= size.y - cornerSize and resizableEdges & ResizableEdge.BOTTOM:
		cornersArray.append(EdgeOrientation.BOTTOM)
		if pos.y >= size.y - edgeSize:
			edgesArray.append(EdgeOrientation.BOTTOM)
	elif pos.y <= cornerSize and resizableEdges & ResizableEdge.TOP:
		cornersArray.append(EdgeOrientation.TOP)
		if pos.y <= edgeSize:
			edgesArray.append(EdgeOrientation.TOP)

	if pos.x >= size.x - cornerSize and resizableEdges & ResizableEdge.RIGHT:
		cornersArray.append(EdgeOrientation.RIGHT)
		if pos.x >= size.x - edgeSize:
			edgesArray.append(EdgeOrientation.RIGHT)
	elif pos.x <= cornerSize and resizableEdges & ResizableEdge.LEFT:
		cornersArray.append(EdgeOrientation.LEFT)
		if pos.x <= edgeSize:
			edgesArray.append(EdgeOrientation.LEFT)

	if cornersArray.size() >= 2 && edgesArray.size() >= 1:
		match cornersArray[1]:
			EdgeOrientation.LEFT:
				match cornersArray[0]:
					EdgeOrientation.BOTTOM:	edge = EdgeOrientation.BOTTOM_LEFT
					EdgeOrientation.TOP:	edge = EdgeOrientation.TOP_LEFT
			EdgeOrientation.RIGHT:
				match cornersArray[0]:
					EdgeOrientation.BOTTOM:	edge = EdgeOrientation.BOTTOM_RIGHT
					EdgeOrientation.TOP:	edge = EdgeOrientation.TOP_RIGHT
	elif edgesArray.size() >= 1:
		edge = edgesArray[0]

	return edge

func GetCursorForEdge(edge : EdgeOrientation) -> DeviceManager.CursorType:
	match edge:
		EdgeOrientation.RIGHT, EdgeOrientation.LEFT:
			return DeviceManager.CursorType.RESIZE_HORIZONTAL
		EdgeOrientation.TOP, EdgeOrientation.BOTTOM:
			return DeviceManager.CursorType.RESIZE_VERTICAL
		EdgeOrientation.TOP_LEFT, EdgeOrientation.BOTTOM_RIGHT:
			return DeviceManager.CursorType.RESIZE_DIAGONAL_BACK
		EdgeOrientation.TOP_RIGHT, EdgeOrientation.BOTTOM_LEFT:
			return DeviceManager.CursorType.RESIZE_DIAGONAL_FORWARD
		_:
			return DeviceManager.CursorType.DEFAULT

func RefreshResizeCursor(edge : EdgeOrientation):
	if edge == EdgeOrientation.NONE:
		DeviceManager.ResetCursor()
	else:
		DeviceManager.SetCursor(GetCursorForEdge(edge))

func _notification(what : int):
	if what == NOTIFICATION_MOUSE_EXIT and clickPosition == Vector2.INF:
		DeviceManager.ResetCursor()

func ResetWindowModifier():
	clickPosition	= Vector2.INF
	isResizing		= false
	selectedEdge 	= EdgeOrientation.NONE
	DeviceManager.ResetCursor()

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
func IsWithinResizeMargin(pos : Vector2) -> bool:
	return pos >= -Vector2.ONE * cornerSize && pos <= size + Vector2.ONE * cornerSize

func OnGuiInput(event : InputEvent):
	if event is InputEventMouseButton:
		var isInPanel = IsWithinResizeMargin(event.position)
		if isInPanel:
			if event.pressed:
				clickPosition = event.position
				selectedEdge = GetEdgeOrientation(event.position)
				isResizing = selectedEdge != EdgeOrientation.NONE
				SetFloatingWindowToTop()
				RefreshResizeCursor(selectedEdge)
			else:
				ResetWindowModifier()
		else:
			ResetWindowModifier()

	if event is InputEventMouseMotion:
		if clickPosition != Vector2.INF:
			UpdateWindow(event.position)
		else:
			var isInPanel = IsWithinResizeMargin(event.position)
			RefreshResizeCursor(GetEdgeOrientation(event.position) if isInPanel else EdgeOrientation.NONE)

func UpdateWindow(eventPosition : Vector2 = Vector2.ZERO):
	var floatingWindowSize : Vector2 = Launcher.GUI.windows.get_size()

	if isResizing:
		ResizeWindow(ClampFloatingWindow(eventPosition, floatingWindowSize), ClampFloatingWindow(eventPosition + position, floatingWindowSize))
	else:
		if clickPosition != Vector2.INF and draggable:
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
