extends Node

#
func Assert(cond : bool, message : String) -> void:
	if OS.is_debug_build():
		printerr(cond, message)
		if not cond:
			push_warning(message)
