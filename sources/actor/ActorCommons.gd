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

const genderMale : String				= "Male"
const genderFemale : String				= "Female"
const genderNonBinary : String			= "Non Binary"

static func GetGenderName(gender : Gender) -> String:
	match gender:
		Gender.MALE:			return genderMale
		Gender.FEMALE:			return genderFemale
		Gender.NONBINARY:		return genderNonBinary
		_:						return genderNonBinary

static func GetGenderID(gender : String) -> Gender:
	match gender:
		genderMale:					return Gender.MALE
		genderFemale:				return Gender.FEMALE
		genderNonBinary:			return Gender.NONBINARY
		_:							return Gender.MALE

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
	NONE = -1,
	CHEST = 0,
	LEGS,
	FEET,
	HANDS,
	HEAD,
	NECK,
	WEAPON,
	SHIELD,
	BODY,
	FACE,
	HAIR,
	QUEST,
	COUNT,
	FIRST_EQUIPMENT = CHEST,
	LAST_EQUIPMENT = SHIELD + 1,
	FIRST_MODIFIER = BODY,
	LAST_MODIFIER = HAIR + 1,
}

enum Attribute
{
	STRENGTH = 0,
	VITALITY,
	AGILITY,
	ENDURANCE,
	CONCENTRATION,
}

static func CheckTraits(traits : Dictionary) -> bool:
	if "hairstyle" not in traits or not DB.GetHairstyle(traits["hairstyle"]):
		return false
	if "haircolor" not in traits or not DB.GetPalette(DB.Palette.HAIR, traits["haircolor"]):
		return false
	if "race" not in traits:
		return false
	var race : RaceData = DB.GetRace(traits["race"])
	if not race or "skintone" not in traits or traits["skintone"] not in race._skins:
		return false
	if "gender" not in traits:
		return false
	return true

static func CheckAttributes(attributes : Dictionary) -> bool:
	return (attributes.get("strength", 0) + attributes.get("vitality", 0) + attributes.get("agility", 0) + attributes.get("endurance") + attributes.get("concentration")) <= Formula.GetMaxAttributePoints(1)

