extends Polygon2D
class_name AmbientPolygon2D

@onready var subViewport : SubViewport = $SubViewport
@onready var line2D : Line2D = $SubViewport/Line2D

#
func _ready():
	if not texture or not material or polygon.size() < 3 or not subViewport or not line2D:
		return

	var minPos : Vector2 = Vector2.INF
	var maxPos : Vector2 = -minPos
	for point in polygon:
		minPos = minPos.min(point)
		maxPos = maxPos.max(point)

	line2D.position = -minPos
	line2D.points = polygon

	var subviewportSize : Vector2 = maxPos - minPos
	if not subviewportSize.is_zero_approx():
		subViewport.set_size_2d_override(subviewportSize)
		subViewport.set_size_2d_override_stretch(true)

		material.set_shader_parameter("mask", subViewport.get_texture())
		material.set_shader_parameter("mask_offset", line2D.position / subviewportSize)
		material.set_shader_parameter("mask_scale", texture.get_size() / subviewportSize)
