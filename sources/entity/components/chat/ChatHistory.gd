extends Object
class_name ChatHistory

#
var sentLog : Array[String]				= []
var currentIdx : int					= 0

#
func Up():
	currentIdx = currentIdx - 1 if currentIdx > 0 else sentLog.size()

func Down():
	currentIdx = currentIdx + 1 if currentIdx < sentLog.size() else sentLog.size()

func Add(log : String):
	sentLog.append(log)
	currentIdx = sentLog.size()

func Get() -> String:
	return sentLog[currentIdx] if currentIdx >= 0 && currentIdx < sentLog.size() else ""
