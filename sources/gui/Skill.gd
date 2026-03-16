extends WindowPanel

@onready var spellGrid : GridContainer		= $VBoxContainer/TabContainer/Spells/ScrollContainer/SpellGrid
@onready var physicalGrid : GridContainer	= $VBoxContainer/TabContainer/Physical/ScrollContainer/PhysicalGrid
@onready var abilityGrid : GridContainer	= $VBoxContainer/TabContainer/Abilities/ScrollContainer/AbilityGrid

#
func RefreshSkills():
	if not Launcher.Player or not Launcher.Player.progress:
		return

	var spellIdx : int		= 0
	var physicalIdx : int	= 0
	var abilityIdx : int	= 0

	for skillID in Launcher.Player.progress.skills:
		var skill : SkillCell = DB.GetSkill(skillID)
		if not skill is SkillCell:
			continue
		CellTile.RefreshShortcuts(skill, 1)
		match skill.category:
			SkillCell.Category.SPELL:
				var tile : CellTile = spellGrid.GetTile(spellIdx)
				if tile:
					tile.AssignData(skill)
					spellIdx += 1
			SkillCell.Category.PHYSICAL:
				var tile : CellTile = physicalGrid.GetTile(physicalIdx)
				if tile:
					tile.AssignData(skill)
					physicalIdx += 1
			SkillCell.Category.ABILITY:
				var tile : CellTile = abilityGrid.GetTile(abilityIdx)
				if tile:
					tile.AssignData(skill)
					abilityIdx += 1

	for remainingIdx in range(spellIdx, spellGrid.maxCount):
		spellGrid.tiles[remainingIdx].AssignData(null, 0)
	for remainingIdx in range(physicalIdx, physicalGrid.maxCount):
		physicalGrid.tiles[remainingIdx].AssignData(null, 0)
	for remainingIdx in range(abilityIdx, abilityGrid.maxCount):
		abilityGrid.tiles[remainingIdx].AssignData(null, 0)

#
func _ready():
	RefreshSkills()
