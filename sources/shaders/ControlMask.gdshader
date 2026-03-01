shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 1.0;
uniform bool inverted = false;
uniform float edge_softness : hint_range(0.0, 0.2) = 0.05;

void fragment() {
	float oriented_uv = inverted ? 1.0 - UV.x : UV.x;
	float shifted = mix(-edge_softness, 1.0 + edge_softness, progress);
	float mask = 1.0 - smoothstep(shifted - edge_softness, shifted + edge_softness, oriented_uv);
	COLOR = texture(TEXTURE, UV);
	COLOR.a *= mask;
}
