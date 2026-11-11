# I01 일반 제품 연결 · data_rules 잔여 검토

2026-11-11 KST. E 현행 소스와 F의 기존 실행 증거를 읽기 전용으로 대조했다. 이 문서에서 판정하는 범위는 데이터 검사 분류와 후속 변경 범위다. 이 문서는 검토 시점의 E 작업본과 F 증거를 기록한다. 최신 K6 일정은 P02·P03 담당 체크리스트를 따른다.

## 대조 결과

- E 반영 후 전체 게이트 로그는 42개 리터럴·7파일·exit 1이다. 일곱 파일의 현행 E 행에서 해당 코드와 값 42개가 일치했다. 진단은 리터럴 출현 단위로 세며 같은 행의 같은 값도 출현마다 센다. E 전체 로그 (검증 폴더 `O07/i02-data-rules-hash-format-20261111-01/e-applied/run.log`) · 실행 결과 (검증 폴더 `O07/i02-data-rules-hash-format-20261111-01/RESULTS.md`)
- A04 구조 분리 로그 21건에서 이미 처리된 두 패키지 해시 항목을 제외하면 O07 결합 로그 19건과 순서까지 일치한다. 격리 분리기는 아래 23개 출현을 구조·형식·한계로 따로 세었고 결합 탐침도 exit 1이었다. 23개 구조 예외의 E 검사 반영은 후속 범위다. A04 분리 로그 (검증 폴더 `I01/a04-er-center-20261111-01/data-rules-classified/engine.log`) · O07 결합 로그 (검증 폴더 `O07/i02-data-rules-hash-format-20261111-01/gate/candidate-plus-prior-structure/run.log`) · 격리 분리기 (검증 폴더 `O07/i02-data-rules-hash-format-20261111-01/project/tests/hash_format_combined_probe.gd:68`)
- 승인 정본은 적벽 v1 정면·표준·직접 지휘의 `seed=208`, `space.size=[1700,1150]`, `space.transform=identity`를 포함한다. 현 E 정의 SHA-256은 제품 로더의 핀 `1e385b25003a5c78bc7a0c4ec0de90ac27f46f290c8277192092803e43e8a164`과 일치한다. 아래 키는 이 승인 정의 기준이다. ‘—’ 뒤 괄호는 관련 값이다. 예를 들어 `settlement.deadline_ms=1200000`, `space.motion.max_step_ms=100`과 체크포인트 시계 검사는 각자 다른 경계에서 쓰인다. 코드의 `BattleRules.TICK_HZ=10`은 별도 시계 상수다. 정의 seed와 치수 (`data/scenarios/p05_p07_first_operation_dev_v1.json:5`) · 정책·이동 키 (`data/scenarios/p05_p07_first_operation_dev_v1.json:78`) · 결산 기한 (`data/scenarios/p05_p07_first_operation_dev_v1.json:255`) · 제품 핀과 resolver (`scripts/first_operation_source_reference.gd:23`) · 시계 상수 (`core/battle/rules.gd:8`)
- 로컬 채팅 최근 목록과 기록 50건에서 동일 잔여 표를 맡은 다른 활성 채팅은 확인되지 않았다. `(DONE) I01 해시 형식 검사 후보 보완·반영` 및 `(DONE) I01 data_rules 해시 형식 검사 분리`는 마감된 두 해시 출현 범위다. r4 관련 두 채팅은 제품 저장 후보와 독립 증거를 담당했다. 체크리스트는 이 채팅에 잔여표를 배정했다. 체크리스트 배정 (`docs/battle-core/CHECKLIST-OPEN.md:25`)

## 현행 42개 출현 및 분리 후 19개

‘검사만 분리 가능’은 제품 소스를 그대로 두고 정적 검사에서 해당 출현을 분류할 수 있다는 뜻이다. 19개 가운데 치수 6개는 기존 승인 데이터를 읽는 코드로 옮길 수 있고, 시드 1개와 identity 검증 2개는 현재 소비 계약에 묶여 있다. 정면 교전·이동의 10개는 해당 값의 승인 키가 없다.

