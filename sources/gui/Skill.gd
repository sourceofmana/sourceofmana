extends WindowPanel

@onready var grid : GridContainer		= $ItemContainer/Grid

#
func RefreshSkills():
	var tileIdx : int		= 0
	var tile : CellTile		= grid.tiles[tileIdx]

	for skillName in DB.SkillsDB:
		var skill : BaseCell = DB.SkillsDB[skillName]
		if skill is BaseCell:
			CellTile.RefreshShortcuts(skill, 1)
			if tile:
				tile.SetData(skill)
				tileIdx += 1
				tile = grid.GetTile(tileIdx)

	for remainingIdx in range(tileIdx, grid.maxCount):
		grid.tiles[remainingIdx].SetData(null, 0)

#
func _ready():
	RefreshSkills()
