shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float edge_softness : hint_range(0.0, 0.2) = 0.05;

void fragment() {
	float dist = abs(UV.y - 0.5);
	float half_width = mix(-edge_softness, 0.5 + edge_softness, progress);
	float mask = 1.0 - smoothstep(half_width - edge_softness, half_width + edge_softness, dist);
	COLOR = texture(TEXTURE, UV);
	COLOR.a *= mask;
}
