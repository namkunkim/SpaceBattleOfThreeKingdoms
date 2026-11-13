# K6 15–18행 범위 결정표

기준은 origin/main `7f138c2df7f1a55118bf9a5b7e251703049d5bb6`이다. 행별 범위 결정과 동결에 필요한 자료를 모았다. 두 개정안은 기존 미서명 제안이며 이 문서의 상태는 결정 대기다. 과거 영수증과 현행 정적 소스만 사용했다.

| 행 | 역사 계약 유지 시 필요한 경로와 기존 근거 | 제안된 개정의 정확한 수용 범위 | 현행 재결속 |
| --- | --- | --- | --- |
| 15 | 공개 WorldMap Atlas에서 기존 적벽 카드 → 직접 출격 → 0틱 배치 → 확인으로 배치 종료. 역사 before/after 양쪽은 명령 수 증가와 배치 종료를 증명한다. 역사 launcher stdout에서 명령 tick은 확인할 수 없다. 현행 공개 CTA는 READY로 전환되므로 유지하려면 공개 routed legacy 진입과 tick 0 명령 증거를 확보해야 한다. [A, B] | 빈 프로필의 기본 EntryBoot에서 승인 정면 첫 작전으로 출격한다. 동일 소유자 C0(0틱·0ms·정지)를 두 번 읽고 명시 `StartOperation` 이후 논리 시계 진행을 확인한다. 6개 역사 입력이 새 5동작으로 바뀌며 기존 카드, 직접 배치 선택·명령·확인은 개정 범위에서 빠진다. 78638587의 합성 신호로 C0와 진행을 관측했다. [C, D] | 현재 SELECT `적벽대전 시작`, 8장 프롤로그 이후의 Skip 경로, 시나리오 적벽, READY 출격, StartOperation의 각 현재 lane 좌표·활성 상태·Windows/Godot 원문. |
| 16 | 공개 기존 카드의 routed legacy 전투에서 Space 두 번, 대체 sim, 동일 brief 시드, 동일 QA 창의 결산 없는 WorldMap 복귀. 역사 양쪽 원본이 이 전이를 검증했다. 현재 Title 하위 합성은 재시작·복귀를 관찰했지만 routed_legacy 및 fixed_seed가 false다. 유지하려면 승인된 공개 routed 진입과 기존 전이를 확보해야 한다. [A, B] | 동일 QA PID/HWND에서 승인 첫 작전 두 번을 시작한다. 첫 복귀 뒤 Atlas `OpenRedCliffs` → READY 재진입으로 요청·정수 seed 208·정의된 C0 필드는 일치하고 소유자·작전 ID는 달라야 한다. 각 명시 Start 뒤 결산 없이 Atlas 직행하며 이전 소유자가 종료되고 슬롯·결산 원장이 없어야 한다. 역사 7입력이 새 10동작으로 바뀌며 두 Space, 구형 pause 메뉴, 같은 전투의 sim 교체와 legacy brief 시드 보존이 범위에서 빠진다. 78638587의 합성 10신호와 오프라인 판정으로 두 전이와 파일 부재를 관측했다. [C, D] | 15행에 더해 양쪽 Return to map, Atlas 복귀 직후 `OpenRedCliffs`, 두 번째 READY 및 Start의 현재 lane 입력. 같은 프로세스·창에서 두 직접 전이와 양쪽 소유자 해제·저장 부재를 관측기에 결속한다. |
| 17 | 공개 지도에서 양양 팝업 → 상세 → 적벽 CTA → 기존 카드(표시, canvas z2, Atlas 숨김). 역사 양 lane은 공개 진입을 포함한 16개 단언을 보존한다. 현행 유지에는 legacy 카드로 이어지는 검토된 공개 제품 경로와 native selector가 필요하다. [A, E] | 양 lane의 #2만 `world-product-marker-card` → `legacy-card-focused-initialization`. 실제 WorldMap 씬에서 격리 하네스가 기존 카드를 열고 `synthetic_setup=true`, 카드 표시, canvas z2, Atlas 숨김을 검사한다. 16개 순서, Auto·표준·출격·생략, 완료·join, poll 멱등, legacy sim 해제, terminal core, 320초/lane과 175,000ms abort/join 유지. 보존 격리 결과는 연합군, 11,350틱·1,134,950ms, terminal fingerprint `c0e18c8c758f6767e67761630cc68cd2a5aeb2e9a5e87d0bf5cd14da5d880acb`. [E, F, G] | 개정 시 현행 두 lane fixture·계측·terminal 원본을 새 동결에 결속한다. 비교기는 새 #2와 기존 15개 ID 순서를 검사하고 공개 크레딧 false를 기록한다. 지정 selector 구성 요소 +1만 승인된 차이로 처리하고 임의 경로 차이, 다른 lane, timeout/join 누락을 거부한다. |
| 18 | 동일 공개 진입 뒤 두 Stop/cancel/join, 복원과 재출격. 역사 양 lane은 공개 진입을 포함한 24개 단언을 보존한다. 승인 첫 작전에서 조기 Atlas 복귀 두 건은 이 legacy resolver 취소 계약과 별개다. [A, E, F] | 17행과 같은 양 lane #2 치환과 격리 초기화. 24개 ID 순서와 320초/lane, 두 취소·join, 상태 복원 및 재출격을 유지한다. 보존 격리 원본에서 24개 의미 단언을 확인했다. [E, F, G] | 같은 #2 및 나머지 23개 단언의 현행 emitted 순서, 두 취소·join 및 복원·재출격 원본을 현재 두 lane에 다시 결속한다. |

