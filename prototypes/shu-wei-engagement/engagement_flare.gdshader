shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec4 tint : source_color = vec4(1.0);
uniform float energy = 1.0;

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float radius = length(p);
	float core = exp(-radius * radius * 45.0);
	float halo = exp(-radius * radius * 7.0);
	float streak = exp(-abs(p.y) * 55.0) * exp(-abs(p.x) * 4.0);
	ALBEDO = (mix(tint.rgb, vec3(1.0), core) * (core * 2.5 + halo * 0.28 + streak * 0.23)) * energy;
	ALPHA = 1.0 - smoothstep(0.72, 1.0, radius);
}
