extends Control
class_name MenuIndicator

#
@onready var content : Control				= $MenuContent
@onready var items : Control				= $MenuContent/HBoxItems
@onready var button : Button				= $MenuButton

#
const MENU_SPEED : float					= 1.1
var tween : Tween							= null
var is_opening : bool						= false

#
func SetItemsVisible(toggle : bool):
	for node in items.get_children():
		if node is WindowButton:
			node.set_visible(toggle)
			if node.targetWindow and not toggle:
				node.targetWindow.EnableControl(toggle)

func SetupThresholds() -> Array[float]:
	var count : int = items.get_child_count()
	var inverted : bool = content.material.get_shader_parameter("inverted") as bool
	var thresholds : Array[float] = []
	for i in count:
		if inverted:
			thresholds.append(float(count - i) / float(count + 1))
		else:
			thresholds.append(float(i + 1) / float(count + 1))
	return thresholds

func UpdateIconsVisibility(progress : float, thresholds : Array[float]):
	var children : Array[Node] = items.get_children()
	for i in children.size():
		var child : Node = children[i]
		if child is Button:
			child.set_visible(progress >= thresholds[i])

#
func Close():
	if not is_opening:
		return
	is_opening = false

	if tween:
		tween.kill()

	var progress : float = content.material.get_shader_parameter("progress")
	var duration : float = progress / MENU_SPEED
	var thresholds : Array[float] = SetupThresholds()

	tween = create_tween()
	tween.tween_method(
		func(v : float):
			content.material.set_shader_parameter("progress", v)
			UpdateIconsVisibility(v, thresholds),
		progress, 0.0, duration
	)
	tween.tween_callback(func():
		items.set_visible(false)
	)

func _on_button_pressed():
	if not FSM.IsGameState():
		Launcher.GUI.ToggleControl(Launcher.GUI.settingsWindow)
		return

	if is_opening:
		Close()
		return

	is_opening = true

	if tween:
		tween.kill()

	var progress : float = content.material.get_shader_parameter("progress")
	var duration : float = absf(1.0 - progress) / MENU_SPEED
	var thresholds : Array[float] = SetupThresholds()

	for icon in items.get_children():
		icon.set_visible(false)
	items.set_visible(true)

	UpdateIconsVisibility(progress, thresholds)

	tween = create_tween()
	tween.tween_method(
		func(v : float):
			content.material.set_shader_parameter("progress", v)
			UpdateIconsVisibility(v, thresholds),
		progress, 1.0, duration
	)

#
func _ready():
	assert(content != null and content.material != null and items != null, "Menu Indicator nodes are not set correctly")
	content.material.set_shader_parameter("progress", 0.0)
	items.set_visible(false)
