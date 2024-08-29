extends PanelContainer
class_name ContextMenu

@export var fadeInDelay : float				= 1.0
@export var displayDelay : float			= 5.0
@export var fadeOutDelay : float			= 2.0
@export var persistant : bool				= true

@onready var contextList : Control			= $Margin/List

var buffer : Array[ContextData]				= []
var currentStep : float						= 0.0
var fadeInStep : float						= 0.0
var displayStep : float						= 0.0
var fadeOutStep : float						= 0.0

var canFadeOut : bool						= false

#
func FlushDataBuffer():
	while buffer.size() > 0:
		var data : ContextData = buffer.pop_front()
		var action : Control = UICommons.ContextAction.instantiate()
		action.Init(data, self)
		contextList.add_child.call_deferred(action)

func ResetSteps():
	fadeInStep = fadeInDelay
	displayStep = fadeInStep + displayDelay
	fadeOutStep = displayStep + displayDelay

	if currentStep >= displayStep:
		if fadeOutDelay > 0:
			currentStep = (1 - (currentStep - displayStep) / fadeOutDelay) * fadeInStep
		else:
			currentStep = 0.0

func Push(data : ContextData):
	buffer.push_back(data)

func FadeIn(disableAction : bool = false):
	ResetSteps()
	Show(disableAction)
	FlushDataBuffer()

	canFadeOut = not persistant

func FadeOut():
	if currentStep < fadeInStep:
		if fadeInStep > 0:
			currentStep = (1 - currentStep / fadeInStep) * fadeOutDelay + displayStep
		else:
			currentStep = displayStep
	elif currentStep < displayStep:
		currentStep = displayStep

	canFadeOut = true

func Show(disableAction):
	visible = true
	for child in contextList.get_children():
		child._on_visibility_changed()
	Launcher.Action.Enable(not disableAction)

func Hide():
	visible = false
	canFadeOut = false
	currentStep = 0.0
	Launcher.Action.Enable(true)
	Clear()

func Clear():
	for child in contextList.get_children():
		contextList.remove_child(child)
		child.queue_free()

#
func _process(delta):
	if not visible:
		return

	if canFadeOut or currentStep <= displayStep:
		currentStep += delta
		if currentStep <= fadeInStep:
			if fadeInStep > 0.0:
				modulate.a = currentStep / fadeInStep
		elif currentStep <= displayStep:
			if displayStep > 0.0:
				modulate.a = 1.0
		elif canFadeOut:
			if currentStep <= fadeOutStep:
				if fadeOutDelay > 0.0:
					modulate.a = 1.0 - (currentStep - displayStep) / fadeOutDelay
			else:
				Hide()

func _ready():
	Hide()
