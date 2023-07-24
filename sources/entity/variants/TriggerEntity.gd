extends NpcEntity
class_name TriggerEntity

var triggered : bool = false

#
func Interact():
	if triggered == false:
		$AnimationPlayer.play("To Trigger")
		triggered = true
	else:
		$AnimationPlayer.play("From Trigger")
		triggered = false

#
func _ready():
	super._ready()
