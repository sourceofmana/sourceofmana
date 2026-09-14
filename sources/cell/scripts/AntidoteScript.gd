extends CellScript
class_name AntidoteScript

#
const CureSkillName : StringName = "Poison"

#
func Execute(target : BaseAgent, _cell : BaseCell):
	target.stat.buffs.ClearSkill(DB.GetCellHash(CureSkillName))
