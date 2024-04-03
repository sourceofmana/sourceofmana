extends WindowPanel

@onready var weightStat : Control		= $Margin/VBoxContainer/Weight/BgTex/Weight
@onready var itemGrid : GridContainer	= $Margin/VBoxContainer/ItemContainer/Grid
@onready var itemContainer : Container	= $Margin/VBoxContainer/ItemContainer
@onready var tilePreset : Resource		= FileSystem.LoadGui("inventory/ItemGridTile", false)

#
# Update Weight Stat with Formula.GetWeight
func Refresh():
	pass
