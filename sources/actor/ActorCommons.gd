extends Object
class_name ActorCommons

#
enum Type
{
	PLAYER = 0,
	MONSTER,
	NPC
}

enum Gender
{
	MALE = 0,
	FEMALE,
	NONBINARY,
	COUNT
}

enum State
{
	UNKNOWN = -1,
	IDLE = 0,
	WALK,
	SIT,
	ATTACK,
	DEATH,
	TO_TRIGGER,
	TRIGGER,
	FROM_TRIGGER,
	COUNT
}

enum Slot
{
	BODY = 0,
	HAIR,
	CHEST,
	LEGS,
	FEET,
	HANDS,
	HEAD,
	FACE,
	WEAPON,
	SHIELD,
	COUNT
}

enum Attribute
{
	STRENGTH = 0,
	VITALITY,
	AGILITY,
	ENDURANCE,
	CONCENTRATION,
}

const playbackParameter : String = "parameters/playback"

# Skip TO_TRIGGER & FROM_TRIGGER as they are only used as transition steps between idle/trigger.
const stateTransitions : Array[Array] = [
#	IDLE			WALK			SIT				ATTACK			DEATH			TO_TRIGGER		TRIGGER			FROM_TRIGGER		< To/From v
	[State.IDLE,	State.WALK,		State.SIT,		State.ATTACK,	State.DEATH,	State.IDLE,		State.TRIGGER,	State.IDLE],		# IDLE
	[State.IDLE,	State.WALK,		State.WALK,		State.ATTACK,	State.DEATH,	State.IDLE,		State.TRIGGER,	State.IDLE],		# WALK
	[State.SIT,		State.WALK,		State.IDLE,		State.ATTACK,	State.DEATH,	State.IDLE,		State.TRIGGER,	State.IDLE],		# SIT
	[State.IDLE,	State.WALK,		State.ATTACK,	State.ATTACK,	State.DEATH,	State.IDLE,		State.TRIGGER,	State.IDLE],		# ATTACK
	[State.DEATH,	State.DEATH,	State.DEATH,	State.DEATH,	State.DEATH,	State.DEATH,	State.DEATH,	State.DEATH],		# DEATH
	[],																																	# TO_TRIGGER
	[State.TRIGGER,	State.TRIGGER,	State.SIT,		State.ATTACK,	State.DEATH,	State.TRIGGER,	State.IDLE,		State.TRIGGER],		# TRIGGER
	[]																																	# FROM_TRIGGER
]

const stateIdle : String					= "Idle"
const stateWalk : String					= "Walk"
const stateSit : String						= "Sit"
const stateAttack : String					= "Attack"
const stateDeath : String					= "Death"
const stateToTrigger : String				= "To Trigger"
const stateTrigger : String					= "Trigger"
const stateFromTrigger : String				= "From Trigger"

# State
static func GetNextTransition(currentState : State, newState : State) -> State:
	return stateTransitions[currentState][newState]

static func GetStateName(state : State) -> String:
	match state:
		State.IDLE:			return stateIdle
		State.WALK:			return stateWalk
		State.SIT:			return stateSit
		State.ATTACK:		return stateAttack
		State.DEATH:		return stateDeath
		State.TO_TRIGGER:	return stateToTrigger
		State.TRIGGER:		return stateTrigger
		State.FROM_TRIGGER:	return stateFromTrigger
		_:					return stateIdle

static func IsAlive(agent : Actor) -> bool:
	return agent and agent.state != State.DEATH

static func IsAttacking(agent : Actor) -> bool:
	return agent and agent.state == State.ATTACK

static func IsSitting(agent : Actor) -> bool:
	return agent and agent.state == State.SIT

static func IsTriggering(agent : Actor) -> bool:
	return agent and agent.state == State.TRIGGER

#
const slotBody : String						= "Body"
const slotHair : String						= "Hair"
const slotChest : String					= "Chest"
const slotLegs : String						= "Legs"
const slotFeet : String						= "Feet"
const slotHands : String					= "Hands"
const slotHead : String						= "Head"
const slotFace : String						= "Face"
const slotWeapon : String					= "Weapon"
const slotShield : String					= "Shield"

