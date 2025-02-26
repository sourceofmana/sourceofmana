extends CharacterBody2D
class_name Actor

#
var inventory : ActorInventory			= null
var progress : ActorProgress			= null
var state : ActorCommons.State			= ActorCommons.State.IDLE
var stat : ActorStats					= ActorStats.new()
var type : ActorCommons.Type			= ActorCommons.Type.NPC
var nick : String						= ""
var data : EntityData					= null

#
func SetData():
	pass

func _init(_type : ActorCommons.Type = ActorCommons.Type.NPC, _data : EntityData = null, _nick : String = "", isManaged : bool = false):
	if not _data:
		return

	data = _data
	type = _type
	nick = _nick
	Callback.PlugCallback(ready, SetData)

	if type == ActorCommons.Type.PLAYER:
		inventory = ActorInventory.new(self)
	progress = ActorProgress.new(self, isManaged and type == ActorCommons.Type.PLAYER)

	if stat:
		stat.Init(self, data)