## baaba60b에서 7f138c2d로 바뀐 진입 관련 소스

- `view/world/navigation_atlas.gd` Git blob `a926d6a5e91b1e4d94a37331441499b02816b7c2` → `98b1f8b1e4263ec5060d3f53b914c695a5b9e5f6`. `_tap` 457–491행의 분기 순서는 그대로다. 상세 상태에서는 접근 마커 우선, 요새 검사, 객체 검사, 접근로 fallback(491행) 순이다. `_nearest_detail_object` 515–531행은 기존 station 좌표를 행성들과 함께 거리 비교하던 방식에서, `_relay_positions`가 계산한 단일 orbital 위치와 `max(rect 대각선/2, 18/scale)`로 먼저 반환하도록 바뀌었다. `_tap`은 그 반환값으로 동일한 `_show_station_routes`를 호출한다. `_fortress_at` 정의(494–498행)를 부르는 호출은 유지되나 `_facility_rect` 828행의 참조 텍스처와 크기 상한(246 및 145 → 61.5 및 36.25)이 바뀐다. 실제 rect는 텍스처 비율과 `_fit_fortress_scale`로 계산되므로 요새 상세 hitbox에 기존 좌표를 재사용할 근거가 없다. 표시·라벨과 행성 반경 계산에도 같은 위치 변경이 연결된다. 정거장·요새 상세 클릭을 포함하는 현행 경로를 선택할 때 해당 lane의 실제 활성 좌표를 다시 결속해야 한다.
- 개요의 `_nearest_point(position, 23.0)` → Red Cliffs `red_cliffs_requested`(457–470행), 양양의 상세 열기 버튼(470–473행), 그리고 `WorldMapScreen`의 마커 연결(131행)과 `OpenRedCliffs`(484–487행)는 같은 코드를 사용한다. WorldMap 경로는 `_open_atlas_red_cliffs` → `WorldLink.open_entry_detail` → EntryBoot READY로 이어진다. EntryBoot 설정 Atlas에서는 같은 마커 신호가 `show_screen("map_detail")`에 연결된다. 두 selector의 소속 씬을 결속해야 하며 현행 화면 좌표는 이 정적 대조로 증명되지 않는다. 구형 카드에 공개로 진입한다는 17·18행 #2의 요구도 이 변경으로 해결되지 않는다.
- 7f138c2d Git blob 핀은 `view/world/world_map_screen.gd` `e101bbf767542b5edb50c486b025ba3139aab481`, `scripts/world_link.gd` `c5141800ad0d4994a95b7de60cefe30a1003d26e`, `scripts/entry/entry_boot.gd` `5a43ae68ab3cc54157b7ce56c876d0501fe72dd4`, `scripts/entry/entry_settings.gd` `0164655d341bf1cfc879d273166c6bac619ae332`이다. baaba60b와 비교해 이 파일과 `scripts/world`, `core/battle`, `data`, `native`에 차이가 없다. 격리 경로의 WorldMap `AutoResolver.new(brief)`(1128행) 이후는 변경된 Atlas hitbox를 사용하지 않는다. 정확한 런타임·자료 핀과 이미 관측한 resolver 의미를 현재 동결에서 다시 연결할 수 있는 정적 근거다.

