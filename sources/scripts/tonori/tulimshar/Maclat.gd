extends MerchantScript

#
func GetStock() -> PackedStringArray:
	return ["Shorts", "Cotton Shirt", "Tank Top"]

func OnStart():
	Mes("Get yourself something light before the sun cooks you alive!")
	super.OnStart()
