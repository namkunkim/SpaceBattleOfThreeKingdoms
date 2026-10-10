# REVIEW-O5 — UI 문구 전대 → 함대 (Q73, §T-1 O5)

- 대상: `0505971`(O5 본 변경), `d8da15b`(`tests/ui_wording.gd.uid`)
- 리뷰: 2026-10-10, 리뷰 세션(코드 수정 없음)
- 판정: **조건부 수용**

## 범위

- 화면 문자열: `hud/`, `view/`, `input/`, `scripts/`, `core/`의 GDScript 리터럴, `scenes/*.tscn`, 화면에 나오는 데이터 필드(`data/`), `플레이_조작법.md/txt`, 생성기 `tools/scenario/make_red_cliffs_208.py`.
- 내부 식별자·데이터 키·저장 형식이 바뀌지 않았는지.
- "함대"로 바꾸며 뜻이 어긋난 곳(예전 상위 묶음 '함대'와의 혼동).
- `tests/ui_wording.gd`의 검사 범위.
- 범위 밖: `docs/` 설계·역사 서술, 코드 주석, 규칙 메모(`note`, `*_rule`, `historical_basis`, `open_issues` — 현재 화면에 쓰이지 않음을 확인).

## 실행한 테스트와 결과

Godot `C:\Tools\Godot\Godot_v4.7.2-stable_win64_console.exe --headless --path . -s tests/<이름>.gd`

| 테스트 | 결과 | 비고 |
|---|---|---|
| `ui_wording` | PASS (`UI_WORDING_PASS`, exit 0) | |
| `rule_text` | PASS (`RULE_TEXT_PASS`, exit 0) | POC 프로필에서 `battle_source.gd:47` `combat.formations` 접근 SCRIPT ERROR가 여러 번 찍힌다. O5가 건드리지 않은 파일(마지막 변경 `fe2d202`)이라 기존 문제 |
| `squadron_strip` | PASS (exit 0) | 종료 시 ObjectDB 누수 경고(기존) |
| `ui_flow` | PASS (exit 0) | 종료 시 ObjectDB 누수 경고(기존) |

추가 확인: 생성기 `make_red_cliffs_208.py`를 다시 돌려도 `red_cliffs_208_realtime.json`에 차이가 없다(생성기와 데이터 일치). `boundary.gd`는 지시대로 돌리지 않았다.

## 확인한 것 (문제 없음)

- 남은 "전대": 위 경로의 문자열 리터럴·`.tscn`·조작법 문서에는 없다. 남은 것은 모두 주석, 테스트 실패 메시지(화면 아님), 규칙 메모(`note`·`deploy_rule`·`historical_basis` 등, GDScript에서 읽지 않음), `data/scenarios/base/`(본편 사본, 게임이 `world_208.json`만 읽음)뿐이다.
- 내부 식별자: diff는 표시 문자열 9곳뿐이다. `squadrons`, `RC-*-SQ-*`, `squadron_strip`, `FleetState`, JSON 키, 저장 형식은 그대로다. `RC-CAO-SQ-03`의 `name`만 바뀌었고, 이 이름을 문자열로 기대하는 테스트는 없다(`tests/`에서 "서황 전대" 검색 0건).
- 바뀐 문장 자체(`%d개 함대 제외`, `%d개 함대 · %d척`, `정찰 전에는 함대 수·구성·척 수`, `편성 %d에 %d개 함대 저장`, `사령관 · 기함 함대`, `황개 함대`, 조작법 `함대 띠 카드`)는 뜻이 맞다.

## 발견 사항

