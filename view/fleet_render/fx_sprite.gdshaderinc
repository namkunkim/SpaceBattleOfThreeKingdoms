// 전투 연출용 스프라이트 공용 코드. MultiMesh 인스턴스 하나가 사각형 하나다.
// INSTANCE_CUSTOM = (kind, age 0..1, seed, alpha)
// kind: 0 부드러운 발광, 1 화구, 2 충격파 고리(전장 평면), 3 방어막 섬광, 4 십자 섬광, 5 연기, 6 불씨
// 인스턴스 변환의 원점 = 중심, basis.x 길이 = 크기. 고리(2)는 전장 평면에 눕히고 나머지는 카메라를 본다.

varying vec4 v_custom;
varying vec4 v_color;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}
float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * noise(p);
		p *= 2.03;
		a *= 0.5;
	}
	return v;
}

void vertex() {
	v_custom = INSTANCE_CUSTOM;
	v_color = COLOR;
	vec3 center = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	float size = length(MODEL_MATRIX[0].xyz);
	vec3 world;
	if (int(INSTANCE_CUSTOM.x + 0.5) == 2) {
		world = center + vec3(VERTEX.x, 0.0, VERTEX.y) * size;
	} else {
		world = center + (INV_VIEW_MATRIX[0].xyz * VERTEX.x + INV_VIEW_MATRIX[1].xyz * VERTEX.y) * size;
	}
	VERTEX = (VIEW_MATRIX * vec4(world, 1.0)).xyz;
}

vec4 sprite(vec2 uv) {
	int kind = int(v_custom.x + 0.5);
	float age = v_custom.y;
	float sd = v_custom.z;
	vec2 p = uv * 2.0 - 1.0;
	float r = length(p);
	vec3 col = v_color.rgb;
	float a = 0.0;
	if (kind == 0) {
		a = exp(-r * r * 9.0) * 1.2 + exp(-r * r * 2.5) * 0.25;
		col = mix(col, vec3(1.0), exp(-r * r * 40.0));
	} else if (kind == 1) {
		float n = fbm(p * 2.6 + vec2(sd * 17.0, age * 1.7));
		float edge = 0.55 + 0.45 * age;
		float body = smoothstep(edge, edge - 0.45, r + (n - 0.5) * 0.55);
		float hot = smoothstep(0.55, 0.0, r + age * 0.4);
		col = mix(vec3(0.75, 0.16, 0.03), vec3(1.0, 0.62, 0.22), n);
		col = mix(col, vec3(1.0, 0.96, 0.85), hot);
		a = body * (1.0 - age) * (1.0 - age) * 1.4;
	} else if (kind == 2) {
		float rr = 0.15 + age * 0.85;
		a = smoothstep(0.06, 0.0, abs(r - rr)) * (1.0 - age) * 0.9;
		a += smoothstep(rr, 0.0, r) * 0.08 * (1.0 - age);
	} else if (kind == 3) {
		float rim = smoothstep(0.22, 0.0, abs(r - 0.72 - age * 0.15));
		float hex = 0.0;
		vec2 h = p * 5.0;
		h.x *= 1.1547;
		h.y += mod(floor(h.x), 2.0) * 0.5;
		vec2 f = abs(fract(h) - 0.5);
		hex = smoothstep(0.42, 0.5, max(f.x * 1.5 + f.y, f.y * 2.0));
		a = (rim * 0.9 + hex * rim * 0.6 + exp(-r * r * 6.0) * 0.7) * (1.0 - age);
		col = mix(col, vec3(1.0), exp(-r * r * 12.0));
	} else if (kind == 4) {
		float core = exp(-r * r * 30.0);
		float spike = exp(-abs(p.y) * 60.0) * (1.0 - abs(p.x)) + exp(-abs(p.x) * 60.0) * (1.0 - abs(p.y)) * 0.7;
		a = (core * 1.4 + spike * 0.8) * (1.0 - age);
		col = mix(col, vec3(1.0), core);
	} else if (kind == 5) {
		float n = fbm(p * 2.0 + vec2(sd * 9.0, 0.0));
		a = smoothstep(1.0, 0.2, r + (n - 0.5) * 0.6) * (1.0 - age) * 0.5;
	} else {
		a = exp(-r * r * 14.0) * (1.0 - age);
		col = mix(col, vec3(1.0, 0.95, 0.8), 0.4);
	}
	return vec4(col, clamp(a * v_custom.w, 0.0, 4.0));
}
