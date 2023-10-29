shader_type canvas_item;

// [0 ; UV.x + 0.2]
uniform float progress : hint_range(0.0,1.2) = 0.0;
uniform bool inverted = false;

void fragment() {
	vec4 custom_color = texture(TEXTURE, UV);
	if (custom_color.a != 0.0)
	{
		float offset_progress = max(0, progress - 0.2);
		float oriented_UV = inverted ? 1.0 - UV.x : UV.x;
		if (offset_progress == 0.0)
		{
			COLOR.a = 0.0;
		}
		else if (oriented_UV >= offset_progress)
		{
			COLOR.a = custom_color.a * clamp(1.0 - (oriented_UV - offset_progress) / offset_progress, 0.0, 1.0);
		}
	}
}