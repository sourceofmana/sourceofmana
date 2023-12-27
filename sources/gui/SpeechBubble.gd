extends RichTextLabel

@onready var textLength : int			= get_total_character_count()

#
func _ready():
	var speechContent : String = get_parsed_text()
	var speechLength : float = get_theme_font("normal_font").get_string_size(speechContent).x
	if speechLength > EntityCommons.speechMaxWidth:
		speechLength = EntityCommons.speechMaxWidth
	custom_minimum_size.x = speechLength as int + EntityCommons.speechExtraWidth

func _process(_delta : float):
	if has_node("Timer"):
		var timeLeft : float = get_node("Timer").get_time_left()
		var speechIncreaseDelay : float = EntityCommons.speechDecreaseDelay

		if textLength < EntityCommons.speechIncreaseThreshold:
			speechIncreaseDelay = EntityCommons.speechDecreaseDelay / (EntityCommons.speechIncreaseThreshold - textLength)

		if timeLeft > EntityCommons.speechDelay - speechIncreaseDelay:
			var ratio : float = (EntityCommons.speechDelay - timeLeft) / speechIncreaseDelay
			visible_characters_behavior = TextServer.VC_GLYPHS_LTR
			visible_ratio = ratio
		elif timeLeft > 0 && timeLeft < EntityCommons.speechDecreaseDelay:
			var ratio : float = timeLeft / EntityCommons.speechDecreaseDelay
			modulate.a = ratio
			visible_characters_behavior = TextServer.VC_GLYPHS_RTL
			visible_ratio = ratio
		else:
			visible_ratio = 1
	else:
		visible_ratio = 1
