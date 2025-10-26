shader_type canvas_item;

uniform sampler2D color_ramp;
uniform sampler2D mask;
uniform vec2 direction = vec2(1.0, 0.0);
uniform vec2 perspective = vec2(1.0, 0.7);
uniform float opacity = 0.2;
uniform float transformative = 0.8;
uniform vec2 mask_offset = vec2(1.0, 1.0);
uniform vec2 mask_scale = vec2(1.0, 1.0);

const vec2 VEC2_MIN_EPSILON = vec2(-0.01, -0.01);

void fragment()
{
	vec2 normalized_direction = normalize(direction) * TIME;
	vec2 scaled_uv = UV / perspective;
	vec2 uv = scaled_uv - normalized_direction;
	vec4 tex = texture(TEXTURE, uv);

	vec2 uv_noise = scaled_uv* transformative - normalized_direction;
	vec4 tex_noise = texture(TEXTURE, uv_noise);

	float mask_alpha = texture(mask, mask_offset + UV * mask_scale).a;

	float luminence = (tex * tex_noise).r * (1.0f - mask_alpha) * 2.0;
	vec4 ramp_color = texture(color_ramp, vec2(luminence, 0.5));
	ramp_color.a *= opacity;

	COLOR = ramp_color;
}
