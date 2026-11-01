extends MerchantScript

#
func GetStock() -> PackedStringArray:
	return ["Short Sword", "Cleaver", "Gladius"]

func OnStart():
	Mes("Need a blade? The guards come to me for theirs.")
	super.OnStart()
