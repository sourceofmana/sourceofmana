extends RefCounted
class_name BuffModifier

#
const TimerPrefix : String									= "Buff_"
const InfiniteTime : float									= -1.0

# Buffs of disconnected players
static var storedBuffs : Dictionary[int, Array]				= {}

var buffs : Dictionary[CellCommons.Modifier, StatModifier]	= {}
var skills : Dictionary[CellCommons.Modifier, int]			= {}
var actor : Actor											= null

# Getter
func Get(effect : CellCommons.Modifier) -> StatModifier:
	return buffs.get(effect)

func GetSkillID(effect : CellCommons.Modifier) -> int:
	return skills.get(effect, DB.UnknownHash)

func GetValue(effect : CellCommons.Modifier) -> Variant:
	var modifier : StatModifier = Get(effect)
	return modifier._value if modifier else 0

func GetRemaining(effect : CellCommons.Modifier) -> float:
	if not actor or not buffs.has(effect):
		return 0.0
	var timer : Timer = actor.get_node_or_null(GetTimerName(effect))
	return timer.time_left if timer else InfiniteTime

# Application
func ApplyCell(skill : SkillCell, duration : float):
	if not skill or not skill.modifiers:
		return

	for modifier in skill.modifiers._modifiers:
		if modifier and modifier._persistent:
			Apply(modifier._effect, modifier._value, duration, skill.id)

func Apply(effect : CellCommons.Modifier, value : Variant, duration : float, skillID : int = DB.UnknownHash, merge : bool = true):
	if not actor or effect == CellCommons.Modifier.None or duration == 0.0:
		return

	var modifier : StatModifier = buffs.get(effect, null)
	if modifier:
		if merge:
			var merged : Variant = MergeValue(effect, modifier._value, value)
			if merged != value:
				skillID = GetSkillID(effect)
			value = merged
			duration = MergeDuration(GetRemaining(effect), duration, effect, value)
		modifier._value = value
	else:
		modifier = StatModifier.new()
		modifier._effect = effect
		modifier._value = value
		modifier._persistent = true
		buffs[effect] = modifier
		actor.stat.modifiers.Add(modifier)
	skills[effect] = skillID

	if IsInfinite(duration):
		Util.RemoveNode(actor.get_node_or_null(GetTimerName(effect)), actor)
	else:
		Callback.SelfDestructTimer(actor, duration, Expire, [effect], GetTimerName(effect))
	actor.stat.RefreshEntityStats()
	Notify(effect, value, duration)
	Display(effect)

# Removal
func Expire(effect : CellCommons.Modifier):
	if not actor or not buffs.has(effect):
		return

	actor.stat.modifiers.Remove(buffs[effect])
	buffs.erase(effect)
	skills.erase(effect)
	actor.stat.RefreshEntityStats()
	Notify(effect, 0, 0.0)
	Display(effect)

func Clear(effect : CellCommons.Modifier):
	if actor:
		Util.RemoveNode(actor.get_node_or_null(GetTimerName(effect)), actor)
	Expire(effect)

func ClearSkill(skillID : int):
	for effect in skills.keys():
		if skills[effect] == skillID:
			Clear(effect)

func ClearAll():
	for effect in buffs.keys():
		Clear(effect)

# Offline storage
func Store(charID : int):
	if charID == NetworkCommons.PeerUnknownID:
		return

	var entries : Array = []
	for effect in buffs:
		var remaining : float = GetRemaining(effect)
		if remaining != 0.0:
			entries.append([effect, buffs[effect]._value, remaining, GetSkillID(effect)])

	if entries.is_empty():
		storedBuffs.erase(charID)
	else:
		storedBuffs[charID] = entries

func Restore(charID : int):
	for entry in storedBuffs.get(charID, []):
		Apply(entry[0], entry[1], entry[2], entry[3])
	storedBuffs.erase(charID)

# Notify client(s)
func Notify(effect : CellCommons.Modifier, value : Variant, duration : float):
	if actor is PlayerAgent:
		Network.UpdateBuff(effect, value, duration, GetSkillID(effect), actor.peerID)

func NotifyAll():
	for effect in buffs:
		Notify(effect, buffs[effect]._value, GetRemaining(effect))

func NotifyAgent(peerID : int):
	var actorRID : int = actor.get_rid().get_id()
	for effect in buffs:
		Network.Bulk("EntityBuff", [actorRID, effect, GetSkillID(effect), true], peerID)

func Display(effect : CellCommons.Modifier):
	var enabled : bool = buffs.has(effect)
	if actor is Entity:
		if actor.interactive:
			actor.interactive.DisplayBuff(effect, GetSkillID(effect), enabled)
	elif actor is BaseAgent:
		Network.NotifyNeighbours(actor, "EntityBuff", [actor.get_rid().get_id(), effect, GetSkillID(effect), enabled], false)

# A malus always beats a bonus and is never softened, two same sided buffs keep the strongest
static func MergeValue(effect : CellCommons.Modifier, current : Variant, value : Variant) -> Variant:
	var currentBenefit : float = GetBenefit(effect, current)
	var benefit : float = GetBenefit(effect, value)
	if currentBenefit < 0.0 or benefit < 0.0:
		return current if currentBenefit < benefit else value
	return current if currentBenefit > benefit else value

# The merged value drives the duration, a malus can only be extended and a bonus only shortened
static func MergeDuration(remaining : float, duration : float, effect : CellCommons.Modifier, value : Variant) -> float:
	if remaining == 0.0:
		return duration
	if IsInfinite(remaining) or IsInfinite(duration):
		if IsMalus(effect, value):
			return InfiniteTime
		return duration if IsInfinite(remaining) else remaining
	return maxf(remaining, duration) if IsMalus(effect, value) else minf(remaining, duration)

static func GetBenefit(effect : CellCommons.Modifier, value : Variant) -> float:
	return -float(value) if CellCommons.IsInverseModifier(effect) else float(value)

static func IsMalus(effect : CellCommons.Modifier, value : Variant) -> bool:
	return GetBenefit(effect, value) < 0.0

static func IsInfinite(duration : float) -> bool:
	return duration < 0.0

static func GetTimerName(effect : CellCommons.Modifier) -> String:
	return TimerPrefix + str(effect)
