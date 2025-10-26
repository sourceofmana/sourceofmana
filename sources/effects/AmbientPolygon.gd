extends Polygon2D

@onready var subViewport : SubViewport = $SubViewport
@onready var line2D : Line2D = $SubViewport/Line2D

#
func _ready():
	if line2D and texture and subViewport and not polygon.is_empty():
		var minPos : Vector2 = Vector2.INF
		var maxPos : Vector2 = -minPos
		for point in polygon:
			minPos = minPos.min(point)
			maxPos = maxPos.max(point)

		line2D.position = -minPos
		line2D.points = polygon

		var textureSize : Vector2 = texture.get_size()
		var subviewportSize : Vector2 = maxPos - minPos
		if not subviewportSize.is_zero_approx():
			subViewport.set_size(subviewportSize)
			material.set_shader_parameter("mask_offset", line2D.position / subviewportSize)
			material.set_shader_parameter("mask_scale", textureSize / subviewportSize)
			set_visible(true)
