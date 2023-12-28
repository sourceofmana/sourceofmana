shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 1.0;
uniform bool inverted = false;

void fragment() {
	vec4 custom_color = texture(TEXTURE, UV);
	if (custom_color.a != 0.0)
	{
		// Convert UV coordinates to local coordinates within the TextureRect
		vec2 local_uv = vec2(mod(SCREEN_UV, 1.0));
		float oriented_UV = inverted ? 1.0 - local_uv.x : local_uv.x;
		if (progress == 0.0)
		{
			COLOR.a = 0.0;
		}
		else if (oriented_UV >= progress)
		{
			COLOR.a = custom_color.a * clamp(1.0 - (oriented_UV - progress) / progress, 0.0, 1.0);
		}
	}
}
