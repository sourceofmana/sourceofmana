extends BaseEntity
class_name NpcEntity

#
func Trigger():
	if interactive:
		interactive.DisplaySpeech("Hello!")

#
func _ready():
	super._ready()
	if interactive:
		interactive.Setup(self)
