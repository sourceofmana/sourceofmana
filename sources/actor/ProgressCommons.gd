extends RefCounted
class_name ProgressCommons

const UnknownProgress : int						= 0
const CompletedProgress : int					= 255

# Quest ID list
class Quest:
	static var SPLATYNA_OFFERING : int = "Splatyna's Offering".hash()
	static var GRAIN_IN_THE_SAND : int = "Grain in the desert".hash()
	static var SNAKE_PIT_THIEF : int = "Snake Pit Thief".hash()
	static var SNAKE_PIT_BITING_THIRST : int = "A Biting Thirst".hash()
	static var SANDSTORM_MINE_ABANDONED_TREASURE : int = "Sandstorm Mine Abandoned Treasure".hash()
	static var TULIMSHAR_OLD_FRIENDSHIP : int = "An Old Friendship".hash()
	static var TUTORIAL : int = "Tutorial".hash()
	static var ELANORE_POTION : int = "Elanore's Potions".hash()
	static var NINA_HUNGRY : int = "Nina's Snack".hash()
	static var MINE_EXPLORATION : int = "Mine Exploration".hash()
	static var SANDSTORM_NATHAN_WATER : int = "A Drop of Relief".hash()
	static var SANDSTORM_NAEM_HELMET : int = "A Miner's Helping Hand".hash()
	static var DESERT_SEED : int = "Desert Seed".hash()
	static var TULIMSHAR_EASTERN_HILLS_CHEST : int = "Found a Chest in the Outskirts".hash()
	static var TULIMSHAR_GLASSMAKING : int = "When the desert gives you sand...".hash()
	static var SHIP_PETER_BOUNTY : int = "Peter's Bounty".hash()
	static var VETERAN_CAVE_EXPLORER : int = "Veteran Cave Explorer".hash()
	static var VINCENT_BUGLEG : int = "Vincent's Bug Legs".hash()

# Quest enums
enum SPLATYNA_OFFERING
{
	INACTIVE = ProgressCommons.UnknownProgress,
	STARTED,
	REWARDS_WITHDREW = ProgressCommons.CompletedProgress,
}
enum GRAIN_IN_THE_SAND
{
	INACTIVE = ProgressCommons.UnknownProgress,
	STARTED,
	SEARCHED_CRATES,
	REWARDS_WITHDREW = ProgressCommons.CompletedProgress,
}
enum SNAKE_PIT_THIEF
{
	INACTIVE = ProgressCommons.UnknownProgress,
	# Bits 0 to 4 [1; 31] are reserved to finding clues
	ALL_CLUES_FOUND = 31,
	RIDDLE_SOLVED = 32,
	REWARDS_WITHDREW = ProgressCommons.CompletedProgress,
}
enum SNAKE_PIT_BITING_THIRST
{
	INACTIVE = ProgressCommons.UnknownProgress,
	STARTED,
	REWARDS_WITHDREW = ProgressCommons.CompletedProgress,
}
enum SANDSTORM_MINE_ABANDONED_TREASURE
{
	INACTIVE = ProgressCommons.UnknownProgress,
	KEY_FOUND,
	REWARDS_WITHDREW = ProgressCommons.CompletedProgress,
}
enum TULIMSHAR_OLD_FRIENDSHIP
{
	INACTIVE = ProgressCommons.UnknownProgress,
	STARTED,
	ENVELOPES_FOUND,
	LETTERS_DELIVERED,
	REWARDS_WITHDREW = ProgressCommons.CompletedProgress,
}
enum TUTORIAL
{
	INACTIVE = ProgressCommons.UnknownProgress,
	INTRO_ITEMS_GIVEN,
	POTION_GIVEN,
	CLOTHES_GIVEN,
	UI_EXPLAINED,
	ELANORE_DONE,
	KAEL_MET,
	KAEL_DONE,
	EKINU_DONE = ProgressCommons.CompletedProgress,
}
enum ELANORE_POTION
{
	INACTIVE = ProgressCommons.UnknownProgress,
	STARTED,
}
enum NINA_HUNGRY
{
	INACTIVE = ProgressCommons.UnknownProgress,
	STARTED,
	REWARDS_WITHDREW = ProgressCommons.CompletedProgress,
}
enum MINE_EXPLORATION
{
	INACTIVE = ProgressCommons.UnknownProgress,
	STARTED,
	FIND_NICKOS,
	STRANGER_SPOTTED,
	FIGHTING,
	DEFEATED,
	MANA_TREE_MET,
	REWARDS_WITHDREW = ProgressCommons.CompletedProgress,
}
enum SANDSTORM_NATHAN_WATER
{
	INACTIVE = ProgressCommons.UnknownProgress,
	STARTED,
	REWARDS_WITHDREW = ProgressCommons.CompletedProgress,
}
enum SANDSTORM_NAEM_HELMET
{
	INACTIVE = ProgressCommons.UnknownProgress,
	GIVEN = ProgressCommons.CompletedProgress,
}
enum DESERT_SEED
{
	INACTIVE = ProgressCommons.UnknownProgress,
	SEEK_NINA,
	SEEK_MANAYIR,
}
enum TULIMSHAR_EASTERN_HILLS_CHEST
{
	INACTIVE = ProgressCommons.UnknownProgress,
	REWARDS_WITHDREW = ProgressCommons.CompletedProgress,
}
enum TULIMSHAR_GLASSMAKING
{
	INACTIVE = ProgressCommons.UnknownProgress,
	STARTED,
	REWARDS_WITHDREW = ProgressCommons.CompletedProgress,
}
enum SHIP_PETER_BOUNTY
{
	INACTIVE = ProgressCommons.UnknownProgress,
	WAVE_ONE_DONE = 1,
	WAVE_TWO_DONE = 2,
	ALL_DONE = ProgressCommons.CompletedProgress,
}
enum VETERAN_CAVE_EXPLORER
{
	INACTIVE = ProgressCommons.UnknownProgress,
	UNCLAIMED,
	REWARDS_WITHDREW = ProgressCommons.CompletedProgress,
}
enum VINCENT_BUGLEG
{
	INACTIVE = ProgressCommons.UnknownProgress,
	STARTED,
	REWARDS_WITHDREW = ProgressCommons.CompletedProgress,
}

