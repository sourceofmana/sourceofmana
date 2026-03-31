extends RefCounted
class_name ProgressCommons

const UnknownProgress : int						= 0
const CompletedProgress : int					= 255

# Quest ID list
enum Quest
{
	UNKNOWN = -1,
	SPLATYNA_OFFERING,
	GRAIN_IN_THE_SAND,
	SNAKE_PIT_THIEF,
	SNAKE_PIT_BITING_THIRST,
	SANDSTORM_MINE_ABANDONED_TREASURE,
}

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

# Quest state lookup
static var QuestStates : Dictionary[Quest, Variant] = {
	Quest.SPLATYNA_OFFERING: SPLATYNA_OFFERING,
	Quest.GRAIN_IN_THE_SAND: GRAIN_IN_THE_SAND,
	Quest.SNAKE_PIT_THIEF: SNAKE_PIT_THIEF,
	Quest.SNAKE_PIT_BITING_THIRST: SNAKE_PIT_BITING_THIRST,
	Quest.SANDSTORM_MINE_ABANDONED_TREASURE: SANDSTORM_MINE_ABANDONED_TREASURE,
}

static func GetQuestStateID(questID : int, stateName : String) -> int:
	var questState : Variant = QuestStates.get(questID)
	return questState.get(stateName, UnknownProgress) if questState else UnknownProgress
