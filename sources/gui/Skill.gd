extends WindowPanel

@onready var grid : GridContainer		= $ItemContainer/Grid

#
func RefreshSkills():
	var tileIdx : int		= 0
	var tile : CellTile		= grid.tiles[tileIdx]

	for skillID in DB.SkillsDB:
		var skill : BaseCell = DB.SkillsDB[skillID]
		if skill is BaseCell:
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
