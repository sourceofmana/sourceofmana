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

enum PersonalStat
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

# Lifetime
const AttackTimestampLimit : int			= 1000 * 60 * 5 # 5 minutes
const RegenDelay : float					= 1.0
const DeathDelay : float					= 10.0
const DisplayHPDelay : float				= 7.0

# Stats
const MaxPointPerPersonalStat : int			= 20
