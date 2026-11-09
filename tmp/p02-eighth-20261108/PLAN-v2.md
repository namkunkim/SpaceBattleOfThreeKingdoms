# P02 여덟째 조각 계획 v2 — 공통 제품 native 초기화 경계

v1의 범위, GUI, K=6, 보존 및 독립 5-b·마감 요구를 유지한다. 다음은 v1과 독립 반려 중 입력 계약, 오라클, 실패 주입, 분모를 대체한다. 독립 재심 전 제품 수정과 실행은 보류한다.

## 제품 내부 호출 계약

- 제안 시그니처는 OperationRuntimeAdapter.create_product_native(profile: Dictionary, seed: int, mode: String) -> Dictionary. 이미 기존 호출부에서 정적 타입이 성립하는 내부 GDScript 호출만 지원한다. Dictionary는 변환·patch까지 끝난 effective 값이다. seed는 기존 GDScript int 전 범위이며 signed 음수·32비트 밖을 좁히거나 정규화하지 않는다. 10Hz는 입력 필드 없이 BattleRules.TICK_HZ로 고정한다. 임의 Variant/JSON 타입 오류는 함수의 계약 밖이며 오류 사전으로 다루지 않는다.
- 기존 BattleBrief.MODES의 "direct"와 "auto"만 계약에서 사용한다. 이 문자열은 생성 후 초기 지휘 정책을 선택한다. direct는 BattleSim.new 후 현재 side0 liu_bei에만 direct 적용, auto는 동일 생성 후 기존 set_manual_all(false) 적용. 적과 후발 증원은 해당 초기 지휘 분기 밖이다. 모드 값은 profile 변환 ID나 실행 모드 전환 토글이 아니다. POC, fallback, bench도 FleetBattle3D에서 direct 지휘 정책으로 생성하며 각각의 source→effective 변환 ID는 이번 계약에서 도입하지 않는다. I01 source ID, effective ID 및 fingerprint 정책은 후속 판정이다.
- 지원하는 유효 프로필 입력은 기존 FleetBattle3D._prepare_game 및 AutoResolver._prepare가 성공으로 만든 내부 BattleSim 입력이다. 프로필 내용의 신규 whitelist 또는 schema를 만들지 않는다. 어댑터의 신규 명시 거절은 지원 모드 밖 값에서만 발생하며 생성 전에 {"ok":false,"error":"unsupported_mode","path":"mode"}를 반환한다. 순서는 모드 검사→BattleSim 생성→초기 지휘→{"ok":true,"sim":sim}. 잘못된 중첩 데이터/엔진 예외까지 검증하거나 롤백하는 새 API가 아니다.
- auto는 brief.validate→brief.profile→기존 빈 프로필 오류 이후 고정 "auto"를 넘긴다. 기존 Brief mode 검사와 독립된 caller 역할이며 외부 Brief의 mode를 다시 이 인자로 읽어 지휘 정책을 바꾸지 않는다. direct는 기존 org 적용 및 fallback→시나리오 변환→벤치 patch→기존 guard→고정 "direct" 순서다. 기존 guard에서 끝나는 입력은 어댑터 도달 수 0이다. 새 거절 뒤 다른 생성 호출은 금지한다. 실제 제품 경로는 현재처럼 main-thread native 후보를 준비하고 게시/스레드 시작 책임을 각자 유지한다.
- 프로필과 하위 컨테이너는 생성기에 원래 참조 그대로 한 번 넘긴다. adapter는 저장, 소유권 이전, 별도 가공, 복제 또는 새 mutation을 하지 않는다. 기존 생성기의 읽기·보관·수정과 벤치 콜백이 보관한 alias의 의미를 유지한다. BattleSim._reinf_def는 profile.reinf 배열을 그대로 보관하고 combat은 SalvoCombat에 전달한다. 테스트 전용 벤치 hook은 기존 범위다. rg로 확인한 제품 트리 callback은 tests/bench_density.gd._big_preset와 tools/scenario/cross_counter_drill.gd._patch이며 둘은 준비 시 인자로 받은 p를 변이하고 그 참조를 사후 저장하지 않는다. 후자의 모의전 설정 변경은 기존 fixture일 뿐 적벽 지원을 주장하는 근거가 아니다.

## 독립 기준과 행 변경

기준선 native와 실제 제품 연결을 분리한다. (a) 원본 제품에서 동결한 전후 관측을 수집한다. (b) 동결 source를 별도로 읽은 기준 프로브가 Organization/ScenarioProfile로 source profile을 만들고 원래 BattleSim.new 및 원본 지휘 코드를 직접 실행한다. adapter를 기준 프로브에서 preload/call하지 않는다. (c) 테스트 복제에서만 호출 지점/함수 진입과 constructor 직전 카운터를 주입해 실제 변경 제품이 같은 factory를 1회 사용함을 확인한다. 이 관측용 diff는 허용 제품 diff에 포함하지 않는다.

