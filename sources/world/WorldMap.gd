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
				var spawnObject = SpawnObject.new()
				spawnObject.count = spawn[0]
				spawnObject.id = spawn[1]
				spawnObject.type = spawn[2]
				spawnObject.spawn_position = spawn[3]
				spawnObject.spawn_offset = spawn[4]
				spawnObject.respawn_delay = spawn[5]
				spawnObject.player_script = spawn[6]
				spawnObject.own_script = spawn[7]
				spawnObject.nick = spawn[8]
				spawnObject.is_always_visible = spawn[9] if spawn.size() > 9 else false
				spawnObject.direction = spawn[10] if spawn.size() > 10 else ActorCommons.Direction.UNKNOWN
				spawnObject.state = spawn[11] if spawn.size() > 11 else ActorCommons.State.UNKNOWN
				spawnObject.has_trigger = spawn[12] if spawn.size() > 12 else false
				spawnObject.trigger_radius = spawn[13] if spawn.size() > 13 else 0.0
				spawnObject.trigger_polygon = spawn[14] if spawn.size() > 14 else PackedVector2Array()
				spawnObject.destination_map = spawn[15] if spawn.size() > 15 else DB.UnknownHash
				spawnObject.destination_pos = spawn[16] if spawn.size() > 16 else Vector2.ZERO
				spawnObject.auto_warp = spawn[17] if spawn.size() > 17 else true
				spawnObject.sailing_pos = spawn[18] if spawn.size() > 18 else Vector2.ZERO
				spawnObject.is_global = spawnObject.spawn_position < Vector2i.LEFT
				spawnObject.is_persistant = true
				spawnObject.map = self
				spawns.append(spawnObject)
func HasFlags(checkedFlags : Flags) -> bool: return !!(flags & checkedFlags)
