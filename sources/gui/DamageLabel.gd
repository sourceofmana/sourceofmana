extends Label

#
var timeLeft : float						= 3.0
var fadingTime : float						= 1.0
var velocity : Vector2						= Vector2.ZERO
var criticalDamage : bool					= false
var HSVA : Vector4							= Vector4.ZERO
var floorPosition : float					= 0.0

const gravityRedux : float					= 180.0
const maxVelocityAngle : float				= 36
const minVelocitySpeed : float				= 24.0
const maxVelocitySpeed : float				= 60.0
const overheadOffset : int					= -10

#
func SetPosition(startPos : Vector2, floorPos : Vector2):
	position = startPos
	floorPosition = floorPos.y

func SetDamage(damage : int, isTargetLocal : bool, isDealerLocal : bool, isCrit : bool):
	var hue : float = 0.0
	if damage == 0:
		hue = EntityCommons.MissAttackColor
	elif isDealerLocal:
		hue = EntityCommons.LocalAttackColor
	elif isTargetLocal:
		hue = EntityCommons.LocalDamageColor
	else:
		hue = 0.55

	HSVA = Vector4(hue, 0.8, 1.0, 1.0)
	criticalDamage = isCrit

	velocity.x = randf_range(-maxVelocityAngle, maxVelocityAngle)
	velocity.y = randf_range(minVelocitySpeed, maxVelocitySpeed)

	add_theme_color_override("font_color", Color.from_hsv(HSVA.x, HSVA.y, HSVA.z, HSVA.w))
	add_theme_color_override("font_outline_color", Color.from_hsv(HSVA.x, HSVA.y, 0.0, HSVA.w))
	set_text(str(damage) if damage > 0 else "miss")

#
func _process(delta):
	timeLeft -= delta
	if timeLeft <= 0.0: 
		queue_free()
		return

	if timeLeft < fadingTime:
		modulate.a = timeLeft / fadingTime

	var deltaVelocity : Vector2 = velocity * delta
	if position.y - deltaVelocity.y >= floorPosition:
		velocity.y = -velocity.y
		velocity.y *= 0.66
	position -= deltaVelocity
	velocity.y -= gravityRedux * delta

	if criticalDamage:
		HSVA.x = HSVA.x + delta * 2
		if HSVA.x > 1.0:
			HSVA.x = 0.0
		if HSVA.x > 0.3 and HSVA.x < 0.7:
			HSVA.x = 0.7

		add_theme_color_override("font_color", Color.from_hsv(HSVA.x, HSVA.y, HSVA.z, HSVA.w))
		add_theme_color_override("font_outline_color", Color.from_hsv(HSVA.x, HSVA.y, 0.2, HSVA.w))
