extends Tree
class_name TableView

#
func SetHeader(header : PackedStringArray):
	columns = maxi(header.size(), 1)
	for column in header.size():
		set_column_title(column, header[column])
		set_column_title_alignment(column, HORIZONTAL_ALIGNMENT_LEFT)
		set_column_expand(column, true)

func SetRows(rows : Array):
	clear()
	var root : TreeItem = create_item()
	for row in rows:
		var item : TreeItem = create_item(root)
		for column in mini(row.size(), columns):
			item.set_text(column, str(row[column]))

	custom_minimum_size.y = GetFitHeight(rows.size())

func SetCellColor(rowIndex : int, column : int, color : Color):
	var root : TreeItem = get_root()
	if root and rowIndex < root.get_child_count():
		root.get_child(rowIndex).set_custom_color(column, color)

func GetFitHeight(rowCount : int) -> float:
	var rowHeight : float = get_theme_font("font").get_height(get_theme_font_size("font_size")) \
		+ get_theme_constant("v_separation") \
		+ get_theme_constant("inner_item_margin_top") \
		+ get_theme_constant("inner_item_margin_bottom")

	var titleHeight : float = get_theme_font("title_button_font").get_height(get_theme_font_size("title_button_font_size")) \
		+ get_theme_stylebox("title_button_normal").get_minimum_size().y

	return rowHeight * maxi(rowCount, 1) + titleHeight + get_theme_stylebox("panel").get_minimum_size().y

#
func _init(header : PackedStringArray = []):
	hide_root = true
	column_titles_visible = true
	select_mode = SELECT_ROW
	scroll_vertical_enabled = false
	size_flags_horizontal = SIZE_EXPAND_FILL
	SetHeader(header)