| 전체 | 분리 결과 | 현행 E 파일·행 | 현 값 | 승인 정의 키 | 동작 보존 이동 | 근거 또는 필요한 결정 |
| ---: | --- | --- | ---: | --- | --- | --- |
| 1 | 구조 | `core/battle/first_operation_checkpoint.gd:4` | `12000` | — (`settlement.deadline_ms`는 별도) | 검사만 분리 가능 | v1 진행 슬롯의 틱 상한. 작전 기한과 수치상 대응해도 슬롯의 종결 상태 검증과 결합된 계약이다. |
| 2 | 구조 | `core/battle/first_operation_checkpoint.gd:5` | `2147483647` | — | 검사만 분리 가능 | 사건 커서·제안 순번의 정수 상한. |
| 3 | 구조 | `core/battle/first_operation_checkpoint.gd:6` | `256` | — | 검사만 분리 가능 | 대기 명령 배치 상한. |
| 4 | 구조 | `core/battle/first_operation_checkpoint.gd:88` | `100000` | — | 검사만 분리 가능 | 동기 복원 첫 호출의 작업량 예산. |
| 5 | 구조 | `core/battle/first_operation_checkpoint.gd:90` | `100000` | — | 검사만 분리 가능 | 동기 복원 반복 호출의 작업량 예산. |
| 6 | 구조 | `core/battle/first_operation_checkpoint.gd:131` | `64` | — | 검사만 분리 가능 | 체크포인트 지문 필드의 16진 폭. 앞서 마감한 패키지 해시 위치와 별개. |
| 7 | 구조 | `core/battle/first_operation_checkpoint.gd:135` | `32` | — | 검사만 분리 가능 | 작전 ID 접미부 16진 폭. 생성부 16바이트와 짝을 이룬다. |
| 8 | 구조 | `core/battle/first_operation_checkpoint.gd:143` | `4294967295` | — (`seed`는 고정 값만 승인) | 검사만 분리 가능 | 정의 버전·시드 필드의 uint32 상한. |
| 9 | 구조 | `core/battle/first_operation_checkpoint.gd:147` | `128` | — | 검사만 분리 가능 | 요청의 나머지 문자열 필드 길이 상한. |
| 10 | 구조 | `core/battle/first_operation_checkpoint.gd:151` (1/2) | `100` | — (`BattleRules.TICK_HZ`는 코드 상수) | 검사만 분리 가능 | 저장 시계의 틱당 ms 변환. 첫 출현은 허용 ms 상한, 둘째는 tick과 clock_ms의 일치 검증. |
| 11 | 구조 | `core/battle/first_operation_checkpoint.gd:151` (2/2) | `100` | — (`BattleRules.TICK_HZ`는 코드 상수) | 검사만 분리 가능 | 저장 시계의 틱당 ms 변환. 첫 출현은 허용 ms 상한, 둘째는 tick과 clock_ms의 일치 검증. |
| 12 | 잔여 1 | `core/battle/first_operation_dev.gd:12` | `208` | `seed` | 단독 이동 보류 | 개발 resolver·빌더 검증과 제품 `const REQUEST`가 `Dev.SEED`를 공유한다. 데이터로 단일화하려면 상수 API, 고정 정의 검증 순서, seed 오류 우선순위와 제품·개발·복원 소비자를 함께 보존하는 설계가 필요하다. 값 재승인은 불필요하다. |
| 13 | 구조 | `core/battle/first_operation_dev.gd:122` | `16` | — | 검사만 분리 가능 | 작전 ID 접미부의 난수 바이트 수. 체크포인트 32자리 검증과 짝. |
| 14 | 잔여 2 | `core/battle/first_operation_preparer.gd:50` | `1700` | `space.size[0]` | 가능 · 선행 후보 | 검증된 `source.world_size`에서 정수 배열을 만든다. `effective_digest`에 쓰이는 Variant 형식을 보존한다. |
| 15 | 잔여 3 | `core/battle/first_operation_preparer.gd:50` | `1150` | `space.size[1]` | 가능 · 선행 후보 | 검증된 `source.world_size`에서 정수 배열을 만든다. `effective_digest`에 쓰이는 Variant 형식을 보존한다. |
| 16 | 잔여 4 | `core/battle/first_operation_preparer.gd:62` | `1700` | `space.size[0]` | 가능 · 선행 후보 | 정규화된 effective 치수를 기존 `Vector2` 메타데이터로 만든다. |
| 17 | 잔여 5 | `core/battle/first_operation_preparer.gd:62` | `1150` | `space.size[1]` | 가능 · 선행 후보 | 정규화된 effective 치수를 기존 `Vector2` 메타데이터로 만든다. |
| 18 | 구조 | `core/battle/first_operation_preparer.gd:130` | `4294967295` | — (`seed`는 고정 값만 승인) | 검사만 분리 가능 | 일반 요청 시드의 uint32 검증 상한. 제품 seed 208의 검증과 별도. |
| 19 | 잔여 6 | `core/battle/first_operation_preparer.gd:143` | `1700` | `space.size[0]` · `space.transform` | 검사만 분리 가능 | v1 `pc/identity-1700x1150/1`의 신뢰 경계. 입력 자체의 값과 비교하면 크기 거부가 사라진다. 데이터 이동에는 별도로 신뢰할 변환 규격과 합성·개발 입력 계약이 필요하다. |
| 20 | 잔여 7 | `core/battle/first_operation_preparer.gd:143` | `1150` | `space.size[1]` · `space.transform` | 검사만 분리 가능 | v1 `pc/identity-1700x1150/1`의 신뢰 경계. 입력 자체의 값과 비교하면 크기 거부가 사라진다. 데이터 이동에는 별도로 신뢰할 변환 규격과 합성·개발 입력 계약이 필요하다. |
| 21 | 구조 | `core/battle/first_operation_preparer.gd:163` | `10` | — (`BattleRules.TICK_HZ`는 코드 상수) | 검사만 분리 가능 | 초기 투영 포맷의 지원 주파수. `space.motion.max_step_ms`와 용도가 다르다. |
| 22 | 잔여 8 | `core/battle/first_operation_routes.gd:3` | `56` | — (`space.routes.front.nodes`, `approach_standoff` 관련) | 승인 결정 필요 | 정면 경로의 마지막 정책 접근점에 더하는 XY 오프셋. 승인 노드와 접근 거리만으로 같은 좌표가 정해지지 않는다. 상대 오프셋의 기준점과 데이터 소유를 결정해야 한다. |
| 23 | 잔여 9 | `core/battle/first_operation_routes.gd:3` | `18` | — (`space.routes.front.nodes`, `approach_standoff` 관련) | 승인 결정 필요 | 정면 경로의 마지막 정책 접근점에 더하는 XY 오프셋. 승인 노드와 접근 거리만으로 같은 좌표가 정해지지 않는다. 상대 오프셋의 기준점과 데이터 소유를 결정해야 한다. |
| 24 | 잔여 10 | `core/battle/first_operation_routes.gd:4` | `1355` | — (`space.routes.reinforcement.nodes`, `approach_standoff` 관련) | 승인 결정 필요 | 정면에서만 예비대 마지막 점을 대체하는 절대 XY 교전 좌표. R–C 승인 접근점과 별도로 좌표 기준·적용 경로·데이터 소유를 결정해야 한다. |
| 25 | 잔여 11 | `core/battle/first_operation_routes.gd:4` | `505` | — (`space.routes.reinforcement.nodes`, `approach_standoff` 관련) | 승인 결정 필요 | 정면에서만 예비대 마지막 점을 대체하는 절대 XY 교전 좌표. R–C 승인 접근점과 별도로 좌표 기준·적용 경로·데이터 소유를 결정해야 한다. |
| 26 | 잔여 12 | `core/battle/first_operation_routes.gd:97` | `0.00001` | — (`space.motion.turn` 관련) | 승인 결정 필요 | 경로 생성기가 정지 선회로 넘어가는 각도 차 임계값(rad). 판정기의 각도 허용치와 공유할지 및 비교 경계를 결정해야 한다. |
| 27 | 잔여 13 | `core/battle/first_operation_routes.gd:100` | `0.999` | — (`space.motion.max_speed_per_s` 관련) | 승인 결정 필요 | 경로 생성기 이동량의 무차원 배율. 최대 속도에서 얼마나 여유를 둘지, 생성기 정책의 데이터 소유를 결정해야 한다. |
| 28 | 구조 | `core/battle/operation_replay.gd:5` | `16` | — | 검사만 분리 가능 | 리플레이 입력 16 MiB 한계. `16`과 두 `1024`는 동일 식에 속한다. |
| 29 | 구조 | `core/battle/operation_replay.gd:5` (1/2) | `1024` | — | 검사만 분리 가능 | 리플레이 입력 16 MiB 한계. `16`과 두 `1024`는 동일 식에 속한다. |
| 30 | 구조 | `core/battle/operation_replay.gd:5` (2/2) | `1024` | — | 검사만 분리 가능 | 리플레이 입력 16 MiB 한계. `16`과 두 `1024`는 동일 식에 속한다. |
| 31 | 구조 | `core/battle/operation_replay.gd:6` | `18000` | — | 검사만 분리 가능 | 리플레이 요청 시뮬레이션 틱 상한. |
| 32 | 구조 | `core/battle/operation_replay.gd:7` | `18000` | — | 검사만 분리 가능 | 리플레이 명령 수 상한. 같은 숫자의 틱 상한과 독립된 검사. |
| 33 | 구조 | `core/battle/operation_replay.gd:8` | `2147483647` | — | 검사만 분리 가능 | 리플레이 ID 정수 상한. |
| 34 | 구조 | `core/battle/operation_runtime_adapter.gd:9` | `2147483647` | — | 검사만 분리 가능 | 정수 필드·편성 척수·합계의 상한과 오버플로 가드. |
| 35 | 구조 | `core/battle/operation_runtime_adapter.gd:45` | `4294967295` | — (`seed`는 고정 값만 승인) | 검사만 분리 가능 | 어댑터 입력 시드의 uint32 상한. |
| 36 | 구조 | `core/battle/operation_runtime_adapter.gd:48` | `10` | — (`BattleRules.TICK_HZ`는 코드 상수) | 검사만 분리 가능 | 어댑터의 지원 주파수. `unsupported_hz` 경계. |
| 37 | 잔여 14 | `core/battle/p05_p07_first_operation.gd:32` | `1700` | `space.size[0]` | 가능 · 선행 후보 | 핀 검증을 거친 정의 치수에서 정수 비교값을 얻는다. 정의 동등성 검증도 유지한다. |
| 38 | 잔여 15 | `core/battle/p05_p07_first_operation.gd:32` | `1150` | `space.size[1]` | 가능 · 선행 후보 | 핀 검증을 거친 정의 치수에서 정수 비교값을 얻는다. 정의 동등성 검증도 유지한다. |
| 39 | 잔여 16 | `core/battle/p05_p07_first_operation.gd:96` | `0.00001` | — (`space.motion.max_turn_deg_per_s` 관련) | 승인 결정 필요 | 선회 상한에 더하는 각도 허용치(rad). 적용 위치와 허용 경계의 규약이 필요하다. |
| 40 | 잔여 17 | `core/battle/p05_p07_first_operation.gd:98` (1/2) | `0.00001` | — (`space.motion.turn` 관련) | 승인 결정 필요 | 동시 이동·선회 거부의 두 임계값. 첫 출현은 이동 거리, 둘째는 각도(rad)라 숫자가 같아도 단위가 다르다. |
| 41 | 잔여 18 | `core/battle/p05_p07_first_operation.gd:98` (2/2) | `0.00001` | — (`space.motion.turn` 관련) | 승인 결정 필요 | 동시 이동·선회 거부의 두 임계값. 첫 출현은 이동 거리, 둘째는 각도(rad)라 숫자가 같아도 단위가 다르다. |
| 42 | 잔여 19 | `core/battle/p05_p07_first_operation.gd:102` | `0.00001` | — (`space.motion.turn` 관련) | 승인 결정 필요 | 이동량이 양수이거나 선회가 이 각도 임계값을 넘을 때 뒤따르는 진형 위치 검증을 시작한다. 직전 판정들과 임계값을 공유할지 결정해야 한다. |

