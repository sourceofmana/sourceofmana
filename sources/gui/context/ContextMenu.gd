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
var actionDisabled : bool					= false

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
	_process(0) # Force refresh

func Push(data : ContextData):
	buffer.push_back(data)

func FadeIn(disableAction : bool = false):
	ResetSteps()
	Show(disableAction)
	FlushDataBuffer()

	canFadeOut = not persistant
	_process(0)

func FadeOut():
	if currentStep < fadeInStep:
		if fadeInStep > 0:
			currentStep = (1 - currentStep / fadeInStep) * fadeOutDelay + displayStep
		else:
			currentStep = displayStep
	elif currentStep < displayStep:
		currentStep = displayStep

	canFadeOut = true
	_process(0)

func Show(disableAction : bool):
	visible = true
	for child in contextList.get_children():
		child._on_visibility_changed()
	if Launcher.Action and disableAction:
		actionDisabled = true
		Launcher.Action.Enable(false)

func Hide():
	visible = false
	canFadeOut = false
	currentStep = 0.0
	if Launcher.Action and actionDisabled:
		Launcher.Action.Enable(true)
		actionDisabled = false
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
