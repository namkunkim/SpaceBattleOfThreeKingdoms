# P02 첫 PC · 천하 복귀 실패 알림 계획

계획 1~3 · 2026-11-09 KST · 독립 심사 대기

## 1. 의도와 범위

첫 PC 경로의 실제 천하→적벽 직접 전투에서 천하 복귀 버튼을 눌렀는데 엔진이 즉시 거절하면, 현재 화면에서 실패 사실과 다음 동작을 읽고 같은 버튼으로 다시 요청할 수 있게 한다. 실제 결과 게시의 실패 은폐를 줄이고, 준비 실패 화면에 갇혔을 때 조작이 받아들여졌는지 알려준다. PC0 및 앞선 복귀 롤백의 증거를 재사용한다. 같은 규칙의 저장·재개, P05/P07 작전 공간·목표, 비동기 전환 수락 이후 실패는 별도다. 전투 프로필, 기본 fallback, 작전 활성화, WorldMap, 결산 규칙과 오디오를 수정 범위 밖에 둔다. 현재 첫 PC 전체 미완료다.

- scripts/world_link.gd의 go_battle은 이미 Error를 돌려준다. back_to_world는 실제 change_scene_to_file의 즉시 Error에서 직전 brief/outcome 객체를 복원하고 숫자 코드 경고를 남기지만 호출자는 그 상태를 받지 못한다.
- scripts/FleetBattle3D.gd의 전장 복귀는 종료 시 BattleOutcome.from_sim으로 매번 새 DTO를 만든다. 첫 준비 실패의 별도 버튼은 WorldLink에 직접 null을 전달한다. 초기 standalone에서는 종료, 활성 재준비 실패에는 이 버튼이 없다.
- hud/ui_kit/deck_screens.gd의 PauseScreen과 ResultScreen은 command_deck.to_title을 공유한다. routed의 버튼 문구가 '천하로'이며 standalone의 기존 제목 복귀 및 재초기화 경로가 같은 엔트리를 사용한다. 표시된 버튼과 동일한 focus 및 signal wiring을 재사용한다.
- 대체안으로 팝업/글로벌 토스트는 게임 상태·초점·렌더 레이어의 새 관리가 필요하고, 기술 경고만 보강하는 것은 플레이어에게 다음 동작을 알려주지 않는다. UI 내부 라벨은 화면 수명에 맞는다.

## 2. 인수 조건과 후보

- WorldLink.back_to_world(o) -> Error로 실제 즉시 로더 반환을 전달한다. 인수, 상태 갱신 순서, 롤백 객체 identity와 기존 로그 한 줄 WORLD_RETURN_REJECTED error=<정수>를 유지한다. 기존 결과를 무시하는 호출도 그대로 동작한다. 오류 시 exception, payload dump, path/seed/결과/유저 데이터 로그를 추가하지 않는다.
- FleetBattle3D.back_to_world() -> Error로 전달하고 WorldLink가 없으면 ERR_UNAVAILABLE을 반환한다. sim == null이면 null 결과로 기존 최초 실패 버튼과 같은 경로, sim.st.over이면 기존 from_sim, 나머지는 null이다. 최초 routed 버튼은 이 메서드와 현재 카드의 상태 표시를 연결한다. 첫 준비 실패 원인과 기존 안내는 유지한다. 활성 재준비 카드의 기존 상태 처리와 standalone 종료 흐름을 유지한다.
- command_deck.to_title은 반환·무인수 호출 계약을 유지하면서 표시 대상 Label을 선택 인자로 받는다. routed 분기에서만 실패한 경우 해당 Label.show(). 성공 후 떠나는 화면에는 별도 갱신을 하지 않는다. 두 screen은 자신이 소유한 라벨을 전달하며 on_show 시 안내를 초기화한다. standalone은 기존 init_game 성공/실패 처리 및 title 이동을 그대로 따른다. 첫 준비 화면의 라벨은 카드 수명과 함께 해제한다.
- 한국어 문구 ‘천하로 돌아가지 못했습니다. 다시 눌러 주세요.’ 한 가지를 공용 상수로 둔다. UiTheme.label의 Body·WARN, 필요 시 word wrap, mouse_filter IGNORE. 준비 실패는 기존 guidance와 버튼 사이, 일시정지는 왼쪽 메뉴 아래, 결과는 하단 버튼 행 아래 남는 영역에 배치한다. 정상 상태에서는 숨김이며 추가 버튼·팝업·타이머가 없다. '천하로' 버튼 활성과 현재 입력 위치를 유지한다. 재진입 뒤 오류가 다시 나기 전 라벨은 숨겨진다. native 해상도/긴 문구 잘림·겹침·대비는 실제 렌더 확인을 게이트로 둔다. 배치가 차지하는 공간과 기존 버튼 위치 보존을 비교한다.
- 같은 버튼 첫/둘째 거절마다 WorldLink 로더 1회·고정 로그 1행. 하나의 라벨만 보인다. 최초 준비·일시정지에서 DTO 요청 null. 결과에서는 두 실패 요청 및 성공 요청의 DTO가 각기 다른 객체이며 결과 사실은 동일하다. 재사용/캐시하거나 이전 slot DTO를 덮어 쓰지 않는다. 실패 직후 WorldLink brief/outcome, 기존 diff/mode, scene/sim/UI 화면·시간·결과 및 pause 상태가 유지된다. 기존 결과 생성 호출 수를 코드와 필요한 관측으로 구분한다. 새 가시 안내 자체는 허용하는 상태 변화다.
- 성공은 정상 WorldMap 진입과 결과의 1회 소비로 관측한다. 일시정지/준비 실패 복귀는 결과 없이 browse, 결과 복귀는 마지막으로 요청한 DTO만 기존 결과 UI가 한 번 소비한다. 기존 카드 경계(기존 P03 지도 표시 마감)를 회귀로 검토하며 지급·내구 저장은 주장하지 않는다.

