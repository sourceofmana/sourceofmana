class_name Effects
extends Node

#
static var shadowPool : Array				= []
static var shadowEnabled : bool				= false

static func EnableShadow(enable : bool):
	shadowEnabled = enable
	for shadow in Effects.shadowPool:
		if shadow:
			shadow.set_visible(enable)
