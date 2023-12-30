class_name Effects
extends Node

#
static var lightLayer : CanvasLayer				= null
static var lightingEnabled : bool				= false

static func EnableLighting(enable : bool):
	lightingEnabled = enable
	if lightLayer:
		lightLayer.set_visible(enable)
