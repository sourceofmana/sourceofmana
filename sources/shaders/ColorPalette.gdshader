shader_type canvas_item;

const float inc = 0.01;
uniform int num_colors : hint_range(1, 100) = 1;

uniform sampler2D palette_in;
uniform sampler2D palette_out;

void fragment()
{
	if (COLOR.a > 0.0)
	{
		vec2 uv;
		for (int i = 0; i < 128; ++i)
		{
			if (distance(COLOR.xyz, texture(palette_in, uv).xyz) < 0.01)
			{
				COLOR.xyz = vec3(uv.x,uv.x,uv.x);//texture(palette_out, uv).xyz;
				break;
			}
			uv.x += 0.001;
		}
	}
}