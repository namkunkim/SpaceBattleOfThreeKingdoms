# K6 실행 계약 v2 정정 및 구현 경계

독립 심사 반려를 반영한 별도 문서다. v1과 판정 원문을 보존한다. 제품 소스·fixture 실행과 K6은 미실행이다.

## 행 9 정정

정본 K6-EXECUTION-CONTRACT.md 행 09 및 prepared/rejection_v2.gd의 factory_contract에서 확인했다.

| Case | 기대 | 계측 counter |
|---|---|---|
| direct / -1 | 성공 | [1,1,0,0] |
| direct / 4294967296 | 성공 | [1,1,0,0] |
| auto / -1 | 성공 | [1,1,0,0] |
| auto / 4294967296 | 성공 | [1,1,0,0] |
| invalid mode | 정확한 unsupported() 결과 | [1,0,0,0] |
| 빈 mode | 정확한 unsupported() 결과 | [1,0,0,0] |

성공 shape의 키는 순서까지 ["ok","sim"]이며 ok는 true bool, sim은 BattleSim이다. state는 원래 seed 그대로, hz 10, source reinf와 동일 reference다. 각 case에서 seed/hz/fingerprint를 저장한다. 무계측 기대는 shape4/state4/reject2 = 10, 계측 기대는 calls4 추가 = 14다. sim 누락으로 state가 생략되는 경우도 실패다. seed의 restricted CLI 범위를 여기 적용하지 않는다. invalid/빈 mode는 별도 고정 seed로 호출하며 성공 case에서 rejection/no owner를 요구한 v1 문장을 폐기한다.

## 행 16 정적 근거와 남은 차이

input/battle_input.gd의 _key는 Space를 메뉴 토글로 처리한다. 일반 숫자 1..9는 play에서 Ctrl/Meta 유무에 따라 assign/select 경로로 들어간다. Key 2가 정상 그룹 선택을 하려면 fixture의 그룹 2, 그 구성원 ID/순서와 초기 선택, play 상태, OS foreground 및 focus를 먼저 고정해야 한다. 기존 Space 검증을 이 case의 성공으로 대체하지 않는다. 실제 API와 provenance 미확정으로 행 15/16은 여전히 실행 차단이다.

## Q/C/B 계측의 구현 승인 경계

- Q 기대 소스는 tests/p02_headless_adapter.gd의 reference_commands 및 동일 raw BattleSim projection이다. 실제 queue 쪽은 Cli._operation_policy_commands 및 owner.queue call이다. native raw input의 provenance와 helper bytes를 동결한다. 계획된 증거 `q-native.jsonl` 및 `q-product.jsonl`은 case/seed/tick/ordinal/typed tuple을 사용한다. Raw와 제품은 같은 BattleSim 규칙에 의존하지만 정책 생성 함수와 sim instance를 공유하지 않는다. 누락·중복·same-command 다른 순번·typed 좌표 변형·late tick은 거부한다. 현재 wrapper 계측 코드와 hash 미동결이다.
- C 기대 source는 tests/i01b_service_state.gd의 _fixture에서 직접 생성된 native sim의 양 side contact records다. 계획된 `c-source-native.jsonl`, `c-target-restore.jsonl`은 case/seed/phase/side/ID 및 typed payload fingerprint를 포함한다. _restore 전에 native side 양쪽을 캡처하고 restore 이후 대상 side와 비교하며 record identity detach도 검증한다. Source를 restore 결과에서 재구성하거나 source set과 target을 같은 내부 wrapper 함수의 호출 결과로 만들어 비교하지 않는다. 수용 원문에 양쪽 ID가 없으므로 값을 현재 확정할 수 없다.
- B 기대는 네 stage 별 .tscn 및 동적 button 구성 원문에서 유도한 stable NodePath·enabled/visible 예측 목록이어야 한다. `b-expected-stages.json`과 `b-live-buttons.jsonl`은 stage/path/device index를 비교한다. 실제 _buttons 목록을 복사한 기대와 버튼 text-only 식별은 금지다. 동적 경로·stage visibility predicate를 현재 확정하지 못했으므로 독립 oracle 미완료다.
- 이 동적 항목은 첫 제품 검증 실행으로 K6을 소진하는 최종 단일 계약 내부에만 배치한다. 원본 fixture/Godot을 사전 실행해 분모를 고정하지 않는다. 파일 이름은 manifest 계약 초안이며 결과 파일이 생겼다는 의미가 아니다.

