class_name WorldMap
extends RefCounted

#
enum Flags
{
	NONE = 0,
	NO_DROP = 1 << 0,
	NO_SPELL = 1 << 1,
	NO_REJOIN = 1 << 2,
	ONLY_SPIRIT = 1 << 3,
}

#
var id : int							= DB.UnknownHash
var name : String						= ""
var instances : Dictionary[int, WorldInstance]	= {}
var spawns : Array[SpawnObject]			= []
var flags : int							= Flags.NONE
var navPoly : NavigationPolygon			= null
var mapRID : RID						= RID()
var regionRID : RID						= RID()

#
static func Create(mapID : int) -> WorldMap:
	var map : WorldMap = null
	var mapData : FileData = DB.MapsDB.get(mapID, null)
	if mapData:
		map = WorldMap.new()
		map.id = mapID
		map.name = mapData._name
		map.LoadMapData()
		WorldNavigation.LoadData(map)
		map.CreateInstance(0)

	return map

func CreateInstance(instanceID : int) -> WorldInstance:
	var inst : WorldInstance = WorldInstance.Create(self, instanceID)
	instances[instanceID] = inst
	return inst

func DestroyInstance(instanceID : int):
	var inst : WorldInstance = instances.get(instanceID, null)
	if inst:
		inst.Destroy()
		instances.erase(instanceID)

func Destroy():
	for instanceID in instances.keys():
		DestroyInstance(instanceID)

func LoadMapData():
	var resource : Resource = Instantiate.LoadMapData(id)
	if resource:
		flags = resource.flags
		for spawn in resource.spawns:
			assert(spawn != null, "Spawn format is not supported")
			if spawn:
				spawn.map = self
				spawns.append(spawn)
func HasFlags(checkedFlags : Flags) -> bool: return !!(flags & checkedFlags)
