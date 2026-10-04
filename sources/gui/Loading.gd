extends Control

#
@export_range (0.1, 10.0) var speed : float		= 2.0
@onready var progress : TextureProgressBar		= $Progress
@onready var label : Label						= $Label

var currentTween : Tween						= null
var progressLines : Array[String]				= []
var lineIdx : int								= 0
var lineShownTimestamp : int					= 0

const MinLineDurationMs : int					= 1500
const DefaultText : String						= "Loading..."
const ProgressLines : PackedStringArray			= [
	"Making pixel squarish",
	"Turn on the lights",
	"Shade our particles",
	"Shake the sandglobe",
	"Feed the slimes",
]

#
func SetProgress(current : int, total : int):
	if current >= total:
		label.set_text(DefaultText)
		return

	if progressLines.is_empty():
		progressLines.assign(ProgressLines)
		progressLines.shuffle()
		lineShownTimestamp = Time.get_ticks_msec()

	var ratio : float = float(current) / total
	var targetLineIdx : int = mini(floori(ratio * progressLines.size()), progressLines.size() - 1)
	if targetLineIdx > lineIdx and Time.get_ticks_msec() - lineShownTimestamp >= MinLineDurationMs:
		lineIdx += 1
		lineShownTimestamp = Time.get_ticks_msec()
	label.set_text("%s... %d%%" % [progressLines[lineIdx], floori(ratio * 100.0)])

func _on_visibility_changed() -> void:
	if visible:
		if currentTween:
			currentTween.kill()
		currentTween = create_tween()
		currentTween.set_loops()
		currentTween.tween_property(progress, "radial_initial_angle", 360, speed).from(0)
		currentTween.play()
		create_tween().set_parallel(true).tween_property(progress, "modulate:a", 1.0, speed).set_ease(Tween.EASE_IN)
	else:
		if currentTween:
			currentTween.stop()
			currentTween = null
		if progress:
			progress.modulate.a = 0

func _ready():
		progress.modulate.a = 0
