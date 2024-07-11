extends RichTextLabel

@onready var tip : ButtonTip = $ButtonTip

#
func Init(title : String, action : StringName, callback : Callable):
	set_text(title) 
	Callback.OneShotCallback(ready, Setup, [action, callback])

func Setup(action : StringName, callback : Callable):
	if tip:
		tip.Setup(action, callback)
