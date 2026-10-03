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

# 인물 ID → 이름·세력·초상 번호(POC 초상 시트, 없으면 -1 = 머리글자 패). 결정 카드 화자 등(리뷰 V-6).
const PEOPLE := {
	"liu_bei": {"name": "유비", "faction": "shu", "portrait": 0},
	"guan_yu": {"name": "관우", "faction": "shu", "portrait": 1},
	"zhuge_liang": {"name": "제갈량", "faction": "shu", "portrait": 2},
	"zhao_yun": {"name": "조운", "faction": "shu", "portrait": 3},
	"cao_cao": {"name": "조조", "faction": "wei", "portrait": 4},
	"lu_su": {"name": "노숙", "faction": "wu", "portrait": -1},
	"zhou_yu": {"name": "주유", "faction": "wu", "portrait": -1},
	"huang_gai": {"name": "황개", "faction": "wu", "portrait": -1},
	"sun_quan": {"name": "손권", "faction": "wu", "portrait": -1},
	"cheng_yu": {"name": "정욱", "faction": "wei", "portrait": -1},
}

static func person(id: String) -> Dictionary:
	return PEOPLE.get(id, {})

static func zi(name: String) -> String:
	return ZI.get(name, "")
