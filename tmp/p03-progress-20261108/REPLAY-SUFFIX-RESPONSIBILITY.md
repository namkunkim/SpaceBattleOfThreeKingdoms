# P03 fresh replay 소비와 운영 suffix 책임 대조

2026-11-08 KST. **읽기 조사.** [동결한 원문 15개](replay-audit-inputs.json) · [이전 명령 조사](../p03-state-checkpoint-20261105/COMMAND-AUDIT.md). P02는 실제 fresh replay CLI의 입력·실행·출력 및 viewer 필터를 소유한다. P03은 그 구현을 운영 Cn 저장·재개 책임에 대조한다. P02 최신 읽기 revision4는 자동결산 변환과 보존 감사의 독립 검토 중이다. 공통 private owner의 쓰기 소유권 인계는 확인되지 않았다.

| 구간 | 현재 동작·소유 | 운영 Cn에서 남은 책임 |
|---|---|---|
| 파일/입력 | P02 CLI `tests/autoresolve.gd:226–264`는 새 fresh replay 파일의 byte를 검증·파싱·SHA 계산한다. `operation_replay.gd:32–70`는 정확 필드, 유한 좌표, 정수 범위, 비감소 tick, 명령 내부 고유 ids와 whitelist를 검사하고 Vector2와 int로 변환한다. | 기존 파일의 재실행 identity와 별개로 checkpoint/동일 규칙·실효 설정/스키마 및 후속 입력의 연결 계약 필요 |
| 사전검증 | `operation_replay.gd:72–115`는 adapter로 fresh owner를 먼저 만들고 모든 입력 행의 구조·순서를 확인한 뒤 첫 queue로 들어간다. 구조적으로 정상인 command가 전술적으로 적용됐는지는 여기서 판정하지 않는다. | 운영 복원의 candidate 구성 실패 및 현재 활성 보존은 별도 인수. 새 envelope를 기존 packet으로 해석하지 않음 |
| enqueue | `operation_replay.gd:117–127`의 `consumed:int`는 해당 호출의 지역 변수다. 현재 요약 tick과 같은 행들을 배열 순서대로 `owner.queue`한다. `operation_private_state.gd:189–221`은 명령 검증/사본, `battle_sim.gd:95–96`은 queue append만 한다. | 수용된 예정 명령과 이미 적용된 prefix의 구분. 기존 packet pending과 외부 suffix가 겹칠 때 소유 책임 및 절단점 필요 |
| 적용/log/진행 | `battle_sim.gd:142–180`의 즉시 issue와 step 앞 queue 적용은 모두 현재 tick으로 log를 남긴다. 논리적 거부도 log 뒤 사건이 될 수 있다. `operation_replay.gd:128–131`은 `advance()` 성공 뒤 `consumed=next`로 처리 행의 끝 위치를 갱신한다. | 외부 정본 seq·applied cursor·commit과 예정 이벤트/재실행 경계는 미구현. log 길이, tick, replay 행 소비량에 대입 불가 |
| 사건 | `operation_replay.gd:132–138`은 consume 뒤 raw `drain_events()` 및 summary로 진행한다. `operation_private_state.gd:231–248`의 raw/filtered는 같은 파괴적 queue이고 `battle_sim.gd:424–448`의 filtered는 현재 contacts에 따라 삭제·마스킹한다. | 한 owner 안에서 어느 함수가 큐를 꺼냈는지와 외부 게시/효과 적용 확인을 분리. 복원으로 사건을 다시 받는 경우의 ack/dedup 정책은 별도 |
| 종료/실패 | `operation_replay.gd:119–142`는 over 또는 max tick에서 멈추고 미소비 행이 있으면 `replay_unconsumed_command`와 첫 미소비 행 path를 반환한다. `92–96`의 정상 반환형 성공·오류는 fresh owner를 닫는다. `tests/autoresolve.gd:260–268`은 오류를 출력 경로로 넘기지 않는다. | 이 fresh 결과 차단으로 이미 존재하는 운영 owner 복원 원자성이나 외부 소비/디스크/동시 writer 효과의 원자성을 추정할 수 없다 |
| 성공 DTO | `operation_replay.gd:82–90`의 `meta.commands_consumed`는 그 fresh 호출에서 처리한 입력 행의 최종 개수다. 코드가 별도 전역 seq, commit ID나 소비자 ack를 반환하지 않는다. | 운영 resume 포인터를 설정할 공개 계약이나 내구 원장 없음. 효과·결산·게시 커서와의 연동 필요 |
| in-memory packet | `operation_private_state.gd:14,272–294,316–375`의 제한 view는 command_log/_queue/_events를 보존하고 후보를 준비한다. 동일-context 활성 교체는 검사 후 sim을 넘기지만 Dictionary value metadata가 다른 후보 수용 문제는 남아 있다. | 실패 시 실제 host/worker/표시 및 외부 게시를 포함한 원자성, 모든 활성 모듈과 상태 책임, 동일 규칙 버전의 지원·거부 조건을 별도 검증 |

