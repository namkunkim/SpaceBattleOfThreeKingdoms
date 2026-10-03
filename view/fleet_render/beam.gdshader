shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, skip_vertex_transform, shadows_disabled;

// 광선 한 줄 = 인스턴스 하나. 원점 = 발사 지점 A, basis.x = A→B 벡터.
// INSTANCE_CUSTOM = (폭, 머리 위치 0..1, 꼬리 위치 0..1, 세기)
// 사각형을 화면 쪽으로 세워 그리므로 어느 각도에서도 두께가 같다.

varying float v_len_t;
varying float v_side;
varying vec4 v_col;
varying float v_int;

void vertex() {
	vec3 a = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	vec3 ab = MODEL_MATRIX[0].xyz;
	float head = INSTANCE_CUSTOM.y;
	float tail = INSTANCE_CUSTOM.z;
	float u = VERTEX.x + 0.5;
	float t = mix(tail, head, u);
	vec3 pv = (VIEW_MATRIX * vec4(a + ab * t, 1.0)).xyz;
	vec3 dv = (VIEW_MATRIX * vec4(ab, 0.0)).xyz;
	vec2 side = normalize(vec2(-dv.y, dv.x) + vec2(1e-5, 0.0));
	// 원근에서 멀어도 최소 두께를 유지한다.
	float w = INSTANCE_CUSTOM.x * max(1.0, -pv.z * 0.012);
	pv.xy += side * VERTEX.y * 2.0 * w;
	VERTEX = pv;
	v_len_t = u;
	v_side = UV.y * 2.0 - 1.0;
	v_col = COLOR;
	v_int = INSTANCE_CUSTOM.w;
}

void fragment() {
	float s = abs(v_side);
	float core = exp(-s * s * 60.0);
	float halo = exp(-s * s * 5.0) * 0.35;
	float along = mix(0.35, 1.0, smoothstep(0.0, 0.9, v_len_t));
	vec3 col = v_col.rgb * (halo + core * 0.8) + vec3(1.0) * core * 0.9;
	ALBEDO = col * along * v_int;
	ALPHA = 1.0;
}
