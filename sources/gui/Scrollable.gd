extends WindowPanel

@export var jsonFile: Resource						= null
@onready var textContainer : VBoxContainer			= $Scroll/Margin/VBox


const single_line_mode : bool						= false

const categoryLabel : PackedScene					= preload("res://presets/gui/labels/CategoryLabel.tscn")
const titleLabel : PackedScene						= preload("res://presets/gui/labels/TitleLabel.tscn")
const contentLabel : PackedScene					= preload("res://presets/gui/labels/ContentLabel.tscn")
const contactLabel : PackedScene					= preload("res://presets/gui/labels/ContactLabel.tscn")

#
func _ready():
	Util.Assert(jsonFile != null, "No file to load for this Scrollable Window")
	if jsonFile:
		var jsonData : Dictionary = jsonFile.get_data()

		if "categories" in jsonData:
			for category in jsonData["categories"]:
				if "category" in category:
					var label : RichTextLabel = categoryLabel.instantiate()
					label.text = "[center][color=#" + UICommons.LightTextColor.to_html(false) + "]" + category["category"] + "[/color][/center]\n"
					textContainer.add_child.call_deferred(label)

				if "entries" in category:
					for entry in category["entries"]:
						if "title" in entry:
							var label : RichTextLabel = titleLabel.instantiate()
							label.text = "[color=#" + UICommons.LightTextColor.to_html(false) + "]" + entry["title"]
							if "date" in entry:
								label.text += " ~ " + entry["date"]
							label.text += "[/color]\n"
							textContainer.add_child.call_deferred(label)

						if "content" in entry:
							var label : RichTextLabel = contentLabel.instantiate()
							label.text = "[color=#" + UICommons.TextColor.to_html(false) + "]" + entry["content"] + "[/color]\n"
							textContainer.add_child.call_deferred(label)

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
									Util.Assert(false, "No name for this contact information")
									continue

								if "mailid" in contact and "mailprovider" in contact:
									label.text += "[url=mailto:" + contact["mailid"] + "@" + contact["mailprovider"] + "]" + contactName + "[/url]\n"
								elif "website" in contact:
									label.text += "[url=" + contact["website"] + "]" + contactName + "[/url]\n"
								else:
									label.text += contactName + "\n"
							label.text += "[/color][/center]"
							textContainer.add_child.call_deferred(label)

func _richtextlabel_on_meta_clicked(meta):
	OS.shell_open(str(meta))
