shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec4 haze_color : source_color = vec4(0.24, 0.29, 0.41, 0.1);
uniform float seed = 0.0;

float grain(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f *= f * (3.0 - 2.0 * f);
	vec4 s = vec4(0.0, 1.0, 57.0, 58.0) + dot(i, vec2(1.0, 57.0)) + seed;
	vec4 h = fract(sin(s) * 43758.5453);
	return mix(mix(h.x, h.y, f.x), mix(h.z, h.w, f.x), f.y);
}

void fragment() {
	vec2 p = (UV - 0.5) * vec2(2.0, 2.0);
	float veil = 1.0 - smoothstep(0.18, 1.0, length(p));
	float broad = grain(UV * vec2(6.0, 11.0));
	float detail = grain(UV * 25.0);
	float density = smoothstep(0.30, 0.82, broad * 0.82 + detail * 0.18);
	ALBEDO = haze_color.rgb * (0.54 + detail * 0.38);
	ALPHA = veil * density * haze_color.a;
}
