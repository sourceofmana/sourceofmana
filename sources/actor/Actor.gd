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

func Init(_type : ActorCommons.Type, _data : EntityData, _nick : String = "", isManaged : bool = false):
	if not _data:
		return

	data = _data
	type = _type
	nick = _nick
	Callback.PlugCallback(ready, SetData)

	if type == ActorCommons.Type.PLAYER and isManaged:
		inventory = ActorInventory.new()
		progress = ActorProgress.new()

	if inventory:
		inventory.Init(self)

	if stat:
		stat.Init(self, data)