## 재사용할 반례와 아직 필요한 인수

1. **같은 tick의 issue와 queue.** Q를 먼저 접수한 뒤 I를 즉시 적용하면 checkpoint log에는 I, pending에는 Q가 있다. checkpoint 뒤 같은 tick의 B를 `tick>T`로 고르면 B가 유실되고 `>=T`로 고르면 I가 재실행된다. Q가 두 번 접수됐으면 내용 dedup도 잘못이다. [실제 P03 suffix](../p03-command-suffix-20261107/RESULT.md)
2. **입력 순서와 적용 결과.** P02 fresh 파일의 동일 틱 행 순서는 큐 적용 순서다. 전술 rejected가 나와도 그 행을 처리한 tick이 정상 반환되면 consume 수에 들어간다. 구조 거부의 선검증과 전술 거부를 구분한다. 운영 log의 순서만으로 외부 접수/커밋 순서를 재구성할 수 없다. [P02 fresh replay 결과](../../docs/battle-core/pc-campaign-design/P02-REPLAY-RESULT-20261108.md)
3. **종료 후 미소비.** 종료 다음에 예정된 행이 있으면 fresh replay는 미소비 오류를 반환한다. 운영 복원에서는 종료 tick과 실제 clock이 독립적이다. 검증된 fixture는 tick2/clock150이었다. 종료 경계의 예정 행을 어떻게 처리/보고할지는 저장·재개 계약에서 따로 판정해야 한다. [P03 종료 경계](../p03-terminal-boundary-20261108/RESULT.md)
4. **raw/filtered drain.** 필터 소비 전 A를 복원하면 raw 숨김 사건까지 되살아나고, 필터 소비 후 같은 tick B에서는 raw/표시가 모두 빈다. 두 packet의 tick이 같아도 소비 경계가 다르며 외부 UI가 이미 보았는지나 자원 지급이 끝났는지는 이 값으로 판단할 수 없다. [P03 viewer 경계](../p03-viewer-checkpoint-20261108/RESULT.md)

H2-02는 현재 상태+이후 명령 및 초기 동일 규칙 재개 방향을 채택한다. D04 ST02/ST18과 §4는 시계·커밋·적용 cursor와 처리/효과/게시의 책임을 구분한다. I01 K05~08의 명령 seq·commit seq는 권고이고 A06은 seq1/2 반영·seq3 대기/후속의 한 번 적용과 active 보존을 요구한다. 그 번호와 표현을 현 구현에 소급하거나 새 스키마로 확정하지 않는다. 필요한 다음 공동 인수는 **접수/적용/완료의 권위, pending과 suffix의 절단점, 외부 사건/효과 소비 확인, 실패 시 기존 host 유지**다. Dictionary exact 문제의 공통 owner 변경은 별도 소유와 심사에 따른다. 전체 P03/I01/I01b/A04~A06 NOT_READY, O07 OPEN, 외부 save schema UNCLASSIFIED. [H2](../../docs/battle-core/pc-campaign-design/H2-DECISION.md) · [D04](../../docs/battle-core/pc-campaign-design/D04-STATE.md) · [I01 준비](../../docs/battle-core/pc-campaign-design/I01-READINESS-DECISION-20261026.md) · [I01 사전등록](../../docs/battle-core/pc-campaign-design/I01-ACCEPTANCE-PREREG-20261026.md)
