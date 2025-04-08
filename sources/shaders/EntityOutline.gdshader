shader_type canvas_item;

uniform vec3 outline_color : source_color = vec3(1.0, 0.0, 0.0); // Red
uniform float blink_speed : hint_range(0, 10) = 1.0;

const vec2 OFFSETS[8] = {
	vec2(-1, -1), vec2(-1, 0), vec2(-1, 1), vec2(0, -1), vec2(0, 1),
	vec2(1, -1), vec2(1, 0), vec2(1, 1)
};
void vertex() {
    // Nothing here for 2D sprite
}

void fragment() {
	if (COLOR.r < 0.01 && COLOR.g < 0.01 && COLOR.b < 0.01)
	{
		float sintime = sin(TIME * blink_speed);

	    // Output the final color
	    COLOR.rgb = mix(COLOR.rgb, outline_color, 0.5 + 0.5 * sintime);
	}
}
