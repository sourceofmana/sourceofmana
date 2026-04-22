@tool
extends Area2D
class_name TriggerObject

@export var polygon : PackedVector2Array	= []

var linkedNpc : NpcAgent					= null
var playersInside : Dictionary[int, bool]	= {}

#
func bodyEntered(body : CollisionObject2D):
	if not linkedNpc or not linkedNpc.ownScript or body is not PlayerAgent:
		return
	if not body.is_inside_tree() or body.isWarping:
		return

	var rid : int = body.get_rid().get_id()
	if not playersInside.has(rid):
		playersInside[rid] = true
		Callback.OneShotCallback(body.tree_exiting, OnPlayerLeft, [rid])
		linkedNpc.ownScript.OnAreaEnter.call_deferred(body)

func bodyExited(body : CollisionObject2D):
	if not linkedNpc or not linkedNpc.ownScript or body is not PlayerAgent:
		return

	var rid : int = body.get_rid().get_id()
	if playersInside.has(rid):
		playersInside.erase(rid)
		if body.is_inside_tree():
			linkedNpc.ownScript.OnAreaExit.call_deferred(body)

func OnPlayerLeft(rid : int):
	playersInside.erase(rid)

#
func _ready():
	collision_mask = 1
	collision_layer = 0

	body_entered.connect(bodyEntered)
	body_exited.connect(bodyExited)
