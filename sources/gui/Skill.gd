extends WindowPanel

@onready var grid : GridContainer		= $ItemContainer/Grid

#
func RefreshSkills():
	if not Launcher.Player or not Launcher.Player.progress:
		return

	var tileIdx : int		= 0
	var tile : CellTile		= grid.tiles[tileIdx]
	for skillID in Launcher.Player.progress.skills:
		var skill : SkillCell = DB.GetSkill(skillID)
		if skill is SkillCell:
			CellTile.RefreshShortcuts(skill, 1)
			if tile:
				tile.AssignData(skill)
				tileIdx += 1
				tile = grid.GetTile(tileIdx)

	for remainingIdx in range(tileIdx, grid.maxCount):
		grid.tiles[remainingIdx].AssignData(null, 0)

#
func _ready():
	RefreshSkills()
