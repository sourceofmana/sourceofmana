tool
extends Control

signal MoveFloatingWindowToTop

enum EdgeOrientation { NONE, RIGHT, BOTTOM_RIGHT, BOTTOM, BOTTOM_LEFT, LEFT, TOP_LEFT, TOP, TOP_RIGHT }

const edgeSize			= 5
const cornerSize		= 15
var clickPosition		= null
var isResizing			= false
var selectedEdge		= EdgeOrientation.NONE


func ClampViewport(globalPos, moveLimit):
	return Vector2( clamp(globalPos.x, 0, moveLimit.x), clamp(globalPos.y, 0, moveLimit.y))

func ResizeWindow(globalPos):
	match selectedEdge:
		EdgeOrientation.RIGHT:
			rect_size.x = globalPos.x - rect_position.x
		EdgeOrientation.BOTTOM_RIGHT:
			rect_size.x = globalPos.x - rect_position.x
			rect_size.y = globalPos.y - rect_position.y
		EdgeOrientation.BOTTOM:
			rect_size.y = globalPos.y - rect_position.y
		EdgeOrientation.BOTTOM_LEFT:
			rect_size.x += rect_position.x - globalPos.x
			rect_position.x = globalPos.x
			rect_size.y = globalPos.y - rect_position.y
		EdgeOrientation.LEFT:
			rect_size.x += rect_position.x - globalPos.x
			rect_position.x = globalPos.x
		EdgeOrientation.TOP_LEFT:
			rect_size.x += rect_position.x - globalPos.x
			rect_position.x = globalPos.x
			rect_size.y += rect_position.y - globalPos.y
			rect_position.y = globalPos.y
		EdgeOrientation.TOP:
			rect_size.y += rect_position.y - globalPos.y
			rect_position.y = globalPos.y
		EdgeOrientation.TOP_RIGHT:
			rect_size.x = globalPos.x - rect_position.x
			rect_size.y += rect_position.y - globalPos.y
			rect_position.y = globalPos.y

func GetEdgeOrientation(pos):
	var cornersArray = []
	var edgesArray = []

	if pos.y >= rect_size.y - cornerSize:
		cornersArray.append(EdgeOrientation.BOTTOM)
		if pos.y >= rect_size.y - edgeSize:
			edgesArray.append(EdgeOrientation.BOTTOM)
	elif pos.y <= cornerSize:
		cornersArray.append(EdgeOrientation.TOP)
		if pos.y <= edgeSize:
			edgesArray.append(EdgeOrientation.TOP)

	if pos.x >= rect_size.x - cornerSize:
		cornersArray.append(EdgeOrientation.RIGHT)
		if pos.x >= rect_size.x - edgeSize:
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

func _ready():
	hint_tooltip = name

func _on_window_gui_input(event):
	if event is InputEventMouseButton:
		var rescaledPanelPosition = event.global_position - rect_position
		var isInPanel = rescaledPanelPosition >= Vector2(0,0) && rescaledPanelPosition <= rect_size
		if isInPanel:
			if event.pressed:
				clickPosition = event.global_position - rect_global_position
				GetEdgeOrientation(rescaledPanelPosition)
				emit_signal('MoveFloatingWindowToTop', self)
			else:
				ResetWindowModifier()

	if event is InputEventMouseMotion:
		if clickPosition:
			var viewport = get_viewport().get_size()
			var globalPosition = event.global_position
			if isResizing:
				ResizeWindow(ClampViewport(globalPosition, viewport))
			else:
				viewport -= get_size()
				globalPosition -= clickPosition
				rect_global_position = ClampViewport(globalPosition, viewport)

func _on_window_mouse_exited():
	ResetWindowModifier()
