extends MerchantScript

#
func GetStock() -> PackedStringArray:
	return ["Shorts", "Cotton Shirt", "Tank Top"]

func OnStart():
	Mes("Welcome! Simple clothes, ready for the desert heat.")
	super.OnStart()
