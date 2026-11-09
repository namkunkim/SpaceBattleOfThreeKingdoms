# P02 직접 출격 장면 거절 · 실행계획 V2

상태: 독립 계획 재심사 대기. 이 문서는 PLAN.md와 REVIEW-PLAN-INDEPENDENT.md의 실행 미확정 사항을 구체화한다. 제품 수정 및 엔진 실행 0회. PC0 2/2와 여덟째 후보 미사용 K6을 보존한다. 계획 작성자 모델 ID는 이 실행에서 직접 검증되지 않았다. 조율자와 독립 심사자는 실제 실행 할당 기록을 인용한다.

## 소유와 동결

- 제품 허용 범위는 scripts/world_link.gd의 go_battle 및 view/world/world_map_screen.gd의 직접 출격과 해당 출발 맥락 복구뿐이다. WorldLink 네 필드는 전환 호출 전 기존 순서로 게시하고 Error != OK인 경우만 원래 값/참조로 되돌린다. 현재 outgoing map을 지키며 browse는 카드, result는 같은 결산 화면을 복원한다. 실패시 auto 전환이나 결산 재게시 없이 오류가 보이고 플레이어는 재출격할 수 있다. 카메라 프레임을 되감는 범위는 제외한다.
- 테스트 추가는 기존 tests/world_link.gd에만 넣는다. 정상 production helper 변경이나 테스트 전용 제품 훅이 필요 없다. P03 private owner, runtime adapter, FleetBattle3D, AutoResolver, 기존 worker 테스트의 제품 변경은 범위 밖이다. P05/P07 코드는 각각 별도 소유다.
- branch codex/feature-i01b-not_remove, HEAD 0be09755b70378286105972f35ac5b7031715664, staged diff 비어 있음. scoped-baseline.json에 index 파일과 관련 경로의 현재 SHA를 기록했다. baseline.json은 tracked 2,494, git 비무시 untracked 55,855 항목을 순차 수집했다. tracked null 하나는 기존 삭제 P02-EVIDENCE-LOCATIONS.md이고 untracked null 하나는 중첩 repo의 디렉터리 항목이다. Git 장경로 캐시 경고가 있었고 수집 중 새 evidence 파일이 생겼으며 시작/종료 status가 다르므로 글로벌 원자적 스냅샷으로 쓰지 않는다. branch/HEAD/index SHA 및 staged diff는 수집 전후 동일했다.
- closure-v2.json의 1,480개 source SHA를 실제 실행 복제 입력으로 고정한다. run02 기록은 **파일 목록의 시드**만 제공했다. bytes는 현재 원본을 다시 읽었으며 기존 기록의 캐시와 UID 생성물은 가져오지 않는다. 목록의 현재 원본에 없는 UID 네 건은 현재 입력에서 생략한다. 이 네 쌍의 .gd는 존재한다. 새 import에서 생성되는 UID와 .godot/class/import 파일 목록·SHA는 별도 기록한다. 원본의 현재 project.godot과 branding 아이콘도 그대로 동결했다. closure에서 P03 현재 private owner bytes와 비소유 formation 변경을 모든 lane에 같은 값으로 유지하고 그 사본을 P02 변경량에서 제외한다. 기존 진행표/worker hunk는 실행 입력 편집 대상이 아니다.
- 공유 쓰기 전 scoped-baseline 및 closure의 현재 SHA, Git staged/HEAD, 다른 채팅 소유를 재대조한다. 코드 작성 후 before/after의 바뀐 입력은 승인된 두 제품 경로와 동일한 tests/world_link.gd 테스트 hunk뿐이다. 최초에는 두 제품 hunk도 evidence 내부 복제본에서만 검증한다. 적용은 독립 5-b 수용 이후 별도 보존 확인을 거친다.

## 실제 엔진 거절 fixture

