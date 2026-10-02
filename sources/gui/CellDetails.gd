extends PanelContainer
class_name CellDetails

#
@onready var margin : MarginContainer	= $Margin

const TileSpacing : float				= 4.0
var tile : CellTile						= null

#
func Display(target : CellTile):
	if tile != target:
		UnbindTile()
		tile = target
		BindTile()
	Refresh()

func Refresh():
	if not tile or tile.tooltip_text.is_empty():
		Close()
		return

	for child in margin.get_children():
		margin.remove_child(child)
		child.queue_free()
	margin.add_child(CellTile.MakeTooltipLabel(tile.tooltip_text))

	set_visible(true)
	reset_size()
	FollowTile()

func Close():
	UnbindTile()
	tile = null
	set_visible(false)

func Toggle(target : CellTile):
	if tile == target and is_visible():
		Close()
	else:
		Display(target)

#
func BindTile():
	if tile:
		Callback.PlugCallback(tile.visibility_changed, OnTileVisibilityChanged)
		Callback.PlugCallback(tile.tree_exiting, Close)

func UnbindTile():
	if tile:
		Callback.RemoveCallback(tile.visibility_changed, OnTileVisibilityChanged)
		Callback.RemoveCallback(tile.tree_exiting, Close)

func OnTileVisibilityChanged():
	if not tile.is_visible_in_tree():
		Close()

func FollowTile():
	if not tile:
		return
	var tileRect : Rect2 = tile.get_global_rect()
	var viewportSize : Vector2 = get_viewport_rect().size
	var target : Vector2 = Vector2(tileRect.get_center().x - size.x * 0.5, tileRect.position.y - size.y - TileSpacing)
	if target.y < 0.0:
		target.y = tileRect.end.y + TileSpacing
	target.x = clampf(target.x, 0.0, maxf(viewportSize.x - size.x, 0.0))
	target.y = clampf(target.y, 0.0, maxf(viewportSize.y - size.y, 0.0))
	global_position = target

#
func _input(event : InputEvent):
	if not is_visible() or not event is InputEventMouseButton or not event.pressed:
		return

	if tile and tile.get_global_rect().has_point(event.position):
		return

	if get_global_rect().has_point(event.position):
		get_viewport().set_input_as_handled()
	Close()

func _notification(what : int):
	if what == NOTIFICATION_DRAG_BEGIN:
		Close()

func _ready():
	resized.connect(FollowTile)
	get_viewport().size_changed.connect(Close)
	Close()
