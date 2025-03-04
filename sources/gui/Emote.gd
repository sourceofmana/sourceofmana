@tool
extends WindowPanel

@onready var grid : GridContainer		= $ItemContainer/Grid

#
func RefreshEmotes():
	var tileIdx : int		= 0
	var tile : CellTile		= grid.tiles[tileIdx]

	for emoteName in DB.EmotesDB:
		var emote : BaseCell = DB.EmotesDB[emoteName]
		if emote is BaseCell:
			CellTile.RefreshShortcuts(emote, 1)
			if tile:
				tile.AssignData(emote)
				tileIdx += 1
				tile = grid.GetTile(tileIdx)

	for remainingIdx in range(tileIdx, grid.maxCount):
		grid.tiles[remainingIdx].AssignData(null, 0)

#
func _ready():
	RefreshEmotes()
