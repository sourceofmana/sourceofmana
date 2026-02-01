shader_type canvas_item;
render_mode unshaded;

uniform mat4 global_transform;
uniform int n_lights = 0;
uniform vec4 dark_color : source_color = vec4(0.1, 0.08, 0.15, 1.0);
uniform vec4 default_light_color : source_color;
uniform float light_level : hint_range(0.0, 1.0) = 0.0;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float steps = 7.0;
varying vec2 world_position;

#define MAX_LIGHTS 64
uniform vec4 light_data[MAX_LIGHTS];
uniform vec4 color_data[MAX_LIGHTS];

void vertex()
{
	world_position = (global_transform * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment()
{
	vec2 frag_position = floor(world_position);
	float m_value = 1.0; // 1.0 == dark, 0.0 == light
	vec4 light_color = default_light_color;

	for (int i = 0; i < n_lights; ++i)
	{
		vec4 light_instance = light_data[i];
		vec2 normalized_position = light_instance.xy - frag_position;
		normalized_position.y *= 1.3;
		float squared_dist = dot(normalized_position, normalized_position);
		float squared_radius = light_instance.w * light_instance.w;
		if (squared_dist < squared_radius)
		{
			float dist = squared_dist / squared_radius;
			float value = dist < light_instance.z
				? 0.0
				: 1.0 / light_instance.z * (dist - light_instance.z);
			if (value < m_value)
			{
				vec4 new_color = color_data[i];
				light_color.rgb = mix(light_color.rgb, new_color.rgb, m_value);
				light_color.a = max(light_color.r, new_color.r);
			}

			m_value *= value;
			if (m_value <= 0.0)
				break;
		}
	}

    m_value = clamp(m_value, 0.0, 1.0);
    m_value = floor(m_value * steps + 0.5) / steps;

	light_color.rgb = mix(light_color.rgb, dark_color.rgb, max(-0.2, (m_value - 0.5) / 0.5));

	vec4 ambient_color = mix(light_color, dark_color, m_value);
	ambient_color.a *= 1.0 - light_level;
	vec4 screen_color = texture(SCREEN_TEXTURE, SCREEN_UV);

	COLOR = screen_color * ambient_color;
}
