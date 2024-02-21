extends PanelContainer

@onready var levelLabel : Label			= $VBoxContainer/Level
@onready var nameLabel : Label			= $VBoxContainer/Name
@onready var hpLabel : Label			= $VBoxContainer/HP

var entity : BaseEntity					= null

func _ready():
	if entity:
		nameLabel.text += str(entity.entityName)
		levelLabel.text += str(entity.stat.level)
		hpLabel.text += str(entity.stat.health)
		visible = true
		Callback.SelfDestructTimer(self, 5.0, queue_free, "ToolTipQueueFree")
