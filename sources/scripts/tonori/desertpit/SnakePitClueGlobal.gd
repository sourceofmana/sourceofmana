extends NpcScript
class_name SnakePitClueGlobal

# Disable clues until this quest is correctly implemented
func OnStart():
	WorldAgent.RemoveAgent.call_deferred(npc)
