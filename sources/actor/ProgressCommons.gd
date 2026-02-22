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

# Quest state lookup
static var QuestStates : Dictionary[Quest, Variant] = {
	Quest.SPLATYNA_OFFERING: SPLATYNA_OFFERING,
	Quest.GRAIN_IN_THE_SAND: GRAIN_IN_THE_SAND,
}

static func GetQuestStateID(questID : int, stateName : String) -> int:
	var questState : Variant = QuestStates.get(questID)
	return questState.get(stateName, UnknownProgress) if questState else UnknownProgress