## 3. 분해와 게이트

1. 현 문서, 26개 기존 관련 원본의 경로·크기·SHA/브랜치·HEAD·index·scoped status 동결, 채팅 snapshot을 독립 비-Astra 검토자에게 전달한다. 이전 baseline 목록을 그대로 쓰며 새 시험이 읽는 파일(테마/화면/데이터 포함)은 실행 전 별도 최소 closure를 고정한다. 조회는 순간 관측이다. P03 관리, P05, P07 채팅은 이 관측에서 notLoaded로 표시됐다. notLoaded는 소유권 해제나 작업 금지의 근거가 아니다. P03은 공용 FleetBattle3D의 준비/게시와 restore, P05는 분리 지도 검증, P07은 제품 연결 계획이다. 공유 FleetBattle3D 쓰기는 앞선 snapshot이 허가하지 않는다. 실제 적용 전 경로/hunk와 쓰기 창을 재확인하고 다른 소유 변경과 충돌하면 읽기 전용 상태에서 조율한다. P03 원본은 이 계획에서 수정하지 않는다.
2. 독립 수용 후 4개 파일의 관련 hunk만 격리 후보로 만들고 before/after의 실제 Godot 장면을 검증한다. 이전 복귀 시험의 실제 잘못된 WorldMap resource 경로 주입/복구 방법 및 exact warning 오라클을 재사용하되 반복 수/표시·입력·state 대조를 이 범위로 한정한다. 테스트 fixture에서만 유도하고 제품에는 주입 seam을 넣지 않는다. 가능한 한 한 격리 프로젝트를 순차 사용하고 실행 전에 실제 closure/공간을 검토한다. 경로 복구 완료와 실행 입력 hash를 확인하며, 기존 파일에 손대거나 대형 전역 snapshot/cache를 만들지 않는다.
3. 5-a는 routed pause, routed result, 최초 routed 준비 실패 각각 시작 숨김→실제 첫 거절→같은 버튼 둘째 거절→WorldMap 리소스 복구→같은 버튼 성공을 관측한다. 이전 적용 시험의 의도적 결산 유도/프로그램 신호는 해당 범위만 인정한다. baseline 거절 시 안내 부재와 상태 보존, 정상 첫 클릭 성공, standalone pause/result의 타이틀 흐름과 최초 standalone 종료, 준비 실패 기존 안내 및 기존 저장 설정의 반환 영향을 함께 대조한다. 뒤로 복귀가 성공하면 scene_changed까지 대기해 결과·재소비 방지를 본다. Windows native 렌더 증거에 routed pause/result/prepare 실패 라벨과 실제 버튼 노출을 남긴다. OS 입력 여부는 구분한다. 실행 명령, exit, raw 로그, 예상 경고 분모, 오류 및 원본 전후 해시를 보고한다. 여덟째 K6과 분리하며 PC0 2/2는 재실행하지 않는다.
4. 5-b는 별도 모델/작업자가 저장된 원문으로 검토한다. 적용/마감은 독립 수용 뒤 재동결·승인 hunk 대조가 전제다. 관리 채팅 완료 통지는 root 담당이다. 커밋·푸시·HTML·브라우저·새 worktree 작업은 계획 범위 밖이다.

## 읽기 근거

- 워크플로우-플레이북.md, CLAUDE.md, docs/battle-core/SESSION-HANDOFF.md, SESSION-REQUIREMENTS §0 및 P02-PROGRESS-CHECKLIST, tmp/p02-pc-next2-20261109/REVIEW-CLOSEOUT-INDEPENDENT.md. 루트와 경로 상위의 AGENTS.md 후보를 확인했다.
- tmp/p02-ninth-20261108/P02-P03-OWNERSHIP-20261109.md, tmp/p03-a06-map-delivery-20261109/REVIEW-CLOSEOUT-6SOL.md, P05-PC-NATIVE-ACCESS-RESULT-20261109.md, P07-PC-FIRST-OPERATION-EVIDENCE-20261109.md.
- baseline.json, chat-ownership.json. 약 4.0 GB 자유 공간이 관측됐다. 새로운 실행은 없다.
