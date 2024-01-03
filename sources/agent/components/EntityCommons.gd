extends Object
class_name EntityCommons

#
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

static var playbackParameter : String = "parameters/playback"

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


#
static func GetNextTransition(currentState : State, newState : State) -> State:
	return stateTransitions[currentState][newState]

static func GetStateName(state : State):
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

# Guardband static vars
static var StartGuardbandDist : int				= 0
static var PatchGuardband : int					= 0
static var MaxGuardbandDist : int				= 0
static var MaxGuardbandDistVec : Vector2		= Vector2.ZERO

# Visual
static var AllyTarget : Resource 				= preload("res://presets/entities/components/targets/Ally.tres")
static var EnemyTarget : Resource				= preload("res://presets/entities/components/targets/Enemy.tres")
static var DamageLabel : PackedScene			= preload("res://presets/gui/DamageLabel.tscn")
static var SpeechLabel : PackedScene			= preload("res://presets/gui/chat/SpeechBubble.tscn")

# Damage
enum DamageType
{
	HIT = 0,
	CRIT,
	MISS,
	DODGE
}

static var DodgeAttackColor : float				= 0.15
static var LocalAttackColor : float				= 0.35
static var MissAttackColor : float				= 0.2
static var MonsterAttackColor : float			= 0.0
static var PlayerAttackColor : float			= 0.65

# Interactive
static var interactionDisplayOffset : int		= 0
static var emoteDelay : float					= 0
static var morphDelay : float					= 0
static var speechDelay : float					= 0
static var speechDecreaseDelay : float			= 0
static var speechIncreaseThreshold : int		= 0
static var speechMaxWidth : int					= 0
static var speechExtraWidth : int				= 0

static func InitVars():
	# Guardband
	EntityCommons.StartGuardbandDist = Launcher.Conf.GetInt("Guardband", "startGuardbandDist", Launcher.Conf.Type.NETWORK)
	EntityCommons.PatchGuardband = Launcher.Conf.GetInt("Guardband", "patchGuardband", Launcher.Conf.Type.NETWORK)
	EntityCommons.MaxGuardbandDist = Launcher.Conf.GetInt("Guardband", "maxGuardbandDist", Launcher.Conf.Type.NETWORK)
	EntityCommons.MaxGuardbandDistVec = Vector2(EntityCommons.MaxGuardbandDist, EntityCommons.MaxGuardbandDist)

	# Visual
	EntityCommons.DodgeAttackColor = Launcher.Conf.GetFloat("Visual", "dodgeAttackColor", Launcher.Conf.Type.GAMEPLAY)
	EntityCommons.LocalAttackColor = Launcher.Conf.GetFloat("Visual", "localAttackColor", Launcher.Conf.Type.GAMEPLAY)
	EntityCommons.MissAttackColor = Launcher.Conf.GetFloat("Visual", "missAttackColor", Launcher.Conf.Type.GAMEPLAY)
	EntityCommons.MonsterAttackColor = Launcher.Conf.GetFloat("Visual", "monsterAttackColor", Launcher.Conf.Type.GAMEPLAY)
	EntityCommons.PlayerAttackColor = Launcher.Conf.GetFloat("Visual", "playerAttackColor", Launcher.Conf.Type.GAMEPLAY)

	# Interactive
	EntityCommons.interactionDisplayOffset = Launcher.Conf.GetInt("Interactive", "interactionDisplayOffset", Launcher.Conf.Type.GAMEPLAY)
	EntityCommons.emoteDelay = Launcher.Conf.GetFloat("Interactive", "emoteDelay", Launcher.Conf.Type.GAMEPLAY)
	EntityCommons.morphDelay = Launcher.Conf.GetFloat("Interactive", "morphDelay", Launcher.Conf.Type.GAMEPLAY)
	EntityCommons.speechDelay = Launcher.Conf.GetFloat("Interactive", "speechDelay", Launcher.Conf.Type.GAMEPLAY)
	EntityCommons.speechDecreaseDelay = Launcher.Conf.GetFloat("Interactive", "speechDecreaseDelay", Launcher.Conf.Type.GAMEPLAY)
	EntityCommons.speechIncreaseThreshold = Launcher.Conf.GetInt("Interactive", "speechIncreaseThreshold", Launcher.Conf.Type.GAMEPLAY)
	EntityCommons.speechMaxWidth = Launcher.Conf.GetInt("Interactive", "speechMaxWidth", Launcher.Conf.Type.GAMEPLAY)
	EntityCommons.speechExtraWidth = Launcher.Conf.GetInt("Interactive", "speechExtraWidth", Launcher.Conf.Type.GAMEPLAY)