## 바로 구현 가능한 최소 묶음

1. **정적 검사만 수정하는 23개 구조 분리.** 기존 탐침의 출현 목록을 시작점으로 삼아 정해진 구문 위치와 횟수만 분리할 수 있다. 체크포인트의 숫자 경계, 리플레이의 크기·명령 한계, 어댑터 입력 검증은 현행 값과 검사 경계를 유지한다. 새 구조 분리의 검토에서는 공백·주석과 같은 무해한 편집을 허용하면서 같은 값의 추가 출현과 다른 위치의 수치가 계속 진단되는지 확인한다. 이 묶음은 코어 파일 바이트나 규칙 지문을 바꿀 이유가 없다. 기존 결합 탐침 기준 42→19, 전체 게이트는 여전히 exit 1이다. 23개 지정 출현 (검증 폴더 `O07/i02-data-rules-hash-format-20261111-01/project/tests/hash_format_combined_probe.gd:68`) · 19개 기존 출력 (검증 폴더 `O07/i02-data-rules-hash-format-20261111-01/gate/candidate-plus-prior-structure/run.log`)
2. **치수 소비 6개 출현 정리.** 선행 후보의 정확한 변경은 `first_operation_preparer.gd:50,62`와 `p05_p07_first_operation.gd:32` 두 파일 세 위치다. `int` 배열, `Vector2`, 원천/유효 딕셔너리 형식·순서 및 핀 검증을 보존한다. 기존 F 후보는 승인 정면 19/19, P05/P07 37/37, K08 20/20, 체크포인트 40/40, 외부 저장 36/36와 새 프로세스 재개 3/3, 제품 리플레이 23/23을 기록했다. source/effective digest가 일치했다. 호스트·헤드리스·리플레이 출력 비교는 실행별 ID와 규칙·상태 지문 및 원천 파일 SHA 필드를 빼고 했으며 원천 파일 SHA는 별도 비교했다. 당시 로그는 전체 44→38, 구조 분리 후 21→15로 둘 다 exit 1이었다. 현재 기록의 42/19와 결합 시 산술 예상은 36/13이며, 두 후속 묶음을 모두 적용할 경우 E 게이트 예상 잔여는 13개다. 이번 조합의 실행 결과는 없다. 선행 후보 diff (검증 폴더 `O07/i01-data-rules-approval-20261111/candidate/product.diff`) · 기준과 후보 매니페스트 (검증 폴더 `O07/i01-data-rules-approval-20261111/candidate/manifest.json`) · 선행 후보 검증·미반영 사유 (검증 폴더 `O07/i01-data-rules-approval-20261111/RESULTS.md`)

