shader_type canvas_item;

uniform sampler2D piece_tex : filter_linear;
uniform float dissolve : hint_range(0.0, 1.0) = 0.0;
uniform float edge_softness : hint_range(0.0, 0.25) = 0.1;
uniform vec4 edge_color : source_color = vec4(1.0, 0.55, 0.15, 1.0);

float hash21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec4 tex = texture(piece_tex, UV);
	float n = hash21(UV * 14.0);
	float threshold = dissolve * 1.12;
	float alpha = smoothstep(threshold, threshold - edge_softness, n) * tex.a;
	vec3 col = tex.rgb;
	float edge = smoothstep(threshold - edge_softness * 2.5, threshold - edge_softness, n);
	col = mix(col, edge_color.rgb, edge * (1.0 - dissolve * 0.35));
	COLOR = vec4(col, alpha);
}
