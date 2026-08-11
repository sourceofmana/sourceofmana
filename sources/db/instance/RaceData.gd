extends Resource
class_name RaceData

#
@export var name : String						= "Unknown"
@export var faces : Array[Texture2D]			= []
@export var bodies : Array[Texture2D]			= []
@export var skins : Dictionary[String, Material]	= {}

#
func GetSkinMaterial(skintone : int) -> Material:
	for skinName in skins:
		if skinName.hash() == skintone:
			return skins[skinName]
	return null

func HasSkin(skintone : int) -> bool:
	for skinName in skins:
		if skinName.hash() == skintone:
			return true
	return false

func StripServer():
	pass

func StripClient():
	faces = []
	bodies = []
	var strippedSkins : Dictionary[String, Material] = {}
	for key in skins:
		strippedSkins[key] = null
	skins = strippedSkins
