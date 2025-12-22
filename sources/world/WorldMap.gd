class_name WorldMap
extends Object

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
var instances : Array[WorldInstance]	= []
var spawns : Array[SpawnObject]			= []
var warps : Array[WarpObject]			= []
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
		map.instances.append(WorldInstance.Create(map))

	return map

func Destroy():
	for inst in instances:
		inst.Destroy()
		inst.queue_free()
	instances.clear()
	for warp in warps:
		warp.queue_free()
	warps.clear()

func LoadMapData():
	var resource : Resource = Instantiate.LoadMapData(id, Path.MapServerExt)
	if resource:
		flags = resource.flags
		for spawn in resource.spawns:
			assert(spawn != null, "Warp format is not supported")
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
				spawnObject.is_global = spawnObject.spawn_position < Vector2i.LEFT
				spawnObject.is_persistant = true
				spawnObject.map = self
				spawns.append(spawnObject)
		for warp in resource.warps:
			assert(warp != null, "Warp format is not supported")
			if warp:
				var warpObject = WarpObject.new()
				warpObject.destinationID = warp[0]
				warpObject.destinationPos = warp[1]
				warpObject.polygon = warp[2]
				if warp.size() > 3:
					warpObject.autoWarp = warp[3]
				warps.append(warpObject)
		for port in resource.ports:
			assert(port != null, "Port format is not supported")
			if port:
				var portObject = PortObject.new()
				portObject.destinationID = port[0]
				portObject.destinationPos = port[1]
				portObject.polygon = port[2]
				portObject.autoWarp = port[3]
				portObject.sailingPos = port[4]
				warps.append(portObject)

func HasFlags(checkedFlags : Flags) -> bool: return !!(flags & checkedFlags)
