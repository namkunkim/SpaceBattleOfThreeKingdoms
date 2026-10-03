class_name Factions
extends RefCounted

# 세력 표시(리뷰 C-3). 진영은 색만으로 나누지 않는다.
# - 세력 글리프(인장 한자 + 기호 모양): 촉 = 蜀·사각, 위 = 魏·마름모, 오 = 吳·원
# - 소유 표시(지휘권): ● 플레이어가 직접 지휘 / ○ 동맹 세력(같은 편, 지휘 불가). 적에는 붙이지 않는다.
# 세력 키는 BattleSource.faction(id)에서 읽는다.

const INFO := {
	"shu": {"glyph": "蜀", "shape": "square", "name": "촉한", "deep": Color("0e3d39"), "mid": Color("2b8f84"), "rim": Color("7fe9dc"), "ink": Color("f4fffd"), "color": Color("5fe0cf")},
	"wei": {"glyph": "魏", "shape": "diamond", "name": "위", "deep": Color("4d140b"), "mid": Color("b8442a"), "rim": Color("ff9f80"), "ink": Color("fff0e8"), "color": Color("ff7550")},
	"wu": {"glyph": "吳", "shape": "circle", "name": "오", "deep": Color("2a1d4a"), "mid": Color("6a4fb0"), "rim": Color("c7b4ff"), "ink": Color("f6f0ff"), "color": Color("b9a2ff")},
}

static func of(key: String) -> Dictionary:
	return INFO.get(key, INFO.shu)

static func of_side(side: int) -> String:
	return "wei" if side == 1 else "shu"
