@tool
extends Area2D
class_name TriggerObject

@export var polygon : PackedVector2Array	= []

var linkedNpc : NpcAgent					= null
var playersInside : Dictionary[int, bool]	= {}
var pendingExits : Dictionary[int, Array]	= {}

const ExitGraceTicks : int					= 3

#
func bodyEntered(body : CollisionObject2D):
	if not linkedNpc or not linkedNpc.ownScript or body is not PlayerAgent:
		return
	var rid : int = body.get_rid().get_id()
	if pendingExits.has(rid):
		pendingExits.erase(rid)
		return
	if not playersInside.has(rid):
		playersInside[rid] = true
		linkedNpc.ownScript.OnAreaEnter.call_deferred(body)

func bodyExited(body : CollisionObject2D):
	if not linkedNpc or not linkedNpc.ownScript or body is not PlayerAgent:
		return
	var rid : int = body.get_rid().get_id()
	if playersInside.has(rid):
		pendingExits[rid] = [ExitGraceTicks, body]

func _physics_process(_delta : float):
	if pendingExits.is_empty():
		return
	for rid in pendingExits.keys():
		pendingExits[rid][0] -= 1
		if pendingExits[rid][0] <= 0:
			var player : PlayerAgent = pendingExits[rid][1]
			pendingExits.erase(rid)
			if playersInside.has(rid):
				playersInside.erase(rid)
				if linkedNpc and linkedNpc.ownScript:
					linkedNpc.ownScript.OnAreaExit.call_deferred(player)

#
func _ready():
	collision_mask = 1
	collision_layer = 0

	body_entered.connect(bodyEntered)
	body_exited.connect(bodyExited)
