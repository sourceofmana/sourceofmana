extends MerchantScript

#
func GetStock() -> PackedStringArray:
	return ["Bandana Scarf", "Desert Boots"]

func OnStart():
	Mes("Hot sand burns through bare feet in no time. Need some boots?")
	super.OnStart()
