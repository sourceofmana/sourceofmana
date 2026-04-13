extends NpcScript

#
const ENTRANCE_POS : Vector2 = Vector2(1536, 1600) # tile (48, 50)

#
func OnStart():
	Mes("Hold it right there.")
	Mes("Ben's orders. Nobody walks these corridors without clearance.")
	Mes("I don't care why you're here. Turn around.")
	Action(Escort)

func Escort():
	if own.state == ActorCommons.State.TRIGGER:
		own.SetState(ActorCommons.State.TRIGGER)

	var entranceMapID : int = "Tulimshar Center".hash()
	Action(NpcCommons.Warp.bind(own, entranceMapID, ENTRANCE_POS))
