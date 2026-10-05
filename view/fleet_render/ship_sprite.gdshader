shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_draw_opaque;

// 3D 모델 없이 그리는 함선 실루엣(참고 영상 방식): 어두운 선체 + 가장자리의 밝은 테두리 + 중심선 하이라이트.
// 함종마다 실루엣이 다르다(kind): 0 전열 1 화력 2 공성 3 보급·수리 4 전자전 5 호위 6 항모.
// 바닥에 눕힌 평면(PlaneMesh) 위에서 UV.x = 길이(0 = 선수, 1 = 선미), UV.y = 폭.
uniform vec3 hull_color : source_color = vec3(0.09, 0.12, 0.17);
uniform vec3 rim_color : source_color = vec3(0.62, 0.9, 1.0);
uniform float fat = 1.0;   // 폭 배율 미세 조정(0.5~1.0)
uniform int kind = 0;
uniform sampler2D ship_tex : source_color, filter_linear;   // 컨셉 PNG에서 구운 실루엣(RGBA, 알파 = 모양). tools/ships/bake_silhouettes.gd
uniform bool use_tex = false;                                 // false면 아래 kind별 수식 실루엣(대체)
uniform float detail : hint_range(0.0, 1.0) = 0.0;   // 확대할수록 1: 판 이음선, 안쪽 윤곽, 함교 창, 엔진 노즐, 포탑 고리가 나타난다

varying vec4 inst;
varying float spd;   // 함선별 속도 0~1(INSTANCE_CUSTOM.x): 선미 항적의 세기
const float PLANE_K = 1.6;   // 평면 길이 / 선체 길이. 선체가 앞 1/1.6, 나머지 뒤쪽이 항적 자리

void vertex() {
	inst = COLOR;
	spd = INSTANCE_CUSTOM.x;
}

float bump(float p, float c, float w) {
	float x = (p - c) / w;
	return exp(-x * x);
}

float nose(float p, float pw) {
	return pow(clamp(p + 1.0, 0.0, 1.0), pw);
}

// p: -1(선수) ~ +1(선미). 반폭 0~1을 돌려준다.
float hull(int k, float p) {
	if (k == 0) {        // 전열함: 굵은 창끝 + 선미 함교
		float b = p < 0.0 ? nose(p, 0.65) : 1.0 - 0.3 * p;
		return min(1.0, 0.8 * b + 0.2 * bump(p, 0.45, 0.14));
	} else if (k == 1) { // 화력함: 가는 선체 + 양옆 포탑 돌기 두 쌍
		float b = p < 0.0 ? nose(p, 0.8) : 1.0 - 0.45 * p;
		return min(1.0, 0.42 * b + 0.5 * (bump(p, -0.42, 0.11) + bump(p, 0.02, 0.11)) * step(-0.9, p));
	} else if (k == 2) { // 공성함: 뭉툭한 블록 + 선수 포신
		if (p < -0.55) { return 0.14; }
		if (p < -0.35) { return mix(0.14, 0.95, smoothstep(-0.55, -0.35, p)); }
		return p > 0.88 ? 0.95 * (1.0 - smoothstep(0.88, 1.0, p)) : 0.95;
	} else if (k == 3) { // 보급·수리함: 둥근 화물 상자
		return 0.72 * sqrt(clamp(1.0 - pow(abs(p), 6.0), 0.0, 1.0));
	} else if (k == 4) { // 전자전함: 가는 몸체 + 뒤로 젖힌 삼각 날개
		float body = 0.2 * (p < 0.0 ? nose(p, 0.7) : 1.0);
		float wing = (p > -0.25 && p < 0.96) ? clamp(p + 0.25, 0.0, 1.0) * 0.95 : 0.0;
		return max(body, wing);
	} else if (k == 5) { // 호위함: 작고 날카로운 화살촉
		return p < 0.0 ? 0.85 * nose(p, 0.9) : 0.85 * (1.0 - 0.8 * p);
	}
	// 항모: 평행한 넓은 갑판 + 둥근 선수
	return p < -0.72 ? 0.92 * pow(clamp((p + 1.0) / 0.28, 0.0, 1.0), 0.5) : 0.92;
}

