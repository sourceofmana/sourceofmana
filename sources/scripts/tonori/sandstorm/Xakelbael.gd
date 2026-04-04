extends NpcScript

#
const checkDelay : float = 2.0

#
func OnStart():
	Mes("Who comes here?")
	Action(StartFight)

func StartFight():
	SetVisible(false)
	Spawn(npc.data._id, 1, npc.position, Vector2.ZERO)
	AddTimer(own, checkDelay, CheckFight)

func CheckFight():
	if AliveMonsterCount() > 0:
		AddTimer(own, checkDelay, CheckFight)
	else:
		EndFight()

func EndFight():
	SetVisible(true)
	Mes("You are stronger than I thought.")
