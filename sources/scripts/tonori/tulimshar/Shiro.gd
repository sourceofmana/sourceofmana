extends MerchantScript

#
func GetStock() -> PackedStringArray:
	return ["Desert Goggles", "Ghutra", "Desert Hood"]

func OnStart():
	Mes("Heading into the sandstorm without proper headgear? You'll turn into a sand golem in no time!")
	super.OnStart()