## staging부터 정리까지 전역 deadline

V5 runner의 cap은 stage 및 verify_replica 뒤에 시작한다. 새 runner의 외부 supervisor는 stage 시작 전 absolute monotonic hard cap을 정하고, 별도 process로 controller를 실행하여 blocking copy/hash/verification도 종료할 수 있어야 한다. Controller는 prepare/verify/import/cases/postverify/flush 각각 stage 시작과 완료를 durable journal에 기록한다. 기존 V5 broker의 private Job은 각 case를 소유한다. 모든 controller 및 후손은 별도 승인된 outer Job 계층에 편입되어 외부 cap에서도 owned tree를 종료할 수 있어야 한다. 이 nested Job이 해당 Windows 환경에서 가능한지 비제품 동일 방식으로 먼저 검증한다. 가능 여부 미측정으로 현재 실적용되지 않았다.

- 대조용 예산 원문은 18,490초 job caps + 580초 cleanup + 1,200초 reserve = 20,270초다. 이 합의 reserve가 stage/import/postverify 비용을 충족하는지는 미측정이다. 행 17의 175/320은 고정한다.
- Controller deadline은 supervisor hard cap보다 flush/cleanup reserve만큼 이르다. 그 안에 실패 record를 저장하고 broker에 stop을 신호한다. Controller가 붙잡혀도 supervisor가 case files 밖에 실패·활성 stage·owned tree drain 결과를 기록한다. 최종 Job hard cap에 도달하면 parent+all known descendants의 signalled와 ActiveProcesses=0 확인을 별도 deadline으로 제한한다. Timeout 중 최종 원문 기록 실패 자체는 판정 실패다.
- 글로벌 cutoff의 다음 검증 단계는 제품 없는 blocking staging/verification synthetic case, 실제 엔진 normal/timeout lifecycle 및 non-owned sentinel의 independent HANDLE 시험이다. API 가짜 실패는 nested assign 거부 실측으로 집계하지 않는다. 제품 process 최초 시작(제품 import 포함)이 K6 소진점이며 그 이후 timeout/일부 성공으로 재실행하지 않는다.

## Manifest 및 격리 상태

최종 manifest는 정확 argv/env, case source SHA와 변환 SHA, expectation 및 evidence 경로, engine/cache/Python/closure, 각 deadline과 terminal을 요구한다. V5를 참조용으로 유지하며 `K6-V2-MANIFEST-DELTA.json`은 정확하게 정정된 행 9와 실행 차단 항목을 표시하는 review-only delta다. 독립 oracle code/diff SHA와 GUI/Job 실측, 실제 outer deadline 적용이 없으므로 runnable final manifest는 성립하지 않는다.

선택안은 HEAD 기준 P03 lane이며 활성 +9행 결합은 제외한 판정이다. 원본 +9 및 worker +2, staged 상태를 작업 전후 경로 SHA로 보호한다. 별도 snapshot 원본·replica 및 동일 baseline/candidate 합의 여부를 명시한다. 전체 index file bytes 해시와 git staged entries는 별도 관측이고 둘 다 중간 변화 부재를 증명하지 않는다. 런처의 cwd/user://·APPDATA·LOCALAPPDATA·cache·logs를 lane 하위로 고정하고 source/fixture의 외부 참조와 symlink/reparse escape를 reject 한다. Job은 process 범위만 제공하므로 원본 쓰기 차단 증거는 별도 파일시스템 실행 경계에서 확인해야 한다. 이를 입증하기 전 제품 프로세스 실행을 개시하지 않는다.
