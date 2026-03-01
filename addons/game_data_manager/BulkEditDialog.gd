@tool
extends AcceptDialog

#
signal bulk_edit_applied(property : String, value : Variant)

#
var propertySelector : OptionButton = null
var valueEditor : Control = null
var currentPropertyType : int = TYPE_NIL

#
func _ready():
	title = "Bulk Edit Items"
	dialog_text = "Select a property to edit for all filtered items:"

	var vbox : VBoxContainer = VBoxContainer.new()
	add_child(vbox)

	var propLabel : Label = Label.new()
	propLabel.text = "Property:"
	vbox.add_child(propLabel)

	propertySelector = OptionButton.new()
	vbox.add_child(propertySelector)

	var valueLabel : Label = Label.new()
	valueLabel.text = "New Value:"
	vbox.add_child(valueLabel)

	valueEditor = VBoxContainer.new()
	vbox.add_child(valueEditor)

	propertySelector.item_selected.connect(_on_property_selected)

func _on_property_selected(_index : int):
	for child in valueEditor.get_children():
		child.queue_free()

	var edit : LineEdit = LineEdit.new()
	edit.placeholder_text = "Enter new value"
	valueEditor.add_child(edit)

func GetPropertyIndex() -> int:
	if propertySelector.selected == -1:
		return -1
	return propertySelector.get_item_id(propertySelector.selected)

func GetNewValue() -> Variant:
	if valueEditor.get_child_count() == 0:
		return null

	var editor : Node = valueEditor.get_child(0)
	if editor is LineEdit:
		return editor.text
	elif editor is CheckBox:
		return editor.button_pressed
	elif editor is SpinBox:
		return editor.value
	return null
