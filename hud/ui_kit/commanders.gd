class_name Commanders
extends RefCounted

# 지휘관 표시용 자료: 자(字), 컷인 대사. 전투 규칙과 무관한 표현 데이터다.

const ZI := {
	"유비": "玄德", "관우": "雲長", "장비": "翼德", "제갈량": "孔明", "조운": "子龍", "마초": "孟起",
	"조조": "孟德", "하후돈": "元讓", "조인": "子孝", "장료": "文遠", "서황": "公明", "악진": "文謙",
	"허저": "仲康", "하후연": "妙才", "장합": "儁乂",
}

const KILL_LINES := [
	"적진 하나가 무너졌다. 대열을 유지하고 다음 진으로!",
	"격파했다. 놈들의 측면이 비었다.",
	"이 회랑은 넘겨주지 않는다.",
]
const CHARGE_LINES := [
	"전 함대, 돌격하라! 놈들의 진형을 찢어라!",
	"지금이다. 앞으로!",
]
const LOSS_LINES := [
	"%s 함대를 잃었다… 진형을 메워라. 물러서지 마라.",
]
const REINF_LINE := "별동대입니다. 측면을 비워 두지 마십시오. 예비 함대를 돌려야 합니다."
const OPEN_LINE := "전 함대, 전투 배치. 위의 선봉이 회랑에 들어섰다."

# 인물 ID(본편 characters.json·시나리오 JSON과 같은 CHR-xxxx) → POC 초상 시트 번호(리뷰 W-1).
# 이름과 세력은 시나리오 JSON에서 읽는다(ScenarioRoster.person). 여기 없는 인물은 머리글자 패를 쓴다.
const PORTRAIT := {
	"CHR-0128": 0,   # 유비
	"CHR-0107": 1,   # 관우
	"CHR-0134": 2,   # 제갈량
	"CHR-0136": 3,   # 조운
	"CHR-0034": 4,   # 조조
}

# {id, name, faction(세력 키 shu·wu·wei), portrait(-1 = 없음)}. 시나리오에 없는 ID면 빈 사전.
static func person(id: String) -> Dictionary:
	var p := ScenarioRoster.person(ScenarioRoster.load_scenario(), id)
	if p.is_empty():
		return {}
	p["portrait"] = PORTRAIT.get(id, -1)
	return p

static func zi(name: String) -> String:
	return ZI.get(name, "")
