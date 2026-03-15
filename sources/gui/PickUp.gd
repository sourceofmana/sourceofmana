extends Control

#
@export var openSpeed : float	= 4.0
@export var closeSpeed : float	= 1.5

@onready var clip : Control				= $ClipContainer
@onready var panel : PanelContainer		= $ClipContainer/PanelContainer
@onready var container : HBoxContainer	= $ClipContainer/PanelContainer/HBoxContainer
@onready var timer : Timer				= $Timer

var tween : Tween		= null
var timestampsMs : Array	= []
var openGen : int		= 0

#
func AddLast(cell : BaseCell, count : int):
	if count > 0 and cell != null:
		var wasEmpty : bool = timestampsMs.is_empty()
		timestampsMs.push_back(Time.get_ticks_msec())
		var tile : CellTile = UICommons.CellTilePreset.instantiate()
		tile.ready.connect(tile.AssignData.bind(cell, count))
		container.add_child.call_deferred(tile)
		AnimateOpen.call_deferred()
		if wasEmpty:
			timer.start(UICommons.DelayPickUpNotification / 1000.0)

func RemoveOldest():
	var child : Control = container.get_child(0)
	if child:
		container.remove_child(child)

func RemoveAll():
	for child in container.get_children():
		if child:
			container.remove_child(child)
	timestampsMs.clear()

#
func Animate(targetHalf : float, speed : float, callable : Callable = Callable()):
	var panelHalf : float = panel.size.x * 0.5
	if panelHalf <= 0.0 or speed == 0.0:
		if callable.is_valid():
			callable.call()
		return
	if tween:
		tween.kill()
	var currentHalf : float = clip.offset_right
	panel.position.x = currentHalf - panelHalf
	var duration : float = absf(targetHalf - currentHalf) / (panelHalf * speed)
	tween = create_tween()
	tween.tween_method(
		func(v : float):
			clip.offset_left = -v
			clip.offset_right = v
			panel.position.x = v - panelHalf,
		currentHalf, targetHalf, duration
	)
	if callable.is_valid():
		tween.tween_callback(callable)

func AnimateOpen():
	var gen : int = openGen
	await get_tree().process_frame
	if gen != openGen:
		return
	if not visible:
		visible = true
		clip.offset_left = 0.0
		clip.offset_right = 0.0
	panel.reset_size()
	var panelHalf : float = panel.size.x * 0.5
	Animate(panelHalf, openSpeed)

func AnimateClose():
	openGen += 1
	Animate(0.0, closeSpeed, func():
		RemoveAll()
		visible = false
	)

#
func _on_timer_timeout():
	if timestampsMs.size() > 1:
		RemoveOldest()
		timestampsMs.pop_front()
		var remaining : float = (timestampsMs[0] + UICommons.DelayPickUpNotification - Time.get_ticks_msec()) / 1000.0
		timer.start(maxf(remaining, 0.0))
		AnimateOpen.call_deferred()
	else:
		timestampsMs.pop_front()
		AnimateClose()

#
func _ready():
	clip.offset_left = 0.0
	clip.offset_right = 0.0
	visible = false
