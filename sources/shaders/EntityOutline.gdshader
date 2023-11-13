shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(1.0, 0.0, 0.0, 1.0); // Red
uniform float blink_speed : hint_range(0, 10) = 1.0;

const vec2 OFFSETS[8] = {
	vec2(-1, -1), vec2(-1, 0), vec2(-1, 1), vec2(0, -1), vec2(0, 1), 
	vec2(1, -1), vec2(1, 0), vec2(1, 1)
};
void vertex() {
    // Nothing here for 2D sprite
}

void fragment() {
	float outline = 0.0;
	
	for (int i = 0; i < OFFSETS.length(); i++) {
		outline += texture(TEXTURE, UV + TEXTURE_PIXEL_SIZE * OFFSETS[i]).a;
	}

	if (outline >= 2.0)
	{
		outline = min(outline, 1.0);
		vec4 color = texture(TEXTURE, UV);

		float sintime = sin(TIME * blink_speed);

		vec4 interpolated_color = outline_color;
		interpolated_color.a = 0.5 + 0.5 * sintime;

	    // Output the final color
	    COLOR = mix(color, interpolated_color, outline - color.a);
	}
}
