# A05 FX-G 어댑터 연결 사전검토

2026-11-13 KST · 기준 GitHub main `7f138c2df7f1a55118bf9a5b7e251703049d5bb6` · 판정 **종합 인수 대기**

캠페인 체크리스트 20행은 P06의 A05 종합 검증을 열어 둔다. 체크리스트 SHA-256은 `42547de3243ffa39536b8bc780b322c03a8bd8b04d1e3d7442754c09eb06206e`이다. FX-G는 이미 사전등록되어 있다. 기존 fixture에 동일한 유효 설정을 바인딩하고 논리 프레임을 `(0,0) → (1,100) → (2,150)`으로 관찰한다. 배속 1·2·4와 정지 및 재개의 영향을 비교하고 `(2,200)` 치환을 실패로 판정한다. [캠페인 체크리스트](../../../../SESSION-REQUIREMENTS-CHECKLIST-20261031.md) · [사전등록 74·82–83·95행](https://github.com/namkunkim/SpaceBattleOfThreeKingdoms/blob/7f138c2df7f1a55118bf9a5b7e251703049d5bb6/docs/battle-core/pc-campaign-design/I01-ACCEPTANCE-PREREG-20261026.md#L74-L95)

## 확인한 범위

| 경로 | 현재 계약과 기존 증거 |
|---|---|
| FX-G 설정 | `tests/fixtures/i01/valid_definition.json`을 읽는 기존 설정 검사에서 동일 builder를 쓰는 세 envelope의 실효 해시와 초기 clock 0을 확인한다. manifest의 `host_activation`은 false다. [설정 검사](https://github.com/namkunkim/SpaceBattleOfThreeKingdoms/blob/7f138c2df7f1a55118bf9a5b7e251703049d5bb6/tests/i01_operation_config.gd#L34-L59) · [builder](https://github.com/namkunkim/SpaceBattleOfThreeKingdoms/blob/7f138c2df7f1a55118bf9a5b7e251703049d5bb6/core/battle/operation_profile.gd#L70-L89) |
| 제한 공통 호스트·CLI·리플레이 | 제한 호스트 `prepare/advance` 및 CLI `--operation-input`, `--operation-replay`가 runtime-ready 입력을 공유한다. 실제 자연 종료 `tick=2/clock_ms=end_ms=150`의 요약·이벤트 일치가 62개 단언과 실제 CLI 비교 6건으로 기록되어 있다. 이 어댑터는 `definition`을 거부하며 identity 형식만 받는다. [기존 결과](https://github.com/namkunkim/SpaceBattleOfThreeKingdoms/blob/7f138c2df7f1a55118bf9a5b7e251703049d5bb6/docs/battle-core/pc-campaign-design/P02-PROGRESS-CHECKLIST.md#L168) · [비교 runner](https://github.com/namkunkim/SpaceBattleOfThreeKingdoms/blob/7f138c2df7f1a55118bf9a5b7e251703049d5bb6/tests/run_restricted_operation_host.ps1#L29-L55) · [입력 계약](https://github.com/namkunkim/SpaceBattleOfThreeKingdoms/blob/7f138c2df7f1a55118bf9a5b7e251703049d5bb6/core/battle/operation_runtime_adapter.gd#L3-L29) |
| 첫 작전 제품 호스트·CLI·리플레이 | 제품 요청은 승인 적벽 정의와 seed 208에 고정된다. 호스트는 +100ms를 요구하고 native owner는 하위 스텝 전에 전체 틱 시간을 더한다. `--first-operation-input`과 `--first-operation-replay`가 호출하는 제품 어댑터도 재생 결산을 `max_ticks * 100`으로 검증한다. 뷰어의 프레임 소비자는 증가하는 실제 clock을 받으므로 병목은 상류다. [제품 요청](https://github.com/namkunkim/SpaceBattleOfThreeKingdoms/blob/7f138c2df7f1a55118bf9a5b7e251703049d5bb6/scripts/first_operation_source_reference.gd#L15-L53) · [호스트](https://github.com/namkunkim/SpaceBattleOfThreeKingdoms/blob/7f138c2df7f1a55118bf9a5b7e251703049d5bb6/scripts/first_operation_host.gd#L233-L258) · [native tick](https://github.com/namkunkim/SpaceBattleOfThreeKingdoms/blob/7f138c2df7f1a55118bf9a5b7e251703049d5bb6/core/battle/first_operation_native_tick.gd#L5-L17) · [CLI](https://github.com/namkunkim/SpaceBattleOfThreeKingdoms/blob/7f138c2df7f1a55118bf9a5b7e251703049d5bb6/tests/autoresolve.gd#L146-L186) · [리플레이 결산 검증](https://github.com/namkunkim/SpaceBattleOfThreeKingdoms/blob/7f138c2df7f1a55118bf9a5b7e251703049d5bb6/scripts/first_operation_adapter.gd#L198-L217) · [뷰어](https://github.com/namkunkim/SpaceBattleOfThreeKingdoms/blob/7f138c2df7f1a55118bf9a5b7e251703049d5bb6/scripts/first_operation_replay_viewer.gd#L98-L124) |

별도의 I01b 논리시계 시험은 legacy BattleSim과 TickClock으로 50·100·150ms 하위 걸음, 배속, 정지를 검사한다. 해당 시험은 작전 어댑터를 구동하지 않는다. [시계 시험](https://github.com/namkunkim/SpaceBattleOfThreeKingdoms/blob/7f138c2df7f1a55118bf9a5b7e251703049d5bb6/tests/i01b_logical_clock.gd#L3-L49)

## 구현 인계와 재개 기준

1. P06 담당이 A05의 일반 캠페인 바인딩을 정하고 P02 담당이 세 실제 어댑터 진입점에서 사용할 경계를 검토한다. 최소 후보는 기존 FX-G builder의 유효 설정과 해시를 fixture 전용 준비 경계에서 각 실제 어댑터로 전달하고, 세 경로에서 같은 fixture 정의를 해석하게 하는 방식이다. 세 경로가 실행 루프·프레임 소비·직렬화를 각자 통과하도록 하고, clock은 해당 작전 owner가 확정한 논리 상태에서 읽는다. 초기값이 없는 상태에서 제품 호스트에 가짜 owner만 끼워 넣는 시험은 뷰어 소비 범위의 증거로 기록한다.
2. 구현 전 fixture의 owner/시간 경계를 동결한다. 10Hz의 일반 완료 틱은 100ms, 이 fixture의 첫 하위 걸음에서 종료하는 틱은 50ms를 누적한다. 벽시계·배속·정지는 스케줄링에만 작용한다. 재개 후 기준은 보존된 clock 값이다. A05가 승인 적벽 v1 경로까지 요구하는 경우에는 제품 담당이 부분 종료의 판정 시점과 결산·복원·리플레이 버전/호환을 먼저 확정한다. 해당 결정 전에는 제품의 고정 틱 검증을 완화할 근거가 없다.
3. 동결 후 독립 검토자는 각 실제 진입점의 동일 실효 설정 해시, 배속 1·2·4별 clock 궤적, 정지 중 clock 불변과 재개 연속성을 확인한다. tick 2와 terminal clock 150을 모두 비교하고, 200 치환이 실패하는지 확인한다. 원시 clock·결산을 비교하고 표시용 반올림은 관찰 판정에 쓰지 않는다. fixture 바인딩 부재는 `NOT_READY`, 동결 후 기대값 불일치는 `FAIL`로 기록한다.

이번 검토는 고정 SHA의 소스와 기존 근거를 읽어 진행했다. 코드 변경과 시험 재실행은 없었다.
