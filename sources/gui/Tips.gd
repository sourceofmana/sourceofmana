extends PanelContainer

@export var fadeInDelay : float				= 1.0
@export var displayDelay : float			= 6.0
@export var fadeOutDelay : float			= 8.0
@export var actions : Array[StringName]		= []

@onready var tips : Control					= $MarginContainer/TipsList
@onready var tipNode : PackedScene			= preload("res://presets/gui/TipNode.tscn")

var currentDelay : float					= 0.0

#
func Display():
	currentDelay = 0.0
	visible = true

#
func _process(delta):
	currentDelay += delta
	if currentDelay <= fadeInDelay:
		if fadeInDelay > 0.0:
			modulate.a = currentDelay / fadeInDelay
	elif currentDelay <= displayDelay:
		if displayDelay > 0.0:
			modulate.a = 1.0
	elif currentDelay <= fadeOutDelay:
		if fadeOutDelay > 0.0:
			modulate.a = 1.0 - (currentDelay - displayDelay) / (fadeOutDelay - displayDelay)
	else:
		visible = false

func _ready():
	visible = false

	for child in tips.get_children():
		tips.remove_child(child)

	for action in actions:
		if InputMap.action_get_events(action).size() > 0:
			var actionInfo : Array = DeviceManager.GetActionInfo(action)
			if actionInfo.size() == DeviceManager.ActionInfo.COUNT:
				var tip : Control = tipNode.instantiate()
				var tipIcon : Label = tip.get_node("Icon")
				var tipLabel : Label = tip.get_node("Label")
				if tip and tipIcon and tipLabel:
					match actionInfo[DeviceManager.ActionInfo.DEVICE_TYPE]:
						DeviceManager.DeviceType.KEYBOARD:
							tipIcon.set_theme_type_variation("KeyTip")
						DeviceManager.DeviceType.JOYSTICK:
							tipIcon.set_theme_type_variation("ButtonTip")
						_:
							Util.Assert(false, "Device Type not recognized")
					tipIcon.set_text(actionInfo[DeviceManager.ActionInfo.NAME])
					tipLabel.set_text(DeviceManager.GetActionName(action))
					tips.add_child.call_deferred(tip)
