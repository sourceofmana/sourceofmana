// Author: ACB_Gamez
// Source: https://godotshaders.com/author/acb_gamez/
// License: CC-0
shader_type canvas_item;

uniform vec4 shine_color : source_color = vec4(1.0);
uniform float shine_duration : hint_range(0.1, 10.0, 0.1) = 2.0; // In seconds
uniform float shine_size : hint_range(0.01, 1.0, 0.01) = 0.1;
uniform float shine_angle : hint_range(0.0, 89.9, 0.1) = 45.0;
uniform float start_time : hint_range(0.0, 100.0, 0.1) = -1.0;
uniform vec4 modulate : source_color = vec4(1.0);

float scale(float value, float inMin, float inMax, float outMin, float outMax)
{
	return (value - inMin) * (outMax - outMin) / (inMax - inMin) + outMin;
}

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	float slope = tan(radians(shine_angle));
	float shine_size_scaled = shine_size * (1.0 + slope);

	float elapsed_time = TIME - start_time;
	float time_progress = clamp(elapsed_time / shine_duration, 0.0, 1.0);

	vec4 final_color;
	if (start_time < 0.0 || elapsed_time > shine_duration)
	{
		final_color = tex_color;
	}
	else
	{
		float progress = scale(time_progress, 0.0, 1.0, -1.0 - shine_size_scaled, 1.0 + shine_size_scaled);
		float shine_line = slope * UV.x - UV.y;
		float shine = step(shine_line, progress + shine_size_scaled) - step(shine_line, progress);
		final_color = vec4(mix(tex_color.rgb, shine_color.rgb, shine * shine_color.a), tex_color.a);
	}

	COLOR = final_color * modulate;
}
