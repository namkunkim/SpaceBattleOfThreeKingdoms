shader_type spatial;
render_mode specular_schlick_ggx;

uniform vec4 base_color : source_color;
varying vec3 surface;

float noise3(vec3 p) {
	vec3 cell = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	vec4 s = vec4(0.0, 1.0, 57.0, 58.0) + dot(cell, vec3(1.0, 57.0, 113.0));
	vec4 a = fract(sin(s) * 43758.5453);
	vec4 b = fract(sin(s + 113.0) * 43758.5453);
	vec4 c = mix(a, b, f.z);
	return mix(mix(c.x, c.y, f.x), mix(c.z, c.w, f.x), f.y);
}

float terrain(vec3 p) {
	return noise3(p * 3.0) * 0.57 + noise3(p * 9.0) * 0.25 +
		noise3(p * 26.0) * 0.12 + noise3(p * 83.0) * 0.06;
}

void vertex() {
	surface = normalize(VERTEX);
}

void fragment() {
	vec3 p = normalize(surface);
	float relief = terrain(p + vec3(1.3, 2.7, 4.0));
	float bands = 0.5 + 0.5 * sin(p.y * 46.0 + relief * 8.0);
	float cloud = smoothstep(0.60, 0.76, terrain(p * 1.9 + vec3(TIME * 0.012, 5.0, 1.0)));
	vec3 dark_side = base_color.rgb * vec3(0.22, 0.32, 0.43);
	vec3 bright_side = base_color.rgb * (0.52 + relief * 1.05 + bands * 0.14);
	ALBEDO = mix(dark_side, bright_side, smoothstep(0.25, 0.70, relief));
	ALBEDO = mix(ALBEDO, vec3(0.64, 0.69, 0.72), cloud * 0.64);
	ROUGHNESS = mix(0.52, 0.92, relief);
	float rim = pow(1.0 - max(dot(normalize(NORMAL), normalize(VIEW)), 0.0), 5.0);
	EMISSION = base_color.rgb * rim * 0.14;
}
