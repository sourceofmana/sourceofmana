extends BaseAgent
class_name MonsterAgent

#
func Trigger(caller : BaseAgent):
	if caller && caller.SetState(EntityCommons.State.ATTACK):
		var dmgValue : int = 20
		stat.health -= dmgValue
		# Get the player's attack value and trigger:
#		Launcher.Network.Notify("damange_dealt", caller.get_rid().get_id(), dmgValue)
		# Use AiTimer to set a countdown before the death vanish and trigger:
#		Launcher.World.RemoveAgent(self)
