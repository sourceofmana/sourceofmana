extends Object
class_name ProgressCommons

const UnknownProgress : int						= 0
const CompletedProgress : int					= 255

const QuestNames : PackedStringArray			= [ \
	"Splatyna's Offering" # QUEST_SPLATYNA_OFFERING
]

const QUEST_SPLATYNA_OFFERING : int				= 0
enum STATE_SPLATYNA
{
	INACTIVE = ProgressCommons.UnknownProgress,
	STARTED,
	REWARDS_WITHDREW = ProgressCommons.CompletedProgress,
}