static func GetSlotName(slot : Slot) -> String:
	match slot:
		Slot.BODY:				return slotBody
		Slot.HAIR:				return slotHair
		Slot.CHEST:				return slotChest
		Slot.LEGS:				return slotLegs
		Slot.FEET:				return slotFeet
		Slot.HANDS:				return slotHands
		Slot.HEAD:				return slotHead
		Slot.FACE:				return slotFace
		Slot.WEAPON:			return slotWeapon
		Slot.SHIELD:			return slotShield
		_:						return slotBody

static func GetSlotID(slot : String) -> Slot:
	match slot:
		slotBody:					return Slot.BODY
		slotHair:					return Slot.HAIR
		slotChest:					return Slot.CHEST
		slotLegs:					return Slot.LEGS
		slotFeet:					return Slot.FEET
		slotHands:					return Slot.HANDS
		slotHead:					return Slot.HEAD
		slotFace:					return Slot.FACE
		slotWeapon:					return Slot.WEAPON
		slotShield:					return Slot.SHIELD
		_:							return Slot.BODY

# Visual
const AllyTarget : Resource 				= preload("res://presets/entities/components/targets/Ally.tres")
const EnemyTarget : Resource				= preload("res://presets/entities/components/targets/Enemy.tres")
const AlterationLabel : PackedScene			= preload("res://presets/gui/AlterationLabel.tscn")
const SpeechLabel : PackedScene				= preload("res://presets/gui/chat/SpeechBubble.tscn")
const MorphFx : PackedScene					= preload("res://presets/effects/particles/Morph.tscn")
const LevelUpFx : PackedScene				= preload("res://presets/effects/particles/LevelUp.tscn")
const GenderMaleTexture						= preload("res://data/graphics/gui/stat/gender-male.png")
const GenderFemaleTexture					= preload("res://data/graphics/gui/stat/gender-female.png")
const GenderNonBinaryTexture				= preload("res://data/graphics/gui/stat/gender-nonbinary.png")

# Skill
enum Alteration
{
	HIT = 0,
	CRIT,
	MISS,
	DODGE,
	HEAL,
	PROJECTILE,
}

# Colors
const DodgeAttackColor : float				= 0.15
const HealColor : float						= 0.42
const LocalAttackColor : float				= 0.35
const MissAttackColor : float				= 0.2
const MonsterAttackColor : float			= 0.0
const PlayerAttackColor : float				= 0.6
const LevelDifferenceColor : float			= 5.0

# Interactive
const interactionDisplayOffset : int		= 32
const emoteDelay : float					= 4.0
const morphDelay : float					= 1.2
const speechDelay : float					= 6.0
const speechDecreaseDelay : float			= 1.5
const speechIncreaseThreshold : int			= 15
const speechMaxWidth : int					= 256
const speechExtraWidth : int				= 20
const TargetMaxSquaredDistance : float		= 512 * 512 # ~15 Tile squared length

# Lifetime
const AttackTimestampLimit : int			= 1000 * 60 * 5 # 5 minutes
const RegenDelay : float					= 3.0
const DeathDelay : float					= 10.0
const DisplayHPDelay : float				= 7.0
const MapProcessingToggleDelay : float		= 10.0
const MapProcessingToggleExtraDelay : float	= 60.0

# Drop
const DropDelay : float						= 60.0
const PickupSquaredDistance : float			= 48 * 48 # 1.5 Tile squared length

# Stats
const MaxPointPerAttributes : int			= 20
const InventorySize : int					= 100

# Explore
static var SailingDestination : Destination	= Destination.new("Ocean", Vector2(71 * 32, 55 * 32))

# Navigation
const DisplacementVector : Vector2			= Vector2(32, 32)
const MaxDisplacementSquareLength : float	= 64 * 64
const InputApproximationUnit : int			= 12
const MaxEntityRadiusSize : int				= 256

# New player
const DefaultAttributes : Dictionary = {
	"strength": 10,
	"vitality": 3
}
static var DefaultInventory : Dictionary = {
	"Apple".hash(): 5
}
