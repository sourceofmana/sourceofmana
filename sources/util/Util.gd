extends Node

#
func Assert(cond : bool, message : String) -> void:
	if OS.is_debug_build() && not cond:
		printerr(message)
		push_warning(message)

func PrintLog(log : String):
	print(log)