1. 신규 실행 루트는 C:/WorkSpace/SpaceBattleOfThreeKingdoms/tmp/p02-pc-next-20261109/attempt-NN. 같은 경로 재사용 금지. 절대 경로 검증 뒤 closure를 before/project와 after/project에 원본을 링크하지 않고 복제한다. 테스트 hunk는 두 복제본에 동일하게 넣는다. 두 프로젝트의 scene 파일을 온전히 둔 상태로 fresh import한다.
2. 각 import 완료 후 noncached source 및 새 cache manifest를 동결한다. 정상 before/after 프로젝트는 그대로 둔다. 각각을 before-reject/project, after-reject/project로 복사하여 **그 복제본에서만** scenes/FleetBattle3D.tscn 한 경로를 의도적으로 제외한다. .godot에서 해당 씬이 대체 파일이나 remap으로 load 가능한 경로를 확인하면 실행 전에 중단한다. 원본과 정상 lane의 scene SHA는 유지한다.
3. 기존 suite에 --direct-reject lane 추가. 시작 가드는 FileAccess.file_exists와 ResourceLoader.has_cached가 둘 다 false, current scene이 실제 WorldMap으로 만들어졌고 user:// 및 res://가 지정 lane에 귀속됨을 확인한다. --script가 실행하는 SceneTree는 기존 _screen_new를 사용한다. 앱 기본 main_scene은 바꾸지 않는다. 같은 scene 파일을 복구하거나 엔진에 monkey patch 하지 않는다.
4. 결과 실패 실험은 독립된 세 개 실제 WorldMap 인스턴스로 하고, 각 fixture가 고유 before 상태를 구성한다. 기존 결과 화면은 WorldLink.outcome의 실제 1회 consume으로 연다. 최초 결과 animation 타이머가 완료된 후 관측값을 저장한다. 그 뒤 다른 non-null outcome을 sentinel로 넣어 UI 복구가 consume/overwrite하면 검출한다. outcome 및 brief 비교는 객체 identity다. auto worker가 생기는 경우 즉시 fail/cancel 정리한다.

## 정확한 신규 오라클