## 결정 뒤 필요한 입력

1. 담당 범위 결정자가 15·16의 공개 EntryBoot 개정 여부와 17·18의 격리 legacy 개정 여부를 명시한다. 역사 범위를 유지하는 행은 위 표의 공개 legacy 진입을 먼저 제공하고 검토받는다.
2. 현재 정확한 before/after의 프로필·프로젝트·런타임·계측·원본을 새 동결에 연결한다. 해당하는 1600×900 Windows lane마다 PID/HWND·DPI·포커스·좌표 원점·클릭 직전 캡처와 실제 Windows/Godot down/up를 함께 결속한다. 15·16은 각 480초, 17·18은 각 320초를 기준으로 하고 개정된 동작 ID·비교·timeout 규칙을 검토한다. 전체 21행·58작업·27비교 기준을 유지한다.
3. 새 run-root와 동일 manifest SHA의 독립 ACCEPT 및 AUTHORIZE_ONCE, 신선한 입력 시간과 nonce 예약·단일 소비를 확인한다. 기존 런처의 별도 검토자와 MAIN 신원 검사에는 검토된 동일 채팅 독립 모델 신원 결속이 필요하다. 이 결정표에서 제공하는 증거의 범위는 보존 영수증과 소스 대조다.

## 인용 영수증과 파일 SHA-256

경로는 `<validation-root>/K6/` 기준이다.

| 참조 | 원본 | SHA-256 |
| --- | --- | --- |
| A | historical-264f47b9-operator-04/MANIFEST-HISTORICAL-264F47B9.json | `794d49f2d04834ed70e98d8d5f9640525627288df22e91a76579947db39adef2` |
| B | main-b2ba73ff-row15-16-offline-route-gate-01/ROW15-16-OFFLINE-PREFLIGHT.json | `a2f9010b3c9004582f7f075e81b20ce7c16afabd8ab2474d1e92f32d3a010a9a` |
| C | main-b2ba73ff-row15-16-entryboot-amendment-01/ROW15-16-UNSIGNED-MANIFEST.json | `b4a69d81cd7f30f21f2376a238acf78ecb39f0acad806487f277d63a212b3ac4` |
| D | main-78638587-row15-16-headless-rebind-01/OFFLINE-VERIFICATION.json | `a8a7777efd47d05da7f7af3f1bd463fdbdcaca3e557ca17e3e45911e106d7e57` |
| E | main-b2ba73ff-row15-18-launch-preflight-01/ROW17-18-ISOLATED-CONTRACT-PROPOSAL.json | `5dc306e35faa7c9a7149eacb93877e8fd61a2c0b6e51efde858c74ef64bafb4e` |
| F | main-36030a28-row17-18-closure-audit-01/RESULT.json | `49cdd4824f9d8b15da48fa78730ad044b82a70805aed7e89186e3dee73b26c0c` |
| G | main-baaba60b-row17-18-closure-delta-01/RESULT.json | `991c993d53867d0bccc1c05493c4c4599afc62de2df05833f49cf4ed108e15b0` |

