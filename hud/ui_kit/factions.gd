class_name Factions
extends RefCounted

# 세력 표시(리뷰 C-3). 진영은 색만으로 나누지 않는다.
# - 세력 글리프(인장 한자 + 기호 모양): 촉 = 蜀·사각, 위 = 魏·마름모, 오 = 吳·원
# - 지휘 상태 표시는 세력과 별개다: ● 직접 지휘 / ○ 위임(Q20). BattleSource.command_mode(id).
# 세력 키는 BattleSource.faction(id)에서 읽는다.
# 이름(NARRATIVE-RED-CLIFFS §11.3): 적벽(208)은 촉한(221)·위(220) 건국 전이라 표시 이름은 군주 이름 + 군으로 둔다.
# 키(shu/wei/wu)는 본편 세력 ID·ScenarioRoster.FACTION_KEY와 엮여 있어 그대로 둔다. 인장 글리프(蜀·魏·吳)는
# 세력 구분 표지(리뷰 C-3)라 바꾸지 않는다. 바꾸려면 컨셉 세션 결정이 먼저다.

const INFO := {
	"shu": {"glyph": "蜀", "shape": "square", "name": "유비군", "deep": Color("0e3d39"), "mid": Color("2b8f84"), "rim": Color("7fe9dc"), "ink": Color("f4fffd"), "color": Color("5fe0cf")},
	"wei": {"glyph": "魏", "shape": "diamond", "name": "조조군", "deep": Color("4d140b"), "mid": Color("b8442a"), "rim": Color("ff9f80"), "ink": Color("fff0e8"), "color": Color("ff7550")},
	"wu": {"glyph": "吳", "shape": "circle", "name": "손권군", "deep": Color("2a1d4a"), "mid": Color("6a4fb0"), "rim": Color("c7b4ff"), "ink": Color("f6f0ff"), "color": Color("b9a2ff")},
}

static func of(key: String) -> Dictionary:
	return INFO.get(key, INFO.shu)

static func of_side(side: int) -> String:
	return "wei" if side == 1 else "shu"
