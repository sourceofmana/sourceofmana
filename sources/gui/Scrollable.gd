extends WindowPanel
class_name Scrollable

#
@export var jsonFile: Resource						= null

@onready var textContainer : VBoxContainer			= $Scroll/Margin/VBox

const categoryLabel : PackedScene					= preload("res://presets/gui/labels/CategoryLabel.tscn")
const titleLabel : PackedScene						= preload("res://presets/gui/labels/TitleLabel.tscn")
const contentLabel : PackedScene					= preload("res://presets/gui/labels/ContentLabel.tscn")
const contactLabel : PackedScene					= preload("res://presets/gui/labels/ContactLabel.tscn")

#
func Clear():
	for child in textContainer.get_children():
		textContainer.remove_child(child)

static func AddCategories(container : VBoxContainer, dictionary : Dictionary):
	if "categories" in dictionary:
		for category in dictionary["categories"]:
			if "category" in category:
				var label : RichTextLabel = categoryLabel.instantiate()
				label.text = "[center][color=#" + UICommons.LightTextColor.to_html(false) + "]" + category["category"] + "[/color][/center]\n"
				container.add_child.call_deferred(label)
			AddEntries(container, category)

static func AddEntries(container : VBoxContainer, entries : Dictionary):
	if "entries" in entries:
		for entry in entries["entries"]:
			AddTitle(container, entry)
			AddContent(container, entry)
			AddContacts(container, entry)

static func AddTitle(container : VBoxContainer, entry : Dictionary):
	if "title" in entry:
		var label : RichTextLabel = titleLabel.instantiate()
		label.text = "[color=#" + UICommons.LightTextColor.to_html(false) + "]" + entry["title"]
		if "date" in entry:
			label.text += " ~ " + entry["date"]
		label.text += "[/color]\n"
		container.add_child.call_deferred(label)

static func AddContent(container : VBoxContainer, entry : Dictionary):
	if "content" in entry:
		var label : RichTextLabel = contentLabel.instantiate()
		label.text = "[color=#" + UICommons.TextColor.to_html(false) + "]" + entry["content"] + "[/color]\n"
		label.meta_clicked.connect(_richtextlabel_on_meta_clicked)
		container.add_child.call_deferred(label)

static func _richtextlabel_on_meta_clicked(meta):
	OS.shell_open(str(meta))

static func AddContacts(container : VBoxContainer, entry : Dictionary):
	if "contacts" in entry:
		var label : RichTextLabel = contactLabel.instantiate()
		label.text += "[center][color=#" + UICommons.TextColor.to_html(false) + "]"
		for contact in entry["contacts"]:
			var contactName : String
			if "name" in contact and "nick" in contact:
				contactName = contact["name"] + "  \"" + contact["nick"] + "\""
			elif "name" in contact:
				contactName = contact["name"]
			elif "nick" in contact:
				contactName = contact["nick"]
			else:
				assert(false, "No name for this contact information")
				continue
			if "mailid" in contact and "mailprovider" in contact:
				label.text += "[url=mailto:" + contact["mailid"] + "@" + contact["mailprovider"] + "]" + contactName + "[/url]\n"
			elif "website" in contact:
				label.text += "[url=" + contact["website"] + "]" + contactName + "[/url]\n"
			else:
				label.text += contactName + "\n"
		label.text += "[/color][/center]"
		label.meta_clicked.connect(_richtextlabel_on_meta_clicked)
		container.add_child.call_deferred(label)

#
func _ready():
	Clear()
	if jsonFile:
		AddCategories(textContainer, jsonFile.get_data())

func _on_gui_input(event : InputEvent):
	Launcher.Action.TryConsume(event, "gp_zoom_in")
	Launcher.Action.TryConsume(event, "gp_zoom_out")
