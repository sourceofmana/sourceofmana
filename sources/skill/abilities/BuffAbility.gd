extends CellScript
class_name BuffAbility

#
func Execute(target : BaseAgent, cell : BaseCell):
	var skill : SkillCell = cell as SkillCell
	if skill and target:
		target.stat.buffs.ApplyCell(skill, skill.buffTime)