### 치수 후보의 저장·리플레이 호환과 미반영 사유

- 선행 후보는 승인 원천 파일과 전투 입력을 보존했지만, 코어 스크립트 바이트를 포함하는 지문은 `ee3f6dab832380c2038d5630d4942ed762425506f22cb6731dd7209279164fa2` → `02455f448c6164a114b4dcf0d1379355b50657bdfc54547d24c7317021c1a284`로 변했다. 후보 직전 유효한 외부 저장·리플레이는 각각 `external_rules_mismatch`, `replay_rules_mismatch`로 거부됐고 원본 해시는 같았다. 이 호환성 결과 때문에 당시 F 후보의 E 통합이 보류됐으며, A04 지도 후보에도 포함되지 않았다. 선행 보고 (검증 폴더 `O07/i01-data-rules-approval-20261111/RESULTS.md`) · A04 통합 범위 (검증 폴더 `I01/a04-er-center-20261111-01/RESULTS.md`) · 코어 지문 (`core/battle/first_operation_checkpoint.gd:102`) · 외부 저장 가드 (`scripts/first_operation_external_save.gd:107`) · 리플레이 가드 (`scripts/first_operation_replay_codec.gd:67`)
- 승인된 정책은 직전 규칙의 실행본·사용자 데이터를 보존하고, 다른 지문은 현행에서 거부하며, 자동 이전을 제공하지 않는 것이다. A06 기존 증거에서 별도 실행 사본 지문 `2ff8117a…`으로 기존 4틱 저장·리플레이를 다시 열었고 현행 `ee3f6dab…`에서는 두 파일을 거부하면서 SHA를 보존했다. 선행 치수 후보에서도 직전 입력 파일 바이트 보존을 확인했다. 따라서 치수 6개는 이 정책 안에서 구현할 수 있고 지문 변화로 사용자 재승인이 생기지 않는다. 적용 시점에는 당시 직전 지문의 실행본·사용자 데이터 보존을 결속하고 새 후보와 기존 파일의 호환 경계를 확인해야 한다. 선행 치수 후보 자체의 새 Windows 패키지 및 직전 배포 실행본 보존을 묶은 검증은 해당 보고에 없다. 기존 보존·재개·거부 기록 (검증 폴더 `I01/a06-approved-front-20261111-01/RESULTS.md:26`) · 승인된 정책 (검증 폴더 `I01/a06-approved-front-20261111-01/RESULTS.md:36`) · 치수 후보 배포 범위 (검증 폴더 `O07/i01-data-rules-approval-20261111/RESULTS.md`)

