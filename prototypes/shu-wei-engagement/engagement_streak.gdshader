shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, shadows_disabled;

uniform vec4 tint : source_color = vec4(1.0);
uniform float energy = 1.0;

void fragment() {
	float cross_section = pow(max(dot(normalize(NORMAL), normalize(VIEW)), 0.0), 1.5);
	ALBEDO = tint.rgb * energy;
	ALPHA = cross_section;
}