- F 3개. source 파일 누락, ResourceLoader 미캐시, 격리 res/user 두 경로 귀속. 하나라도 실패하면 rejection 실행 금지.
- R 6개. WorldLink.go_battle 단독 1회, Object.call을 써 before의 void와 after의 Error를 같은 테스트에서 읽는다. R1 ERR_CANT_OPEN, R2 current scene 동일, R3 기존 brief 동일, R4 기존 outcome 동일, R5 last_difficulty 동일, R6 last_mode 동일.
- A 10개. browse 실제 출격 버튼으로 시작하고 제품 skip signal을 한 번 발화한 뒤 같은 signal을 다시 발화하고 4프레임 관찰. A1 기존 WorldMap identity, A2 네 WorldLink 필드와 값 동일, A3 이전 local brief 동일, A4 state browse, A5 input unlocked, A6 caption/skip 숨김, A7 기존 출격 카드와 enabled 버튼, A8 오류 chip 표시, A9 resolver null 및 auto 화면 숨김, A10 두 번째 skip 뒤에도 browse/current scene/link가 동일. 실제 새 시도가 가능한 UI를 확인하되 missing-scene lane에서 성공을 기대하지 않는다.
- B 13개씩 2회. 별도 초기화한 결과 화면에서 실제 기존 버튼 텍스트 '같은 판 다시'와 '새 판'을 각각 찾고 연결된 pressed signal을 발화한다. B1 전환 직전 same은 지정 seed 777·new는 테스트 RNG를 미리 고정해 다음 randi()%1000000의 예측 seed, mode direct, B2 current scene 동일, B3 WorldLink 네 필드 동일, B4 local brief 동일, B5 outcome 객체 동일, B6 state=result/card 표시, B7 결과 title/seed/ending/loss 네 표시값 동일, B8 두 결과 출격 버튼 활성, B9 input unlocked와 caption/skip 숨김, B10 오류 chip, B11 sentinel outcome 미소비 및 resolver null, B12 이전 결과 이후 decision 음향 재게시 0 (UISound.history를 해당 호출 직전에 초기화해 확인), B13 추가 skip 및 0.7초 뒤 동일 결과·지역 표현을 유지하고 추가 결산 없음. 결산 타이머를 재생성하는 코드 경로가 없는지도 독립 diff로 확인한다. 새 판의 RNG 고정은 다른 프레임 작업이 없는 버튼 호출 직전에 수행하고, seed 계산 뒤 같은 RNG seed를 다시 설정한다.
- 합계 45개 (3+6+10+13+13), 엔진 전환 거절은 4회(R 1/A 1/B 2), 중복 skip에서 추가 거절 0. F에서 중단하면 45 분모 PASS 금지. 각 단언 ID·실행 순서·ok를 기존 테스트 로그와 RESULT marker에 남긴다. before는 동일 fixture와 실제 오류가 있고 기존 계약 단언에서 exit 1이어야 한다. 정확히 어떤 단언이 실패했는지를 원문으로 기록한다. 제품 실패 분기의 회귀가 before에서 재현되지 않으면 계획으로 돌아간다.
- C 4개. 별도 --direct-round-trip lane에서 기존 tests/world_link.gd의 _round_trip을 호출하고 기존 스킵 emit 직후 같은 버튼에 즉시 emit 1회 추가. 신규 고정 단언은 outgoing node가 제거/전환 경계 진입, FleetBattle3D scene_changed 정확히 1회, brief identity/seed/difficulty/mode 전달, WorldMap의 결산 소비 정확히 1회다. 기존 _round_trip의 고정 11개와 두 _touch_sizes의 기존 동적 단언도 통과해야 한다. 동적 분모는 각 표시 버튼 ID × TouchMetrics.TOUCH_DEVICES 전체이며 before/after에서 목록과 수를 대조한다. 조기 종료나 누락은 fail. before/after 동일 테스트, returning-user로 실행한다. 강제 sim._end를 자연 종결로 집계하지 않는다. reject 결과의 재시도 가능 화면과 별도 정상 프로세스의 출격 성공을 서로 구별한다.
- D 기존 실실행 회귀. K5 auto viewport probe 그대로 complete 14/14와 cancel 15/15, title smoke tests/ui_flow.gd 20개, restart tests/battle_flow.gd 23개를 동일 closure의 before/after에서 수행한다. probe가 같은 seed와 원문 결산 fingerprint·join·cancel 확인을 내야 한다. 과거 K5 evidence는 reference oracle이며 현재 결과와 대체하지 않는다. 기존 clean WorldLink 서막 단일 실패는 별도 알려진 편차이며 clean을 반환 정상 lane의 기대값으로 쓰지 않는다. title 테스트는 그 자체의 first/second run 서막 계약을 fresh lane에서 확인한다.

## 명령·시간·증거

엔진 C:/Tools/Godot/Godot_v4.7.2-stable_win64_console.exe SHA-256 C8F0A6BC45A19B33541501E57F6F7CD972AB18453743266339D495CBBE846643. 관측 자손 exe C:/Tools/Godot/Godot_v4.7.2-stable_win64.exe SHA-256 AB1824F85BFD8E0E4128182C000C4003A3E042245B2967848D089B2A04B22424. 각 명령을 정확한 argv 배열로 materialize한 뒤 hash, 환경 및 입력 SHA를 동결한다. G는 위 exe, P는 lane project 절대 경로, E는 동일 attempt 하위 전용 evidence 절대 경로다. import 2회, rejection·round-trip·auto complete·auto cancel·title·restart 각각 before/after 2회로 총 14 프로세스, 전부 직렬이다.