## 구체적으로 남는 결정

- **시드 1개와 v1 identity 검증 2개.** 값은 승인돼 있다. `Dev.SEED`의 상수 API, 요청 거부 우선순위, 제품·개발 경로를 보존하는 시드 공급 설계가 남는다. 치수의 두 허용값은 일반 Preparer의 고정 v1 경계다. 현재 허용 범위를 유지하며 검사에서 구조 계약으로 다룰지, 별도 신뢰 변환 규격을 정의할지 결정해야 한다. 개발 시드와 원천 검증 (`core/battle/first_operation_dev.gd:38`) · 제품 요청 상수 (`scripts/first_operation_source_reference.gd:9`) · identity 경계 (`core/battle/first_operation_preparer.gd:135`)
- **교전 좌표 4개와 이동 수치 6개.** 정면의 상대 오프셋·예비대 절대 교전점의 기준과 적용 경로, 경로 생성기 속도 배율과 선회 정지 전환, 정책 판정기의 거리·각도 허용치를 각각 확정해야 한다. 현재 승인 키는 경로 노드·접근 거리, 속도·선회 상한과 정지 선회를 정한다. 관련 승인 키에 런타임 상수를 대입할 근거는 없다. 데이터에 새 키를 넣는 경우 승인 정의 버전·핀 갱신과 정면 경로·정책 경계 검증도 범위에 들어간다. 승인 경로 및 이동 규약 (`data/scenarios/p05_p07_first_operation_dev_v1.json:78`) · 정면 교전 위치의 실제 적용 (`core/battle/first_operation_routes.gd:16`) · 경로 생성기 (`core/battle/first_operation_routes.gd:92`) · 이동 판정기 (`core/battle/p05_p07_first_operation.gd:95`)

이번 산출물의 판정은 읽기 전용 검토 마감이다. 전체 게이트 통과와 I01 일반 제품 인수는 미완료다. 체크리스트 반영은 오케스트레이터 담당이다.
