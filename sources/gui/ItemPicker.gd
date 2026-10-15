extends ScrollContainer
class_name ItemPicker

#
@onready var linesBox : VBoxContainer	= $Lines

var lines : Array[ItemPickerLine]		= []

#
func Clear():
	for line in lines:
		line.queue_free()
	lines.clear()

func AddLine(cell : BaseCell, maxValue : int, value : int, ownedCount : int = -1) -> ItemPickerLine:
	var line : ItemPickerLine = ItemPickerLine.new(cell, maxValue, value, "", ownedCount)
	linesBox.add_child(line)
	lines.append(line)
	return line

func Fill(entries : Array[Dictionary]):
	Clear()
	for entry in entries:
		AddLine(entry.get("cell", null), entry.get("max", 0), entry.get("value", 0), entry.get("owned", -1))

func GetLine(cell : BaseCell) -> ItemPickerLine:
	for line in lines:
		if CellCommons.IsSameCell(line.cell, cell):
			return line
	return null

func GetValues() -> Array:
	var values : Array = []
	for line in lines:
		if line.value > 0:
			values.append([line.cell, line.value])
	return values

func Focus(cell : BaseCell = null):
	var line : ItemPickerLine = GetLine(cell) if cell else null
	if not line and not lines.is_empty():
		line = lines[0]

	if line:
		line.grab_focus.call_deferred()
		ensure_control_visible.call_deferred(line)
