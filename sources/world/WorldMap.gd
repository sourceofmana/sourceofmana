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
var name : String						= ""
var instances : Array[WorldInstance]	= []
var spawns : Array[SpawnObject]			= []
var warps : Array[WarpObject]			= []
var flags : int							= Flags.NONE
var navPoly : NavigationPolygon			= null
var mapRID : RID						= RID()
var regionRID : RID						= RID()

#
static func Create(mapName : String) -> WorldMap:
	var map : WorldMap = WorldMap.new()
	map.name = mapName
	map.LoadMapData()
	WorldNavigation.LoadData(map)
	map.instances.append(WorldInstance.Create(map))

	return map

func LoadMapData():
	var node : Node = Instantiate.LoadMapData(name, Path.MapServerExt)
	if node:
		if "flags" in node:
			flags = node.flags
		if "spawns" in node:
			for spawn in node.spawns:
				assert(spawn != null, "Warp format is not supported")
				if spawn:
					var spawnObject = SpawnObject.new()
					spawnObject.count = spawn[0]
					spawnObject.name = spawn[1]
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
		if "warps" in node:
			for warp in node.warps:
				assert(warp != null, "Warp format is not supported")
				if warp:
					var warpObject = WarpObject.new()
					warpObject.destinationMap = warp[0]
					warpObject.destinationPos = warp[1]
					warpObject.polygon = warp[2]
					if warp.size() > 3:
						warpObject.autoWarp = warp[3]
					warps.append(warpObject)
		if "ports" in node:
			for port in node.ports:
				assert(port != null, "Port format is not supported")
				if port:
					var portObject = PortObject.new()
					portObject.destinationMap = port[0]
					portObject.destinationPos = port[1]
					portObject.polygon = port[2]
					portObject.autoWarp = port[3]
					portObject.sailingPos = port[4]
					warps.append(portObject)

func HasFlags(checkedFlags : Flags) -> bool: return !!(flags & checkedFlags)
