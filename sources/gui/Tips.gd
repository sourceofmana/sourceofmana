extends PanelContainer

@export var fadeInDelay : float		= 1.0
@export var displayDelay : float	= 6.0
@export var fadeOutDelay : float	= 8.0

var currentDelay : float			= 0.0

#
func initialize():
	currentDelay = 0.0
	visible = true

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
