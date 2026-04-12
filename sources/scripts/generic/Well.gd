extends NpcScript

#
const FILL_TIME : float									= 10.0
const FILL_TICKS : int									= 20
const FILL_TICK_TIME : float							= FILL_TIME / FILL_TICKS
const MOVE_TOLERANCE_SQUARED : float					= 8.0 * 8.0

var BOTTLE_ID : int										= "Bottle".hash()
var WATER_BOTTLE_ID : int								= "Water Bottle".hash()

#
func OnStart():
	if HasItem(BOTTLE_ID):
		Mes("Hold still while your bottle is filling...")
		Action(StartFill)
	else:
		Mes("You would need a bottle to draw water from this well.")

func StartFill():
	OnFillTick(own.position, 0)

func OnFillTick(startPos : Vector2, tick : int):
	if own.position.distance_squared_to(startPos) > MOVE_TOLERANCE_SQUARED:
		ClearTracker()
		Notification("You moved too far from the well!")
	elif not HasItem(BOTTLE_ID):
		ClearTracker()
	elif tick >= FILL_TICKS:
		CompleteFill()
	else:
		DisplayTracker("Filling...", tick, FILL_TICKS, "%")
		AddTimer(own, FILL_TICK_TIME, OnFillTick.bind(startPos, tick + 1), own.nick)

func CompleteFill():
	NpcCommons.ClearTracker(own)
	if NpcCommons.RemoveItem(own, BOTTLE_ID):
		NpcCommons.AddItem(own, WATER_BOTTLE_ID)
		PromptNext()

func PromptNext():
	if HasItem(BOTTLE_ID):
		Mes("Your bottle is now filled with fresh water. You have another empty bottle.")
		Choice("Fill another bottle", StartFill)
		Choice("Leave")
	else:
		Mes("Your bottle is now filled with fresh water.")