1~4행의 각 네 난이도는 공통 고정 Brief seed와 두 호출 경로를 모두 관측한다. 준비 직전 effective profile 전체를 key와 값의 타입, 배열 순서까지 비교한다. 별도 계산은 전장 x/y 크기, ally/foe 좌표의 축별 배율, terrain rect, supply/escape 좌표, speed_per_turn과 turn_deg_per_s의 곱 및 evasion의 나눗셈, 변환되지 않는 reinf 배열을 검증한다. auto는 Organization 원본 좌표/수치 그대로 비교한다. constructor 직후와 1·10·100틱의 tick/clock_ms/hz/dt, signed seed, spawn 순서, ID·faction·controls, 모듈 활성·RNG·fingerprint, 제품 표시 대상 및 raw 초기/후속 사건을 비교한다. 사건 및 명령의 dictionary 필드 타입, 순서, 위치와 tick을 원문으로 남긴다. JSON 변환이나 normalize로 타입 차이를 제거하지 않는다. raw drain과 제품 viewer drain은 동일 큐를 소비할 수 있으므로 독립 복제 인스턴스로 각각 수집한다. 증원 시계 근처 seed 고정 별도 하위 실행에서 직전/첫 증원 틱 및 새 전대 native controls 비교를 추가한다. 자연 경로가 증원 전에 종료하면 debug 강제 경로를 별도 표시하고 자연 증원 미관측을 남긴다.

5~8행은 v1을 유지한다. 8행은 실제 벤치 callback 두 개 및 별도 synthetic alias 케이스를 하위 사례로 명명한다. 테스트 hook에서 원본 p.reinf, 해당 원소 및 p.combat의 참조를 캡처한다. 준비 직후 원본/변경 native 참조 identity를 별도 확인하고, 준비 후 기존 증원 이름 필드만 바꿔 별도 복제에서 같은 tick에 증원 호출 후 ID/이름과 사건·나머지 상태를 전후 비교한다. 관측은 준비 후 live alias가 유지되는지 확인하며 제품 플로우가 콜백 alias를 보유한다고 주장하지 않는다. combat은 원본에 실제 보존되는 mutable 참조 경계를 정적 확인하고 같은 참조를 보존한 필드의 identity를 비교한다. 8행 patch의 fixture에 변환 이후 변경한 좌표/속도 표식을 두어 transform 재적용을 검출한다.

v1 9~15행을 아래 여섯 행으로 교체한다. 새 고정 분모는 21행(v1 번호 1~8, 아래 9~14, v1 16~22를 새 15~21에 대응)이다. before/after 공통 18행(1~8, 10~12, 15~21), after-only 3행(9,13,14). 하위 실행과 프로세스·단언은 별도 집계한다.

9. 어댑터의 직접 계약 검사. valid effective profile 및 동일 signed seed에서 기존 모드 두 가지의 성공 구조를 확인하고 "invalid"와 빈 문자열의 정확 오류 사전 및 생성 횟수 0을 확인한다. 직접 positive 하위 케이스에 -1 및 4294967296 seed를 별도 고정한다.
10. 실제 direct의 잘못된 roster patch. 기존 invalid_candidate_profile 원래 오류 경로, 제품 어댑터 도달 0, 기존 세션 유지 및 다음 정상 준비를 검증한다.
11. 실제 auto의 기존 Brief 검증 실패. 알 수 없는 난이도에서 기존 메시지·worker 시작 0·outcome 0을 확인한다.
12. 별도 최초 실패 legacy 기준. 기존 guard에서 초기 실패·결과 없는 천하 복귀를 확인한다. 이 행은 새 거절 증거와 분리한다.
13. 실제 direct 준비 경로의 새 어댑터 거절. 프로브 전용 변경 제품 복제에서 실제 _prepare_game의 factory 호출에 전달하는 mode 값만 조건부로 "invalid"로 치환한다. 유효 effective profile 및 seed와 기존 guard 통과를 확인한다. runtime 함수 진입 1, constructor 직전 0, 정확 error/path, publish 0과 이전 session identity/기존 tick·trace·카메라·선택·org·명령/사건 유지 및 정상 재시작을 확인한다. 첫 시작 변형에서도 실제 천하 복귀와 결과 0을 확인한다. 정상 복제의 실제 호출/생성/게시 카운터 각 1과 구분한다. 합성 실패 화면 입력은 별도 원문으로 남긴다.
14. 실제 auto 준비 경로의 새 어댑터 거절. 같은 방식으로 실제 _prepare factory 호출에 전달하는 mode만 치환한다. 유효 Brief 및 effective profile, 진입 1·생성 0·thread start 0·outcome 0, 실제 실패 칩과 browse, 정상 복구 재시도 및 join 후 결산을 확인한다. 각 주입은 사용자 선택으로 만들 수 없는 계측용 입력이며 제품 코드에 남기지 않는다.

## 증거 분리

v1 두 longpaths 관측은 과거 증거이며 계획 재심 동결이나 K1 실행 쌍으로 재사용하지 않는다. 구현자/독립 심판은 실행 직전 별도 현재 SHA 분모를 기록한다. P03 동시 변경은 소유 판정 없이 시점별로 분리한다. 제품 코드 수정이나 검증 실행은 없었다. 권위 있는 계획자 모델 메타데이터 미확인 상태를 유지한다.
