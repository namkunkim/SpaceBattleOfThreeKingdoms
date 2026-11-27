shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, shadows_disabled;

uniform vec4 tint : source_color = vec4(1.0);
uniform float energy = 1.0;
uniform vec4 lead_clearance = vec4(0.0);

void fragment() {
	float cross_section = pow(max(dot(normalize(NORMAL), normalize(VIEW)), 0.0), 1.5);
	ALBEDO = tint.rgb * energy;
	float open = 1.0;
	if (lead_clearance.z > 0.001) {
		vec2 offset = (SCREEN_UV - lead_clearance.xy) / lead_clearance.zw;
		open = smoothstep(0.74, 1.22, length(offset));
	}
	ALPHA = cross_section * open;
}