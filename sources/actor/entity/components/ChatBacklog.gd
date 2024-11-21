extends Object
class_name ChatBacklog

#
var sentLog : Array[String]				= []
var currentIdx : int					= 0

#
func Up() -> String:
	currentIdx = currentIdx - 1 if currentIdx > 0 else sentLog.size()
	return Get()

func Down() -> String:
	currentIdx = currentIdx + 1 if currentIdx < sentLog.size() else sentLog.size()
	return Get()

func Add(logEntry : String):
	sentLog.append(logEntry)
	currentIdx = sentLog.size()

func Get() -> String:
	return sentLog[currentIdx] if currentIdx >= 0 && currentIdx < sentLog.size() else ""
