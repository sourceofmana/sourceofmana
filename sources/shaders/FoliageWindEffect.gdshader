// MIT License

// Copyright (c) 2025 jess-hammer
// Original shader idea and pixelization effect comes from Jess Hammer
// https://github.com/jess-hammer/tree-and-foliage-wind-shader-godot

shader_type canvas_item;
render_mode blend_mix;

uniform sampler2D mask_texture : source_color, filter_nearest;
uniform float distortion : hint_range(0.0, 0.1) = 0.01;

uniform sampler2D noise_texture : source_color ,repeat_enable;
uniform float noise_speed = 1.0;
uniform int noise_direction : hint_range(-1, 1) = -1;

const float EPSILON = 0.0001;

vec2 get_pixelated_uvs(vec2 uv, vec2 texture_pixel_size)
{
	vec2 texture_dimensions = 1.0 / texture_pixel_size + EPSILON;
	vec2 pixel_coords = uv * texture_dimensions;
	vec2 snapped_pixel_coords = vec2(round(pixel_coords.x), round(pixel_coords.y));
	vec2 pixelated_uv = snapped_pixel_coords / texture_dimensions;
	return pixelated_uv;
}

void fragment()
{
	vec2 uv = (TEXTURE_PIXEL_SIZE.x != 1.0) ? get_pixelated_uvs(UV, TEXTURE_PIXEL_SIZE) : UV;
	vec4 uv_result = texture(noise_texture, uv + TIME * noise_speed * float(noise_direction));
	vec2 noise_uv = mix(uv, uv_result.rg, distortion);

	vec4 base = texture(TEXTURE, uv);
	vec4 noise = texture(TEXTURE, noise_uv);
	float blend = texture(mask_texture, noise_uv).a;

	COLOR = mix(base, noise, blend);
}
