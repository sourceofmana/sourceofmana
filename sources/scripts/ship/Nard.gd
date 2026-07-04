extends NpcScript

#
func OnStart():
	Mes("Ready to head back out on the water?")
	Choice("Yes, let's sail!", OnSail)
	Choice("Not yet.", Dismiss)

func OnSail():
	var player : PlayerAgent = own as PlayerAgent
	if player and player.exploreOrigin:
		player.Morph(false, DB.ShipHash)
		Warp("Overworld".hash(), player.exploreOrigin.pos)

func Dismiss():
	Chat("Take your time.")
