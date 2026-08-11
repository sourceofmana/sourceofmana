extends PanelContainer
class_name ContextMenu

@export var fadeInDelay : float				= 1.0
@export var displayDelay : float			= UICommons.DisplayActionShortDelaySec
@export var fadeOutDelay : float			= 2.0
@export var persistant : bool				= true

@onready var contextList : Control			= $Margin/List

var buffer : Array[ContextData]				= []
var fadeTween : Tween						= null
var actionDisabled : bool					= false

#
func FlushDataBuffer():
	while not buffer.is_empty():
		var data : ContextData = buffer.pop_front()
		var action : Control = UICommons.ContextAction.instantiate()
		action.Init(data, self)
		contextList.add_child.call_deferred(action)

func KillTween():
	if fadeTween:
		fadeTween.kill()
		fadeTween = null

func StartFadeIn(canFadeOut : bool, duration : float = -1.0):
	KillTween()
	var startAlpha : float = modulate.a
	fadeTween = create_tween()
	if fadeInDelay > 0.0:
		var remainingFadeIn : float = (1.0 - startAlpha) * fadeInDelay
		if remainingFadeIn > 0.0:
			fadeTween.tween_property(self, "modulate:a", 1.0, remainingFadeIn)
	else:
		modulate.a = 1.0
	if canFadeOut:
		fadeTween.tween_interval(duration if duration > 0.0 else displayDelay)
		AppendFadeOut(fadeTween)

func AppendFadeOut(tw : Tween):
	if fadeOutDelay > 0.0:
		tw.tween_property(self, "modulate:a", 0.0, fadeOutDelay)
	else:
		tw.tween_callback(func(): modulate.a = 0.0)
	tw.tween_callback(Hide)

func Push(data : ContextData):
	buffer.push_back(data)

func FadeIn(disableAction : bool = false, duration : float = -1.0):
	Show(disableAction)
	FlushDataBuffer()
	StartFadeIn(not persistant, duration)

func FadeOut():
	KillTween()
	var currentAlpha : float = modulate.a
	if currentAlpha <= 0.0:
		Hide()
		return
	fadeTween = create_tween()
	if fadeOutDelay > 0.0:
		fadeTween.tween_property(self, "modulate:a", 0.0, currentAlpha * fadeOutDelay)
	else:
		modulate.a = 0.0
	fadeTween.tween_callback(Hide)

func Show(disableAction : bool):
	visible = true
	for child in contextList.get_children():
		child._on_visibility_changed()
	if Launcher.Action and disableAction:
		actionDisabled = true
		Launcher.Action.Enable(false)

func Hide():
	KillTween()
	visible = false
	modulate.a = 0.0
	if Launcher.Action and actionDisabled:
		Launcher.Action.Enable(true)
		actionDisabled = false
	Clear()

func Clear():
	for child in contextList.get_children():
		contextList.remove_child(child)
		child.queue_free()

#
func _ready():
	Hide()
