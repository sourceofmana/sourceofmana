extends BaseEntity
class_name NpcEntity

#
func Trigger():
	if interactive:
		interactive.DisplaySpeech("Hello!")

#
func _physics_process(deltaTime : float):
	super._physics_process(deltaTime)
	if interactive:
		interactive.Update(self, false)

func _ready():
	super._ready()
	if interactive:
		interactive.Setup(self, false)
