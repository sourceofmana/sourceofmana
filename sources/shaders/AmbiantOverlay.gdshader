shader_type canvas_item;

uniform vec2 direction = vec2(1.0, 0.0);
uniform float opacity = 0.2;
uniform vec2 perspective = vec2(1.0, 0.7);

void fragment()
{
    vec2 scaled_uv = (UV - 0.5) / perspective + 0.5;


	vec2 uv = scaled_uv - normalize(direction) * TIME;
	vec4 tex = texture(TEXTURE, uv);
	tex.a *= opacity;
	COLOR = tex;
}