enum Target
{
	NONE = 0,
	ALLY,
	ENEMY
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
const slotChest : String					= "Chest"
const slotLegs : String						= "Legs"
const slotFeet : String						= "Feet"
const slotHands : String					= "Hands"
const slotHead : String						= "Head"
const slotNeck : String						= "Neck"
const slotWeapon : String					= "Weapon"
const slotShield : String					= "Shield"
const slotBody : String						= "Body"
const slotFace : String						= "Face"
const slotHair : String						= "Hair"
const slotQuest : String					= "Quest"

static func GetSlotName(slot : Slot) -> String:
	match slot:
		Slot.CHEST:				return slotChest
		Slot.LEGS:				return slotLegs
		Slot.FEET:				return slotFeet
		Slot.HANDS:				return slotHands
		Slot.HEAD:				return slotHead
		Slot.NECK:				return slotNeck
		Slot.WEAPON:			return slotWeapon
		Slot.SHIELD:			return slotShield
		Slot.BODY:				return slotBody
		Slot.FACE:				return slotFace
		Slot.HAIR:				return slotHair
		Slot.QUEST:				return slotQuest
		_:						return slotBody

const SlotEquipmentCount : int				= ActorCommons.Slot.LAST_EQUIPMENT - ActorCommons.Slot.FIRST_EQUIPMENT
const SlotModifierCount : int				= ActorCommons.Slot.LAST_MODIFIER - ActorCommons.Slot.FIRST_MODIFIER

static func GetSlotID(slot : String) -> Slot:
	match slot:
		slotChest:					return Slot.CHEST
		slotLegs:					return Slot.LEGS
		slotFeet:					return Slot.FEET
		slotHands:					return Slot.HANDS
		slotHead:					return Slot.HEAD
		slotNeck:					return Slot.NECK
		slotWeapon:					return Slot.WEAPON
		slotShield:					return Slot.SHIELD
		slotBody:					return Slot.BODY
		slotFace:					return Slot.FACE
		slotHair:					return Slot.HAIR
		slotQuest:					return Slot.QUEST
		_:							return Slot.BODY

# Visual
const AllyTarget : Resource 				= preload("res://presets/entities/components/targets/Ally.tres")
const EnemyTarget : Resource				= preload("res://presets/entities/components/targets/Enemy.tres")
const AlterationLabel : PackedScene			= preload("res://presets/gui/AlterationLabel.tscn")
const SpeechLabel : PackedScene				= preload("res://presets/gui/chat/SpeechBubble.tscn")
const MorphFx : PackedScene					= preload("res://presets/effects/particles/Morph.tscn")
const LevelUpFx : PackedScene				= preload("res://presets/effects/particles/LevelUp.tscn")
const SelectionFx : PackedScene				= preload("res://presets/effects/particles/Selection.tscn")

const GenderMaleTexture : Texture2D			= preload("res://data/graphics/gui/stat/gender-male.png")
const GenderFemaleTexture : Texture2D		= preload("res://data/graphics/gui/stat/gender-female.png")
const GenderNonBinaryTexture : Texture2D	= preload("res://data/graphics/gui/stat/gender-nonbinary.png")

const LastMeanValueMax : int				= 5

# Skill
enum Alteration
{
	HIT = 0,
	CRIT,
	MISS,
	DODGE,
	HEAL,
	EXP,
	GP,
}

# Colors
const DodgeAttackColor : float				= 0.15
const HealColor : float						= 0.42
const LocalAttackColor : float				= 0.35
const MissAttackColor : float				= 0.2
const ExpColor : float						= 0.44
const GPColor : float						= 0.16
const MonsterAttackColor : float			= 0.0
const PlayerAttackColor : float				= 0.51
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
const TargetMaxDistance : int				= 256 # ~8 Tile squared length
static var TargetMaxSquaredDistance : float	= TargetMaxDistance * TargetMaxDistance

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
const MaxStatValue : int					= 1 << 32
const MaxPointPerAttributes : int			= 20
const InventorySize : int					= 100

static func IsEquipped(cell : BaseCell) -> bool:
	return cell and cell is ItemCell and \
	cell.slot >= ActorCommons.Slot.FIRST_EQUIPMENT and cell.slot < ActorCommons.Slot.LAST_EQUIPMENT and \
	CellCommons.IsSameCell(cell, Launcher.Player.inventory.equipments[cell.slot])

# Explore
static var SailingDestination : Destination	= Destination.new(DB.OceanHash, Vector2(71 * 32, 55 * 32))

# Navigation
const MaxEntityRadiusSize : int				= 256
const DisplacementVector : Vector2			= Vector2(32, 32)
const MismatchPathSquaredThreshold : float	= 32 * 32
const MaxDisplacementSquareLength : float	= 64 * 64
const InputApproximationUnit : int			= 16
static var InputApproximationDelta : float	= 360.0 / InputApproximationUnit

# Camera
const CameraZoomLevels : PackedVector2Array	= [
	Vector2(0.6, 0.6),
	Vector2(0.7, 0.7),
	Vector2(0.85, 0.85),
	Vector2(1.0, 1.0),
	Vector2(1.2, 1.2),
	Vector2(1.5, 1.5),
	Vector2(2.0, 2.0),
	Vector2(3.0, 3.0),
]
const CameraZoomDefault : int				= 3
const CameraZoomDouble : int				= 6
const CameraZoomTriple : int				= 7
const CameraZoomDelay : float				= 0.4

# Character
const InvalidCharacterSlot : int			= -1
const MaxCharacterCount : int				= 10
static var CharacterScreenMapID : int		= "Drazil".hash()
const CharacterScreenLocations : PackedVector2Array = [
	Vector2(1984, 992),
	Vector2(2144, 960),
	Vector2(2240, 896),
	Vector2(2240, 768),
	Vector2(2144, 704),
	Vector2(2048, 736),
	Vector2(1856, 672),
	Vector2(1728, 768),
	Vector2(1760, 896),
	Vector2(1856, 960),
	Vector2(2048, 928)
]

# New player
static var DefaultTraits : Dictionary = {
	"shape": DB.PlayerHash,
	"spirit": "Piou".hash()
}
static var DefaultAttributes : Dictionary = {
	"strength": 10,
	"vitality": 3,
	"agility": 0,
	"endurance": 0,
	"concentration": 0,
}
static var DefaultStats : Dictionary = {
	"level": 1,
}
static var DefaultInventory : Array[Dictionary] = [
	{ "item_id": "Apple".hash(), "count": 5, "customfield": "" },
	{ "item_id": "Trousers".hash(), "count": 1, "customfield": "" },
	{ "item_id": "V-Neck Tee".hash(), "count": 1, "customfield": "" },
	{ "item_id": "Scimitar".hash(), "count": 1, "customfield": "" },
	{ "item_id": "Bone Knife".hash(), "count": 1, "customfield": "" },
	{ "item_id": "Cleaver".hash(), "count": 1, "customfield": "" },
	{ "item_id": "Gladius".hash(), "count": 1, "customfield": "" },
	{ "item_id": "Piou Slayer".hash(), "count": 1, "customfield": "" },
	{ "item_id": "Rock Knife".hash(), "count": 1, "customfield": "" },
	{ "item_id": "Short Sword".hash(), "count": 1, "customfield": "" },
	{ "item_id": "Raw Wood Shield".hash(), "count": 1, "customfield": "" },
	{ "item_id": "Leather Shield".hash(), "count": 1, "customfield": "" },
	{ "item_id": "Bandana Scarf".hash(), "count": 1, "customfield": "" },
	{ "item_id": "Leather Pants".hash(), "count": 1, "customfield": "" },
	{ "item_id": "Cloud Pants".hash(), "count": 1, "customfield": "" },
	{ "item_id": "Funky Hat".hash(), "count": 1, "customfield": "" },
	{ "item_id": "Desert Hood".hash(), "count": 1, "customfield": "" },
	{ "item_id": "Leather Gloves".hash(), "count": 1, "customfield": "" },
	{ "item_id": "Leather Armbands".hash(), "count": 1, "customfield": "" },
	{ "item_id": "Leather Boots".hash(), "count": 1, "customfield": "" },
	{ "item_id": "Desert Boots".hash(), "count": 1, "customfield": "" },
	{ "item_id": "Tank Top".hash(), "count": 1, "customfield": "" },
	{ "item_id": "Crop Top".hash(), "count": 1, "customfield": "" },
	{ "item_id": "Leather Shirt".hash(), "count": 1, "customfield": "" },
	{ "item_id": "Cotton Shirt".hash(), "count": 1, "customfield": "" },
	{ "item_id": "Letter".hash(), "count": 1, "customfield": "" },
	{ "item_id": "Jean Chaps".hash(), "count": 1, "customfield": "" },
	{ "item_id": "Shorts".hash(), "count": 1, "customfield": "Cerulean" },
]
static var DefaultSkills : Array[Dictionary] = [
	{ "skill_id": "Melee".hash(), "level": 1 },
	{ "skill_id": "Flar".hash(), "level": 1 },
	{ "skill_id": "Lum".hash(), "level": 1 },
	{ "skill_id": "Inma".hash(), "level": 1 },
	{ "skill_id": "Mana Burst".hash(), "level": 1 },
]
