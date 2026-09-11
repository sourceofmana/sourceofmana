extends CellScript
class_name BuffAbility

#
func Execute(agent : BaseAgent, cell : BaseCell):
	var skill : SkillCell = cell as SkillCell
	if skill:
		agent.stat.buffs.ApplyCell(skill, skill.buffTime)
