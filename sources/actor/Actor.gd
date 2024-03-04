extends CharacterBody2D
class_name Actor

#
var inventory : EntityInventory			= EntityInventory.new()
var state : ActorCommons.State			= ActorCommons.State.IDLE
var stat : ActorStats					= ActorStats.new()
