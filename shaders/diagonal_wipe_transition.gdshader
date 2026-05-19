shader_type canvas_item;

// Diagonal wipe aligned with cozy stripe backgrounds (scrolling_line_background.gdshader).
uniform vec4 wipe_color : source_color = vec4(0.949, 0.922, 0.878, 1.0);
uniform vec4 wipe_color_alt : source_color = vec4(0.91, 0.88, 0.83, 1.0);
// 0 = fully revealed, 1 = fully covered (swap scene at 1.0).
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float angle = 20.0;
uniform float line_count = 10.0;
uniform float edge_softness : hint_range(0.0, 0.08) = 0.02;

vec2 rotate_uv(vec2 uv, float rotation_angle) {
	float r = radians(rotation_angle);
	float c = cos(r);
	float s = sin(r);
	return uv * mat2(vec2(c, -s), vec2(s, c));
}

void fragment() {
	vec2 uv = UV;
	float aspect = TEXTURE_PIXEL_SIZE.x / TEXTURE_PIXEL_SIZE.y;
	uv.x *= aspect;

	float r = radians(angle);
	float c = cos(r);
	float s = sin(r);
	// Wipe-axis bounds over the full rect (all four corners) so progress 1 covers every pixel.
	float x0 = 0.0 * c - 0.0 * s;
	float x1 = aspect * c - 0.0 * s;
	float x2 = 0.0 * c - 1.0 * s;
	float x3 = aspect * c - 1.0 * s;
	float wipe_min = min(min(x0, x1), min(x2, x3));
	float wipe_max = max(max(x0, x1), max(x2, x3));
	float padding = edge_softness * 2.0;

	vec2 ruv = rotate_uv(uv, angle);
	float wipe_axis = ruv.x;
	float edge = mix(wipe_min - padding, wipe_max + padding, progress);
	float cover = 1.0 - smoothstep(edge - edge_softness, edge + edge_softness, wipe_axis);

	float band = cos(ruv.y * line_count * 0.5);
	float band_t = step(0.0, band);
	vec3 fill = mix(wipe_color_alt.rgb, wipe_color.rgb, band_t);

	COLOR = vec4(fill, cover * wipe_color.a);
}
