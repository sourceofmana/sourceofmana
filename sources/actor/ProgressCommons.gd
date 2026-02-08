extends RefCounted
class_name ProgressCommons

const UnknownProgress : int						= 0
const CompletedProgress : int					= 255

# Quest ID list
const QUEST_SPLATYNA_OFFERING : int				= 0

# Quest enums
enum STATE_SPLATYNA
{
	INACTIVE = ProgressCommons.UnknownProgress,
	STARTED,
	REWARDS_WITHDREW = ProgressCommons.CompletedProgress,
}
