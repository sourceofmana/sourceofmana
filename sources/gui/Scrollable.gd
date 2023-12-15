extends WindowPanel

@export var jsonFile: Resource						= null
@onready var textContainer : VBoxContainer			= $Scroll/Margin/VBox

const categoryColor : Color 						= Color("FFFFDD")
const nameColor : Color 							= Color("FFDDBB")
const contentColor : Color 							= Color("EECC77")
const single_line_mode : bool						= false

#
func _ready():
	Util.Assert(jsonFile != null, "No file to load for this Scrollable Window")
	if jsonFile:
		var jsonData : Dictionary = jsonFile.get_data()

		if "categories" in jsonData:
			for category in jsonData["categories"]:
				if "category" in category:
					var categoryLabel = RichTextLabel.new()
					categoryLabel.set_mouse_filter(MOUSE_FILTER_IGNORE)
					categoryLabel.bbcode_enabled = true
					categoryLabel.fit_content = true
					categoryLabel.add_theme_font_size_override("normal_font_size", 16)
					categoryLabel.add_theme_constant_override("line_separation", 5)
					categoryLabel.text = "[center][color=#" + categoryColor.to_html(false) + "]" + category["category"] + "[/color][/center]\n"
					textContainer.call_deferred("add_child", categoryLabel)

				if "entries" in category:
					for entry in category["entries"]:
						if "title" in entry:
							var titleLabel = RichTextLabel.new()
							titleLabel.set_mouse_filter(MOUSE_FILTER_IGNORE)
							titleLabel.bbcode_enabled = true
							titleLabel.fit_content = true
							titleLabel.autowrap_mode = TextServer.AUTOWRAP_OFF
							titleLabel.text = "[color=#" + nameColor.to_html(false) + "]"
							if "date" in entry:
								titleLabel.text += entry["title"] + " ~ " + entry["date"] + "[/color]\n" 
							else:
								titleLabel.text += entry["title"] + "[/color]\n" 
							titleLabel.size_flags_horizontal = RichTextLabel.SIZE_SHRINK_CENTER | RichTextLabel.SIZE_EXPAND
							textContainer.call_deferred("add_child", titleLabel)

						if "content" in entry:
							var contentLabel = RichTextLabel.new()
							contentLabel.set_mouse_filter(MOUSE_FILTER_IGNORE)
							contentLabel.bbcode_enabled = true
							contentLabel.fit_content = true
							contentLabel.add_theme_font_size_override("normal_font_size", 14)
							contentLabel.add_theme_constant_override("line_separation", 5)
							contentLabel.text = "[color=#" + contentColor.to_html(false) + "]" + entry["content"] + "[/color]\n"
							textContainer.call_deferred("add_child", contentLabel)

						if "contacts" in entry:
							var contactLabel = RichTextLabel.new()
							contactLabel.bbcode_enabled = true
							contactLabel.fit_content = true
							contactLabel.autowrap_mode = TextServer.AUTOWRAP_OFF
							contactLabel.meta_clicked.connect(_richtextlabel_on_meta_clicked)
							contactLabel.meta_underlined = false
							contactLabel.shortcut_keys_enabled = false
							contactLabel.size_flags_horizontal = RichTextLabel.SIZE_SHRINK_CENTER | RichTextLabel.SIZE_EXPAND
							contactLabel.add_theme_font_size_override("normal_font_size", 14)
							contactLabel.add_theme_constant_override("line_separation", 5)
							contactLabel.text += "[center][color=#" + contentColor.to_html(false) + "]"
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
									contactLabel.text += "[url=mailto:" + contact["mailid"] + "@" + contact["mailprovider"] + "]" + contactName + "[/url]\n"
								elif "website" in contact:
									contactLabel.text += "[url=" + contact["website"] + "]" + contactName + "[/url]\n"
								else:
									contactLabel.text += contactName + "\n"
							contactLabel.text += "[/color][/center]"
							textContainer.call_deferred("add_child", contactLabel)

func _richtextlabel_on_meta_clicked(meta):
	OS.shell_open(str(meta))
