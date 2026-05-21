shader_type canvas_item;

uniform vec4 base_color : source_color = vec4(0.722, 0.424, 0.769, 1.0);
// 0 = normal, 1 = rainbow (prism), 2 = gold (coin), 3 = ember, 4 = crystal (shard)
uniform int style = 0;

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;
	float dist = length(uv);
	if (dist > 1.02) {
		COLOR = vec4(0.0);
	} else {
		vec3 col = base_color.rgb;
		float outline = smoothstep(0.88, 0.98, dist);
		col = mix(col, col * 0.68, outline);

		if (style == 1) {
			float hue = atan(uv.y, uv.x) / 6.28318 + 0.5 + TIME * 0.15;
			vec3 ring = vec3(
				sin(hue * 6.28318) * 0.5 + 0.5,
				sin(hue * 6.28318 + 2.094) * 0.5 + 0.5,
				sin(hue * 6.28318 + 4.188) * 0.5 + 0.5
			);
			float ring_mask = smoothstep(0.72, 0.92, dist) * (1.0 - smoothstep(0.98, 1.02, dist));
			col = mix(col, ring, ring_mask * 0.85);
		} else if (style == 2) {
			vec3 gold = vec3(1.0, 0.82, 0.18);
			float ring = smoothstep(0.55, 0.95, dist) * (1.0 - smoothstep(0.95, 1.0, dist));
			col = mix(col, gold, ring * 0.75);
			float cross = max(1.0 - abs(uv.x) * 3.5, 1.0 - abs(uv.y) * 3.5);
			cross = smoothstep(0.55, 0.95, cross) * smoothstep(0.95, 1.0, dist);
			col = mix(col, gold, cross * 0.5);
		} else if (style == 3) {
			vec3 glow = vec3(1.0, 0.42, 0.08);
			float core = 1.0 - smoothstep(0.0, 0.45, dist);
			col = mix(col, glow, core * 0.85);
			float spike = abs(cos(atan(uv.y, uv.x) * 2.0));
			spike = smoothstep(0.35, 0.95, spike) * smoothstep(0.55, 1.0, dist);
			col = mix(col, glow, spike * 0.35);
		} else if (style == 4) {
			vec3 crystal = vec3(0.78, 0.92, 1.0);
			float crack = abs(sin(uv.x * 8.0 + uv.y * 6.0)) * abs(cos(uv.y * 7.0 - uv.x * 5.0));
			crack = smoothstep(0.55, 0.95, crack) * smoothstep(0.0, 0.92, dist);
			col = mix(col, crystal, crack * 0.55);
			float ring = smoothstep(0.78, 0.95, dist) * (1.0 - smoothstep(0.95, 1.02, dist));
			col = mix(col, crystal, ring * 0.45);
		}

		float alpha = 1.0 - smoothstep(0.98, 1.02, dist);
		COLOR = vec4(col, alpha);
	}
}
