extends Node

#
func Assert(condition : bool, message : String) -> void:
	if OS.is_debug_build() && not condition:
		printerr(message)
		push_warning(message)

func PrintLog(logString : String):
	print(logString)
