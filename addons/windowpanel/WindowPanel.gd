@tool
extends Control

#
signal MoveFloatingWindowToTop

#
enum EdgeOrientation { NONE, RIGHT, BOTTOM_RIGHT, BOTTOM, BOTTOM_LEFT, LEFT, TOP_LEFT, TOP, TOP_RIGHT }

#
const edgeSize			= 5
const cornerSize		= 15
var clickPosition		= null
var isResizing			= false
var selectedEdge		= EdgeOrientation.NONE

#
func ClampViewport(globalPos, moveLimit):
	if selectedEdge == EdgeOrientation.BOTTOM_LEFT || selectedEdge == EdgeOrientation.LEFT || selectedEdge == EdgeOrientation.TOP_LEFT:
		moveLimit.x -= custom_minimum_size.x
	elif selectedEdge == EdgeOrientation.TOP_LEFT || selectedEdge == EdgeOrientation.TOP || selectedEdge == EdgeOrientation.TOP_RIGHT:
		moveLimit.y -= custom_minimum_size.y
	return Vector2( clamp(globalPos.x, 0, moveLimit.x), clamp(globalPos.y, 0, moveLimit.y))

func ResizeWindow(globalPos):
	var rectSize = size
	var rectPos = position

	match selectedEdge:
		EdgeOrientation.RIGHT:
			rectSize.x = globalPos.x - rectPos.x
		EdgeOrientation.BOTTOM_RIGHT:
			rectSize.x = globalPos.x - rectPos.x
			rectSize.y = globalPos.y - rectPos.y
		EdgeOrientation.BOTTOM:
			rectSize.y = globalPos.y - rectPos.y
		EdgeOrientation.BOTTOM_LEFT:
			rectSize.x += rectPos.x - globalPos.x
			if rectSize.x < custom_minimum_size.x:
				rectPos.x = globalPos.x + (rectSize.x - custom_minimum_size.x)
			else:
				rectPos.x = globalPos.x
			rectSize.y = globalPos.y - rectPos.y
		EdgeOrientation.LEFT:
			rectSize.x += rectPos.x - globalPos.x
			if rectSize.x < custom_minimum_size.x:
				rectPos.x = globalPos.x + (rectSize.x - custom_minimum_size.x)
			else:
				rectPos.x = globalPos.x
		EdgeOrientation.TOP_LEFT:
			rectSize.x += rectPos.x - globalPos.x
			if rectSize.x < custom_minimum_size.x:
				rectPos.x = globalPos.x + (rectSize.x - custom_minimum_size.x)
			else:
				rectPos.x = globalPos.x
			rectSize.y += rectPos.y - globalPos.y
			if rectSize.y < custom_minimum_size.y:
				rectPos.y = globalPos.y + (rectSize.y - custom_minimum_size.y)
			else:
				rectPos.y = globalPos.y
		EdgeOrientation.TOP:
			rectSize.y += rectPos.y - globalPos.y
			if rectSize.y < custom_minimum_size.y:
				rectPos.y = globalPos.y + (rectSize.y - custom_minimum_size.y)
			else:
				rectPos.y = globalPos.y
		EdgeOrientation.TOP_RIGHT:
			rectSize.x = globalPos.x - rectPos.x
			rectSize.y += rectPos.y - globalPos.y
			if rectSize.y < custom_minimum_size.y:
				rectPos.y = globalPos.y + (rectSize.y - custom_minimum_size.y)
			else:
				rectPos.y = globalPos.y

	size = rectSize
	position = rectPos

func GetEdgeOrientation(pos):
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
	clickPosition	= null
	isResizing		= false
	selectedEdge 	= EdgeOrientation.NONE

func SetFloatingWindowToTop():
	set_draw_behind_parent(false)
	emit_signal('MoveFloatingWindowToTop', self)

#
func _on_window_gui_input(event):
	if event is InputEventMouseButton:
		var rescaledPanelPosition = event.global_position - position
		var isInPanel = rescaledPanelPosition >= Vector2(0,0) && rescaledPanelPosition <= size
		if isInPanel:
			if event.pressed:
				clickPosition = event.global_position - global_position
				GetEdgeOrientation(rescaledPanelPosition)
				SetFloatingWindowToTop()
			else:
				ResetWindowModifier()

	if event is InputEventMouseMotion:
		if clickPosition:
			var viewport = get_viewport().get_size()
			var globalPosition = event.global_position
			if isResizing:
				ResizeWindow(ClampViewport(globalPosition, viewport))
			else:
				viewport -= (Vector2i) (get_size())
				globalPosition -= clickPosition
				global_position = ClampViewport(globalPosition, viewport)

func _on_window_mouse_exited():
	ResetWindowModifier()

func _on_CloseButton_pressed():
	set_visible(false)
