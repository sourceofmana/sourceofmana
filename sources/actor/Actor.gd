extends CharacterBody2D
class_name Actor

#
var inventory : ActorInventory			= null
var progress : ActorProgress			= null
var state : ActorCommons.State			= ActorCommons.State.IDLE
var stat : ActorStats					= ActorStats.new()
var type : ActorCommons.Type			= ActorCommons.Type.NPC
var nick : String						= ""

#
func SetData(_data : EntityData):
	pass

func Init(_type : ActorCommons.Type, _ID : String, _nick : String = "", isManaged : bool = false):
	var data : EntityData = Instantiate.FindEntityReference(_ID)
	Util.Assert(data != null, "Could not create the actor: %s" % _ID)
	if not data:
		return

	type = _type
	nick = _ID if _nick.is_empty() else _nick
	Callback.PlugCallback(ready, SetData, [data])

	if type == ActorCommons.Type.PLAYER and isManaged:
		inventory = ActorInventory.new()
		progress = ActorProgress.new()

	if inventory:
		inventory.Init(self)

	if stat:
		stat.Init(self, data)