| # | 심각도 | 위치 | 내용 | 권고 |
|---|---|---|---|---|
| 1 | 중간 | `data/scenarios/red_cliffs_208_realtime.json:2851`, `tools/scenario/make_red_cliffs_208.py:72` + `hud/ui_kit/order_undo.gd:74`, `scripts/FleetBattle3D.gd:402,435,440`, `hud/ui_kit/commanders.gd:22`, `hud/battle_hud.gd:313` | 함대 이름이 `"서황 함대"`가 됐는데, 화면 틀이 `"%s 함대" % fname`이라 **"서황 함대 함대"**, "서황 함대 함대를 친다!", "서황 함대 함대 격파!"가 뜬다. 다른 13개 함대는 "조인 선봉", "조홍 후군"처럼 '함대'로 끝나지 않아 이 하나만 겹친다(바꾸기 전에도 "서황 전대 함대"로 어색했지만 O5에서 단어가 그대로 중복됐다) | 생성기와 JSON에서 이름을 '함대'로 끝나지 않게 바꾼다(예: "서황 중위"·"서황 별군" — 이름은 시나리오 세션이 정함). 회귀 방지로 `ui_wording`에 "함대 이름은 '함대'로 끝나지 않는다" 검사를 하나 넣는 것을 권한다 |
| 2 | 중간 | `hud/ui_kit/command_deck.gd:730` | 선택 패널 펼침의 `"지휘관 %s  ·  함대 %s"`에서 '함대' 칸에 상위 묶음 `fleet_groups[].name`("유비 연합 전단", "형주 항복 수군" 등)이 들어간다. 조종 단위를 '함대'로 부르게 된 지금, 같은 화면에서 '함대'가 단위 자신과 상위 묶음 둘을 가리킨다(점검 항목 3의 혼동 사례). O5 diff가 건드리지 않은 줄이라 놓쳤다 | 라벨을 "전단"으로 바꾸거나(데이터 이름도 '전단'), Q73(함대 한 단계)에 따라 상위 묶음 표시는 O1 이후 편성 화면 작업에서 정리한다고 대기열에 적는다. 결정이 필요하면 사용자에게 묻는다 |
| 3 | 낮음 | `tests/ui_wording.gd:9-11` | 데이터 검사가 키 `name·role·label·title·text`만 본다. 실제로 화면에 나오는 `note`(`difficulty_profiles[].note`, `scripts/world/battle_brief.gd:26`), `claimed`·`estimate`(`roster_screen.gd:126`), `effect`(계략 카드)는 빠져 있다. 지금은 해당 값에 "전대"가 없어 통과하지만 회귀를 못 잡는다 | `SHOWN_KEYS`에 `claimed`, `estimate`, `effect`를 더하고, `note`는 `difficulty_profiles` 아래만 따로 검사한다(다른 `note`는 규칙 메모라 넣으면 너무 넓다) |
| 4 | 낮음 | `tests/ui_wording.gd:8` | `scenes/*.tscn`(Label `text` 속성)과 `플레이_조작법.md/txt`를 검사하지 않는다. 둘 다 플레이어가 보는 문구다. 현재는 "전대" 없음 | `DIRS` 스캔에 `.tscn`의 `text = "..."` 줄과 조작법 두 파일의 전체 문자열 검사를 더한다 |
| 5 | 낮음 | `tests/ui_wording.gd:24-45` | 리터럴 판정이 줄 단위라 여러 줄에 걸친 `"""..."""` 문자열 속 단어는 못 잡는다. 지금 대상 경로에 `"""`는 없다 | 지금은 두어도 된다. 여러 줄 문자열을 쓰기 시작하면 파일 단위 판정으로 바꾼다 |
| 6 | 낮음(O5 무관) | `view/fleet_render/battle_source.gd:47` | `rule_text` 실행 중 POC 규칙에서 `combat.formations` 없음 SCRIPT ERROR가 반복된다. 테스트는 PASS라 오류가 묻힌다 | `combat.get("formations", {})`로 막는 별도 항목을 대기열에 둔다 |

## 판정

**조건부 수용.** 스펙 범위(화면 리터럴 교체, 내부 키 유지, `ui_wording` 추가, 지정 테스트 통과)는 충족한다. 조건:

1. #1 "서황 함대 함대" 중복을 이름 변경으로 해소한다(화면에 실제로 보이는 결함).
2. #2 '함대' 라벨이 상위 묶음을 가리키는 문제의 처리 방향(라벨 "전단" 또는 O1 이후 정리)을 정해 `CHECKLIST-OPEN.md`에 적는다.

#3~#5는 `ui_wording` 보강 권고, #6은 O5와 무관한 별도 대기열 항목이다.
