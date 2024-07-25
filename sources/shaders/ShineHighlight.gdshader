// Author: ACB_Gamez
// Source: https://godotshaders.com/author/acb_gamez/
// License: CC-0
shader_type canvas_item;

uniform vec4 shine_color : source_color = vec4(1.0);
uniform float shine_size : hint_range(0.01, 1.0, 0.01) = 0.1;
uniform float shine_angle : hint_range(0.0, 89.9, 0.1) = 45.0;
uniform float progress : hint_range(0.0, 1.0, 0.001) = -1.0;
uniform vec4 modulate : source_color = vec4(1.0);

float scale(float value, float inMin, float inMax, float outMin, float outMax)
{
	return (value - inMin) * (outMax - outMin) / (inMax - inMin) + outMin;
}

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);

	vec4 final_color;
	if (progress < 0.0)
	{
		final_color = tex_color;
	}
	else
	{
		float slope = tan(radians(shine_angle));
		float shine_size_scaled = shine_size * (1.0 + slope);
		float scaled_progress = scale(progress, 0.0, 1.0, -1.0 - shine_size_scaled, 1.0 + shine_size_scaled);
		float shine_line = slope * UV.x - UV.y;
		float shine = step(shine_line, scaled_progress + shine_size_scaled) - step(shine_line, scaled_progress);
		final_color = vec4(mix(tex_color.rgb, shine_color.rgb, shine * shine_color.a), tex_color.a);
	}

	COLOR = final_color * modulate;
}
