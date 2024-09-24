extends Label

#
var timeLeft : float						= 3.0
var fadingTime : float						= 1.0
var velocity : Vector2						= Vector2.ZERO
var criticalHit : bool					= false
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

func SetValue(dealer : Entity, value : int, alteration : ActorCommons.Alteration):
	var hue : float = 0.0
	match alteration:
		ActorCommons.Alteration.CRIT:
			criticalHit = true
			set_text(str(value))
		ActorCommons.Alteration.DODGE:
			hue = ActorCommons.DodgeAttackColor
			set_text("dodge")
		ActorCommons.Alteration.HIT:
			if dealer == Launcher.Player:
				hue = ActorCommons.LocalAttackColor
			elif dealer.type == ActorCommons.Type.PLAYER:
				hue = ActorCommons.PlayerAttackColor
			else:
				hue = ActorCommons.MonsterAttackColor
			set_text(str(value))
		ActorCommons.Alteration.MISS:
			hue = ActorCommons.MissAttackColor
			set_text("miss")
		ActorCommons.Alteration.HEAL:
			hue = ActorCommons.HealColor
			set_text(str(value))
		_:
			assert(false, "Alteration type not handled: " + str(alteration))

	HSVA = Vector4(hue, 0.8, 1.0, 1.0)

	velocity.x = randf_range(-maxVelocityAngle, maxVelocityAngle)
	velocity.y = randf_range(minVelocitySpeed, maxVelocitySpeed)

	add_theme_color_override("font_color", Color.from_hsv(HSVA.x, HSVA.y, HSVA.z, HSVA.w))
	add_theme_color_override("font_outline_color", Color.from_hsv(HSVA.x, HSVA.y, 0.0, HSVA.w))

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

	if criticalHit:
		HSVA.x = HSVA.x + delta * 2
		if HSVA.x > 1.0:
			HSVA.x = 0.0
		if HSVA.x > 0.3 and HSVA.x < 0.7:
			HSVA.x = 0.7

		add_theme_color_override("font_color", Color.from_hsv(HSVA.x, HSVA.y, HSVA.z, HSVA.w))
		add_theme_color_override("font_outline_color", Color.from_hsv(HSVA.x, HSVA.y, 0.2, HSVA.w))
