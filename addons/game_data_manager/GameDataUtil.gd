@tool
class_name GameDataUtil

# https://github.com/godotengine/godot-proposals/issues/900#issuecomment-1812881718
static func is_part_of_edited_scene(node: Node):
	return Engine.is_editor_hint() && node.is_inside_tree() && node.get_tree().get_edited_scene_root() && (node.get_tree().get_edited_scene_root() == node || node.get_tree().get_edited_scene_root().is_ancestor_of(node))

static func ShowErrorDialog(parent : Node, message : String):
	var errorDialog : AcceptDialog = AcceptDialog.new()
	errorDialog.title = "Error"
	errorDialog.dialog_text = message
	parent.add_child(errorDialog)
	errorDialog.popup_centered()
	errorDialog.confirmed.connect(errorDialog.queue_free)

static func SaveResource(resource : Resource):
	var filepath : String = resource.resource_path
	if filepath:
		var error : int = ResourceSaver.save(resource, filepath)
		if error != OK:
			printerr("Failed to save resource: ", filepath, " Error: ", error)

static func GetModifierName(effect : CellCommons.Modifier) -> String:
	for key in CellCommons.Modifier.keys():
		if CellCommons.Modifier[key] == effect:
			return key
	return "Unknown"

static func FormatModifiers(cellModifier : CellModifier) -> String:
	if not cellModifier:
		return "None"
	if not cellModifier._modifiers or cellModifier._modifiers.is_empty():
		return "None"
	var parts : Array[String] = []
	for modifier in cellModifier._modifiers:
		if modifier:
			var effectName : String = GetModifierName(modifier._effect)
			var valueStr : String = str(modifier._value)
			if modifier._value > 0:
				valueStr = "+" + valueStr
			var modStr : String = effectName + " " + valueStr
			if modifier._persistent:
				modStr += " (P)"
			parts.push_back(modStr)
	return ", ".join(parts) if not parts.is_empty() else "None"