# Quest state lookup
static var QuestStates : Dictionary[int, Variant] = {
	Quest.SPLATYNA_OFFERING: SPLATYNA_OFFERING,
	Quest.GRAIN_IN_THE_SAND: GRAIN_IN_THE_SAND,
	Quest.SNAKE_PIT_THIEF: SNAKE_PIT_THIEF,
	Quest.SNAKE_PIT_BITING_THIRST: SNAKE_PIT_BITING_THIRST,
	Quest.SANDSTORM_MINE_ABANDONED_TREASURE: SANDSTORM_MINE_ABANDONED_TREASURE,
	Quest.TULIMSHAR_OLD_FRIENDSHIP: TULIMSHAR_OLD_FRIENDSHIP,
	Quest.TUTORIAL: TUTORIAL,
	Quest.ELANORE_POTION: ELANORE_POTION,
	Quest.NINA_HUNGRY: NINA_HUNGRY,
	Quest.MINE_EXPLORATION: MINE_EXPLORATION,
	Quest.SANDSTORM_NATHAN_WATER: SANDSTORM_NATHAN_WATER,
	Quest.SANDSTORM_NAEM_HELMET: SANDSTORM_NAEM_HELMET,
	Quest.DESERT_SEED: DESERT_SEED,
	Quest.TULIMSHAR_EASTERN_HILLS_CHEST: TULIMSHAR_EASTERN_HILLS_CHEST,
	Quest.TULIMSHAR_GLASSMAKING: TULIMSHAR_GLASSMAKING,
	Quest.SHIP_PETER_BOUNTY: SHIP_PETER_BOUNTY,
	Quest.VETERAN_CAVE_EXPLORER: VETERAN_CAVE_EXPLORER,
	Quest.VINCENT_BUGLEG: VINCENT_BUGLEG,
}

static func GetQuestStateID(questID : int, stateName : String) -> int:
	var questState : Variant = QuestStates.get(questID)
	return questState.get(stateName, UnknownProgress) if questState else UnknownProgress
