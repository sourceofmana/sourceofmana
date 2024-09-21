extends ColorRect
class_name CellTile

@export var draggable : bool			= false
@onready var icon : TextureRect			= $Icon
@onready var countLabel : Label			= $Count
@onready var cooldownLabel : Label		= $Cooldown
var cell : BaseCell						= null
var cooldownTimer : float				= -INF
var shineTimer : float					= -INF
var count : int							= 0

const modulateDisable : float			= 0.5

# Private
func SetToolTip():
	var tooltip : String = ""
	if cell:
		tooltip = cell.name
		if cell.description:
			tooltip += "\n" + cell.description
		if cell.weight == 0:
			tooltip += "\n\nWeight: " + str(cell.weight) + "g"
	set_tooltip_text(tooltip)

func UpdateCountLabel():
	if countLabel:
		if count >= 1000:
			countLabel.text = "999+"
		elif count <= 1:
			countLabel.text = ""
		else:
			countLabel.text = str(count)
	if icon:
		var modColor : Color = Color.BLACK if count <= 0 else Color.WHITE
		modColor.a = modulateDisable if count <= 0 else 1.0
		icon.material.set_shader_parameter("modulate", modColor)

# Public
func AssignData(newCell : BaseCell, newCount : int = 1):
	if cell != newCell:
		if cell:
			UnassignData(cell)
		if newCell:
			newCell.used.connect(Used)
	cell = newCell
	count = newCount
	if icon:
		icon.set_texture(cell.icon if cell else null)
	UpdateCountLabel()
	SetToolTip()
	if not draggable:
		set_visible(count > 0 and cell != null)

func UnassignData(sourceCell : BaseCell):
	icon.material.set_shader_parameter("progress", -INF)
	icon.material.set_shader_parameter("modulate", Color.WHITE)
	if sourceCell:
		if sourceCell.used.is_connected(Used):
			sourceCell.used.disconnect(Used)

static func RefreshShortcuts(baseCell : BaseCell, newCount : int = -1):
	if baseCell == null or not Launcher.Player or not Launcher.Player.inventory:
		return

	if baseCell.type != CellCommons.Type.ITEM:
		newCount = 1
	elif newCount < 0:
		newCount = 0
		for item in Launcher.Player.inventory.items:
			if item and item.cell and item.cell == baseCell:
				newCount = item.count
				break

	var tiles : Array[Node] = Launcher.GUI.get_tree().get_nodes_in_group("CellTile")
	for shortcutTile in tiles:
		if shortcutTile and shortcutTile.is_visible() and shortcutTile.draggable and shortcutTile.cell == baseCell:
			shortcutTile.count = newCount
			shortcutTile.UpdateCountLabel()

func UseCell():
	if cell:
		cell.Use()

func Used(cooldown : float = 0.0):
	cooldownTimer = cooldown

func ClearCooldown():
	cooldownTimer = -INF
	cooldownLabel.text = ""
	UpdateCountLabel()
	if count > 0:
		shineTimer = 1.0

# Drag
func _get_drag_data(_position : Vector2):
	if cell and cell.usable:
		if icon:
			set_drag_preview(icon.duplicate())
		return cell
	return null

func _can_drop_data(_at_position : Vector2, data):
	return draggable and data is BaseCell and data != cell and data.usable

func _drop_data(_at_position : Vector2, data):
	AssignData(data)
	CellTile.RefreshShortcuts(data)

# Default
func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.double_click:
			UseCell()

func _process(delta):
	if cooldownTimer != -INF:
		cooldownTimer -= delta
		if cooldownTimer <= 0.0 or Launcher.Player == null:
			ClearCooldown()
		else:
			if cell.type == CellCommons.Type.SKILL:
				var cooldown : float = SkillCommons.GetCooldown(Launcher.Player, cell)
				var cooldownRatio : float = cooldownTimer / cooldown if cooldown > cooldownTimer else 1.0
				var modColor : Color = Color.GRAY.lerp(Color.BLACK, cooldownRatio)
				modColor.a = modulateDisable + (cooldownRatio * (1.0 - modulateDisable))
				icon.material.set_shader_parameter("modulate", modColor)
				cooldownLabel.text = ("%.1f" if cooldownTimer < 10 else "%.0f") % [cooldownTimer]
	elif shineTimer != -INF:
		shineTimer -= delta
		if shineTimer <= 0.0 or Launcher.Player == null:
			shineTimer = -INF
		icon.material.set_shader_parameter("progress", shineTimer)
