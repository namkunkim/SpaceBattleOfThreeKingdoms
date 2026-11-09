# P02 다섯 번째 조각 구현과 5-a 증거

2026-11-08. 사전·사후 제품 동작 검증을 완료했다. 기존 기준선 보존과 신규 미귀속 경로는 독립 보존 판정에 따라 분리한다. 구현 독립 5-b는 대기 중이다.

## 변경

- `BattleOutcome.facts_from_sim`은 승패, 종료 사유, 시각, 결산 데이터의 깊은 사본, 지문을 캡처한다. `from_facts`는 호출 시점의 Brief와 이 자료로 기존 결산을 구성한다. 직접 지휘와 blocking은 기존 진입점 `from_sim`에서 이 결산 로직을 사용한다.
- `AutoResolver` legacy worker는 기존 `_loop`가 끝나면 미취소 상태에서만 사본을 반환한다. `poll`은 worker 종료와 join을 확인한 뒤 취소를 검사하고, 반환 자료의 키와 결산에 쓰이는 타입을 검증한 후 결산한다. 누락·오류 시 join 완료 뒤 기존 legacy sim에서 결산한다.
- 소유 변경은 [BattleOutcome](../../scripts/world/battle_outcome.gd)과 [AutoResolver](../../scripts/world/auto_resolver.gd) 두 파일이다. 변경 전 [BattleOutcome 사본](battle_outcome.gd.before.txt)과 [AutoResolver 사본](auto_resolver.gd.before.txt)은 12,281개 파일 기준선에 일치한다. 제품 UI, operation worker, 기존 P03 경로 및 기존 테스트 파일은 실행 입력 또는 전수 비교로 바이트 보존을 확인했다.

## 실행

| 실행 | 프로세스 | 결과 |
|---|---:|---|
| [v2 사전 1차](before-attempt-01/processes.json) | 4 | common 18행 99단언 중 2실패. A03은 첫 화면이 prologue였고 A06의 실제 거부는 `unsupported_scenario/profile`이었다. clean WorldLink는 prologue에서 1실패. worker와 headless adapter는 통과. |
| [v3 사전 2차](v3-before-attempt-02/processes.json) | 5 | common 18행 106단언, returning WorldLink, worker adapter, headless adapter 통과. clean WorldLink의 알려진 단일 실패는 별도 기록. |
| [v3 사후 1차](v3-after-attempt-01/processes.json) | 6 | common 18행 106단언과 boundary 7행 33단언 통과. returning WorldLink와 두 adapter 통과. clean WorldLink의 동일 단일 실패는 별도 기록. |

- 두 제품 경로의 `to_dict` 전필드, 결말·후일담, 카드 라벨 11개와 권역 소유가 [고정 사전 결과](v3/original-outcome-oracle.json)와 [사후 결과](v3-after-attempt-01/product-outcome-common/result.json)에서 일치한다. 사전 오라클 SHA-256은 `07c709c0c9bcb33b9acc5ddb453f09ffd5487bee7dbddc5f1444ac528f2f3165`다. [동결 기록](v3/oracle-freeze.json)
- A01은 입문 seed 11 실제 WorldMap 자동 자연 종료를 확인했다. 종료는 1096.95초에 `cao_morale_collapse`였고 시작 코스트 대비 손실은 15%/33%였다. A02 blocking 결과와 전필드가 같았다. A03은 seed 777에서 첫 진입의 서막 건너뛰기와 브리핑 자동 편성 시작 버튼을 눌렀다. 10 tick에서 종료를 주입한 뒤 실제 결과 버튼으로 돌아와 결과를 한 번 소비했다. A04 중단 버튼과 A05 씬 제거는 join 후 게시 없음과 poll false를 보였다.
- A06은 원본 적벽 입문 프로필의 `unsupported_scenario/profile` 거부를 기록했다. A07–A18은 빈 결산과 null Brief, 미종료 결과의 의미, 손실·등급 경계·장수·후일담과 패배 이유를 상수 기대와 비교했다.
- B01–B03은 실제 worker 반환을 null, 잘못된 상위 형태, 잘못된 중첩 비용 타입으로 바꿔 join 뒤 기존 결산과 일치하는 것을 확인했다. B04 완료 후 poll 전 cancel, B05 게시 후 cancel과 반복 poll, B06/B07 양방향 중첩 변이를 확인했다. [경계 결과](v3-after-attempt-01/product-outcome-boundary/result.json)
- worker adapter는 양쪽 각각 59개 검사를 통과했다. headless adapter는 각각 8사례, 13,417검사, 32거부, 자연 종료 7, 제한 1이며 [사전 관측 파일](v3-before-attempt-02/p02_headless_adapter/observations.json)과 [사후 관측 파일](v3-after-attempt-01/p02_headless_adapter/observations.json)의 SHA-256이 `5e77c23183b9a77fa56fbf0dfb829dc27b2104678fa96add8e54a44e77ef89a3`로 같다.
- 격리 사본에는 v3 공통 입력 4,209개를 복사했다. 사후 차이는 제품 파일 두 개와 사후 전용 탐침 하나다. 기존 테스트를 상속한 경로 기록기가 `OS.get_user_data_dir()`와 초기 파일 목록을 기록하고 원본 `_initialize`에 인계했다. WorldLink returning 설정은 SHA-256 `c8b752aba9f5015889c00c5a45db9fef916af2a1e1be3e68d49b8121b2db721b`다. clean WorldLink는 앞선 실패와 같은 `tests/world_link.gd:239`의 prologue/brief 단언에서 exit 1이었다.
- v3 공통과 두 WorldLink의 종료 시 ObjectDB/리소스 진단은 각각 215/18, 154/20, 154/20으로 사전·사후 동일했다. 경계 탐침은 181/18 진단을 남겼으며 사전 대응 실행이 없는 사후 전용 검사다. 모든 v3 프로세스는 시간 제한 내에 끝났다.

## 보존과 한계

- 원본 HEAD, branch, index SHA, 엔진과 글로벌 클래스 캐시가 기준선과 일치했다. [v3 사후 전수 감사](v3-after-attempt-01-workspace.json)에서 기존 12,281개 중 변경된 경로는 두 소유 파일이다. [초기 보존 비교 반려](v3/compare-unattributed.stderr)는 좁은 신규 경로 허용 목록에서 미귀속 파일을 발견했다. [독립 보존 판정](REVIEW-CONCURRENT-FILES-INDEPENDENT.md)에 따라 신규 파일의 경로와 바이트, SHA-256, 관측 시점을 별도로 기록했다. 그 파일의 출처·소유 및 첫 관측 이전 바이트는 미확인이다.
- A03은 지정 tick의 종료 주입이다. 실제 1800초 상한 도달, 동시 writer, 손상된 sim, 엔진 예외와 OS Thread.start 실패는 미검증이다. UI 증거는 headless 제품 호출과 라벨에 한정하며 GUI 수동·Android·성능은 미검증이다.
- 제한 operation에는 제품 적벽 및 Victory 결과 지원이 없다. FleetBattle3D와 WorldMap의 operation 소유권·진행·결산 및 replay 연결이 미완료다. P02/I01/I01b/A04~A06은 **NOT_READY**, 외부 save schema는 **UNCLASSIFIED**다.