| lane | G 뒤 argv | wall timeout |
|---|---|---:|
| import | --headless --path P --log-file E/engine.log --editor --import | 300초 |
| reject | --headless --path P --log-file E/engine.log --script res://tests/world_link.gd -- --direct-reject | 45초 |
| direct | --headless --path P --log-file E/engine.log --script res://tests/world_link.gd -- --direct-round-trip | 60초 |
| auto complete | --headless --path P --log-file E/engine.log --script res://tests/p02_k5_world_product_probe.gd -- complete E/result.json | 195초 |
| auto cancel | --headless --path P --log-file E/engine.log --script res://tests/p02_k5_world_product_probe.gd -- cancel E/result.json | 90초 |
| title | --headless --path P --log-file E/engine.log --script res://tests/ui_flow.gd | 75초 |
| restart | --headless --path P --log-file E/engine.log --script res://tests/battle_flow.gd | 75초 |

auto probe는 기존 tmp/p02-seventh-20261108/k5-world-product.gd를 복제본의 명시 경로에 bytes 동일하게 복사한다(SHA-256 8946CB6F6B9F64CCEB8208116FEEADBA67759748D61084F4D21845575E5E6D07). runner는 기존 격리·소유 Job 감독기 방식을 사용하고 새 CUA/OS 입력 도구를 작성하지 않는다. 격리 사용자 경로는 E/roaming, E/local, E/temp로 APPDATA·LOCALAPPDATA·XDG_DATA_HOME·TEMP·TMP를 지정한다. 실제 OS.get_user_data_dir 및 ProjectSettings.globalize_path 검사로 입증한다. returning direct 및 두 auto lane은 E/roaming/Godot/app_userdata/SpaceBattleOfThreeKingdoms/settings.cfg에 고정 UTF-8 LF bytes '[progress]\nprologue_seen=true\n'를 생성하고 사전 SHA를 남긴다. 각 프로세스의 stderr/stdout, Godot 로그, argv JSON, actual exit, timeout과 root/owned child 정리·active 0, 입력 manifest, 테스트 행 수를 E에 둔다. 원본의 파일/caches/사용자 설정에 쓰지 않는다.

reject의 예상 엔진 로그는 호출당 exact path res://scenes/FleetBattle3D.tscn의 텍스트 loader 'Cannot open file'와 ResourceLoader 'Failed loading resource' 각 1개다. 각각 총 4개를 예상하며 브랜치나 4.7.2 배포 차이 때문에 format/건수가 다르면 조용히 allowlist를 넓히지 않고 raw 로그를 독립 판정으로 돌린다. ERR_CANT_OPEN은 테스트에서 확인한 Godot Error이고 프로세스 종료값이 아니다. before reject는 기대 계약 실패의 TEST_FAIL과 exit 1, after reject는 45/45 marker 및 exit 0을 요구한다. 다른 lane exit 0. SCRIPT ERROR·parse error·timeout·외부 중단은 별개 실패이며 정상 결과로 집계하지 않는다. 기존 ObjectDB/리소스 종료 진단은 동일 closure before/after에서 메시지·수·상황을 대조한 경우에만 기존 진단으로 분리한다.

합산 timeout 상한 1,680초/시도이며 고유 fixture를 포함하는 이번 조각만 최대 6회다. PC0 재실행/상한 재할당 및 여덟째 K6 사용은 없다. 첫 PC operation·물리적 입력/렌더·자연 종료 증거를 산출하지 않는다. P02 전체 NOT_READY. 사용량 한도 시 즉시 중단하고 상태·증거 경로를 조율자에게 인계한다.

엔진 참고: https://docs.godotengine.org/en/stable/classes/class_scenetree.html 및 https://github.com/godotengine/godot/blob/master/scene/main/scene_tree.cpp, https://github.com/godotengine/godot/blob/master/scene/resources/resource_format_text.cpp, https://github.com/godotengine/godot/blob/master/core/io/resource_loader.cpp . Master 소스는 메시지 예상 근거이며 실행 설치본의 실제 로그가 정본이다.


