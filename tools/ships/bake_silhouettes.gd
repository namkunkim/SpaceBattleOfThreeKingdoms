extends SceneTree

# ver1 컨셉 PNG(투명 배경, 비스듬한 위쪽 시점)에서 함선 실루엣 텍스처를 만든다. 전투 화면은 이 텍스처를 읽는다(3D 모델 불필요).
#   godot --headless --path . --script tools/ships/bake_silhouettes.gd -- "C:/WorkSpace/Seonghanji/assets/ships/각 전함 컨셉 사진/ver1"
# 처리: 알파 > 0.5 픽셀의 주축(PCA)을 가로로 눕히고, 선수(양 끝 중 더 좁은 쪽)를 왼쪽으로 돌려, 512x128로 늘려 저장한다(RGBA, 알파 = 실루엣).
# 함종 순서는 FleetRenderer.CLASS_NAMES와 같다: 전열 화력 공성 보급 전자전 호위 항모.

const OUT_DIR := "res://assets/ships/silhouette/"
const W := 512
const H := 128
const SRC := ["전열함_1", "화력함", "공성함", "보급함", "전자전함", "고속_요격함", "강습항모"]

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var dir: String = args[0] if args.size() > 0 else "C:/WorkSpace/Seonghanji/assets/ships/각 전함 컨셉 사진/ver1"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	for k in SRC.size():
		var img := Image.load_from_file("%s/%s.png" % [dir, SRC[k]])
		if img == null:
			push_error("열 수 없음: " + SRC[k])
			continue
		img.convert(Image.FORMAT_RGBA8)
		var out := _bake(img)
		var path := ProjectSettings.globalize_path(OUT_DIR + "%d.png" % k)
		out.save_png(path)
		print("BAKE ", k, " ", SRC[k], " -> ", path)
	quit(0)

func _bake(img: Image) -> Image:
	var w := img.get_width()
	var h := img.get_height()
	var n := 0.0
	var c := Vector2.ZERO
	for y in range(0, h, 2):
		for x in range(0, w, 2):
			if img.get_pixel(x, y).a > 0.5:
				c += Vector2(x, y)
				n += 1.0
	c /= maxf(n, 1.0)
	var sxx := 0.0
	var sxy := 0.0
	var syy := 0.0
	for y in range(0, h, 2):
		for x in range(0, w, 2):
			if img.get_pixel(x, y).a > 0.5:
				var d := Vector2(x, y) - c
				sxx += d.x * d.x
				sxy += d.x * d.y
				syy += d.y * d.y
	var ang := 0.5 * atan2(2.0 * sxy, sxx - syy)
	var a := Vector2(cos(ang), sin(ang))
	var b := Vector2(-a.y, a.x)
	# 주축/수직축 범위와 양 끝 폭
	var amin := 1e9
	var amax := -1e9
	var pts := []
	for y in range(0, h, 2):
		for x in range(0, w, 2):
			if img.get_pixel(x, y).a > 0.5:
				var d := Vector2(x, y) - c
				var pa := d.dot(a)
				pts.append(Vector2(pa, d.dot(b)))
				amin = minf(amin, pa)
				amax = maxf(amax, pa)
	var bmin := 1e9
	var bmax := -1e9
	var span := amax - amin
	var lo_min := 1e9
	var lo_max := -1e9
	var hi_min := 1e9
	var hi_max := -1e9
	for p in pts:
		bmin = minf(bmin, p.y)
		bmax = maxf(bmax, p.y)
		if p.x < amin + span * 0.2:
			lo_min = minf(lo_min, p.y)
			lo_max = maxf(lo_max, p.y)
		elif p.x > amax - span * 0.2:
			hi_min = minf(hi_min, p.y)
			hi_max = maxf(hi_max, p.y)
	# 선수 = 더 좁은 끝. 높은 쪽(+a)이 좁으면 a를 뒤집어 선수를 u=0으로 보낸다.
	var flip := (hi_max - hi_min) < (lo_max - lo_min)
	var out := Image.create(W, H, false, Image.FORMAT_RGBA8)
	for j in H:
		for i in W:
			var u := (i + 0.5) / W
			var v := (j + 0.5) / H
			var pa := lerpf(amin, amax, (1.0 - u) if flip else u)
			var pb := lerpf(bmin, bmax, v)
			var src := c + a * pa + b * pb
			out.set_pixel(i, j, _sample(img, src))
	return out

func _sample(img: Image, p: Vector2) -> Color:
	var x0 := floori(p.x - 0.5)
	var y0 := floori(p.y - 0.5)
	var fx := p.x - 0.5 - x0
	var fy := p.y - 0.5 - y0
	var acc := Color(0, 0, 0, 0)
	for dy in 2:
		for dx in 2:
			var x := x0 + dx
			var y := y0 + dy
			if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
				continue
			var wgt := (fx if dx == 1 else 1.0 - fx) * (fy if dy == 1 else 1.0 - fy)
			var col := img.get_pixel(x, y)
			acc += Color(col.r * col.a, col.g * col.a, col.b * col.a, col.a) * wgt
	if acc.a < 0.001:
		return Color(0, 0, 0, 0)
	return Color(acc.r / acc.a, acc.g / acc.a, acc.b / acc.a, acc.a)
