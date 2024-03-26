shader_type canvas_item;

const float EPSILON = 0.0001;

uniform int palette_size : hint_range(1, 20) = 0;
uniform vec3 palette_in[20] : source_color;
uniform vec3 palette_out[20] : source_color;

void fragment()
{
	if (COLOR.a > 0.0)
	{
		for (int i = 0; i < palette_size; ++i)
		{
			vec3 diff = abs(COLOR.xyz - palette_in[i]);
			if (diff.x < EPSILON && diff.y < EPSILON && diff.z < EPSILON)
			{
				COLOR.xyz = palette_out[i].xyz;
				break;
			}
		}
	}
}