void fragment() {
	vec2 suv = vec2(UV.x * PLANE_K, UV.y);
	if (suv.x > 1.0) {   // 선미 항적: 가늘고 밝은 선이 뒤로 갈수록 옅어진다
		float tl = (suv.x - 1.0) / (PLANE_K - 1.0);
		float w = 0.3 * (1.0 - tl) + 0.02;
		float a = (1.0 - smoothstep(w * 0.4, w, abs(suv.y * 2.0 - 1.0))) * pow(1.0 - tl, 1.6) * spd;
		if (a < 0.02) {
			discard;
		}
		ALBEDO = rim_color * 1.3 * inst.rgb;
		ALPHA = a;
	} else if (use_tex) {
		vec4 t = texture(ship_tex, suv);
		float m = t.a;
		if (m < 0.04) {
			discard;
		}
		// 알파를 흐려 바깥쪽 가장자리만 남긴다 -> 밝은 테두리
		vec2 r = vec2(7.0 / 512.0, 7.0 / 128.0);
		float blur = 0.0;
		blur += texture(ship_tex, suv + vec2(r.x, 0.0)).a + texture(ship_tex, suv - vec2(r.x, 0.0)).a;
		blur += texture(ship_tex, suv + vec2(0.0, r.y)).a + texture(ship_tex, suv - vec2(0.0, r.y)).a;
		blur += texture(ship_tex, suv + r * 0.7).a + texture(ship_tex, suv - r * 0.7).a;
		blur += texture(ship_tex, suv + vec2(r.x, -r.y) * 0.7).a + texture(ship_tex, suv + vec2(-r.x, r.y) * 0.7).a;
		blur /= 8.0;
		float edge = clamp(m * (1.0 - blur) * 2.4, 0.0, 1.0) * (suv.y < 0.5 ? 1.0 : 0.6);
		float tex_amt = 0.3 + 0.7 * detail;   // 멀리서는 어두운 실루엣, 확대할수록 선체 무늬가 드러난다
		vec3 body = mix(hull_color, t.rgb * 0.9, tex_amt);
		vec3 c2 = mix(body, rim_color, edge) + rim_color * 0.25 * smoothstep(0.1, 0.0, abs(suv.y - 0.5)) * m * (1.0 - tex_amt);
		ALBEDO = c2 * inst.rgb;
		ALPHA = smoothstep(0.04, 0.5, m);
	} else {
	float p = suv.x * 2.0 - 1.0;
	float q = (suv.y * 2.0 - 1.0) / fat;
	float h = hull(kind, p);
	// 항모 선미 격납고 홈
	if (kind == 6 && p > 0.82 && abs(q) < 0.24) {
		discard;
	}
	float d = abs(q) - h;
	float aa = fwidth(q) * 1.5 + 0.002;
	float alpha = 1.0 - smoothstep(-aa, aa, d);
	if (alpha < 0.02) {
		discard;
	}
	float edge = smoothstep(-0.45, -0.05, d) * (q < 0.0 ? 1.0 : 0.55);
	float spine = (1.0 - smoothstep(0.0, 0.14, abs(q))) * 0.3 * step(-0.55, p);
	vec3 col = mix(hull_color, rim_color, edge) + rim_color * spine;
	if (kind == 3) {   // 화물 칸막이: 일정 간격의 어두운 띠
		col *= 1.0 - 0.45 * smoothstep(0.82, 0.95, abs(fract(p * 2.5) * 2.0 - 1.0));
	} else if (kind == 6) {   // 활주로 점선
		col += rim_color * 0.35 * step(0.5, fract(p * 6.0)) * (1.0 - smoothstep(0.0, 0.1, abs(q)));
	}
	if (detail > 0.0) {
		// 월드 길이 환산: p 한 단위 = 0.95, q 한 단위 = 0.24 (평면 1.9 x 0.48)
		float panel = smoothstep(0.44, 0.5, abs(fract(p * 7.0) - 0.5));
		col += rim_color * 0.1 * panel * detail * (1.0 - edge);
		col += rim_color * 0.3 * smoothstep(0.05, 0.0, abs(d + 0.34)) * detail;
		float win = step(0.5, fract(p * 16.0)) * (1.0 - smoothstep(0.03, 0.09, abs(q))) * step(0.22, p) * step(p, 0.62);
		col += vec3(1.0, 0.88, 0.55) * win * detail * (kind == 4 || kind == 5 ? 0.0 : 0.85);
		float noz = step(0.92, p) * (1.0 - smoothstep(0.06, 0.14, abs(abs(q) - 0.34)));
		col += rim_color * 1.4 * noz * detail * alpha;
		if (kind == 1) {   // 화력함 포탑 고리
			for (int i = 0; i < 2; i++) {
				float c = i == 0 ? -0.42 : 0.02;
				float r = length(vec2((p - c) * 0.95, (abs(q) - 0.5) * 0.24));
				col += rim_color * 0.7 * smoothstep(0.012, 0.0, abs(r - 0.045)) * detail;
				col *= 1.0 - 0.35 * detail * step(r, 0.04);
			}
		}
	}
	ALBEDO = col * inst.rgb;
	ALPHA = alpha;
	}
}
