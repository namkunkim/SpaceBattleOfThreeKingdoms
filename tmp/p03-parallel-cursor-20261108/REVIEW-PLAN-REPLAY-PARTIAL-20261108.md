# P03 fresh replay 부분 처리 경계 독립 계획 심사

2026-11-08. **변경 요청.** 계획 심사 통과 전 runner·fixture·검사 코드를 작성하지 않는다.

심사 담당은 `/root/p03_review`이며, 사용자가 인정한 배정 근거는 `spawn_agent`의 명시적 `gpt-6.1-sol` 지정과 구현 담당과 별개인 에이전트 ID다. 실제 서빙 모델은 별도 검증하지 못했다. 이 심사에서 구현하거나 엔진을 실행하지 않았다.

## 독립 대조

- `워크플로우-플레이북.md` §2–3의 독립 5-b와 조각별 재시도, `CLAUDE.md`의 별도 모델·공유 폴더 규칙, `docs/battle-core/SESSION-HANDOFF.md`, P03 개정 체크리스트와 인계를 대조했다. 상위 경로, 저장소 루트, `tmp` 및 전용 폴더에서 적용할 `AGENTS.md`를 발견하지 못했다.
- H2-02, D04 ST02·ST18·T02, I01 K05–K08과 A06을 원문과 대조했다. fresh owner의 로컬 처리량, 내부 사건 소거와 운영 커서·저장·효과·게시 책임을 구분한 범위가 맞다. P03/I01/I01b/A04–A06은 NOT_READY, O07은 OPEN, 외부 저장 스키마는 UNCLASSIFIED다.
- `operation_replay.gd`의 행 검증은 명령 전진 전에 끝난다. 그 뒤 tick별 enqueue→advance→내부 consumed 갱신→raw drain→summary 순서이며, 남은 명령의 첫 index를 오류로 돌려준다. 선행 A를 처리하고 두 번째 정상 행 B에서 오류가 나는 관측, 같은 자리의 구조 오류로 A까지 실행되지 않는 대조, A 단독 oracle은 서로 다른 경로다. 기존 P02는 late의 `commands[0].tick` 및 close, order 오류, 자연 종료와 cap을 검사한다. 기존 P03 suffix attempt-05는 복원과 후속 재실행을 검사했다. 이번 차별성을 수용한다.
- 현재 HEAD `fb660cea69207fd332e26128643007694910a253`는 시작값과 같고 동결 입력 19개 SHA-256은 재계산 결과 전부 일치했다. 시작 status는 긴 경로 경고로 불완전하다. 전후 동결과 비교, P02 dirty 별도 보존, 외부 입력 drift 때 중단, 기존 로그 보존과 코드 K=6, 환경·사용량 제한 즉시 보고 및 반복 금지, Job timeout 124와 실제 종료 확인을 수용한다. 새 실행의 보존은 별도 5-b에서 확인한다.

## 수정 후 재심사할 항목

1. 기존 P02의 실제 `tmp/p02-third-20261108/matrix/natural.json`, `matrix/late.json`과 `oracle.native` 또는 원래 oracle 생성 근거를 명시하고 해당 입력 해시를 동결한다. 종료 시점 E의 의미를 다음 loop의 summary.tick 및 end_tick/clock으로 구분하고, F와 max_ticks를 사전 등록한다. A는 실제 대상과 예상 log payload를 정하고 A를 넣은 독립 oracle에서도 자연 종료, `E < F < max_ticks`, `over=true` 및 terminal event를 요구한다. 전제 미충족은 실패로 남겨 스펙을 재심사한다.
2. 검사 4개의 고정 단언 분모를 각각 명시하고 합계를 등록한다. 실패, 선행 조건 미충족, 중간 중단, 검사의 누락·중복 및 단언 수 불일치가 있으면 runner가 비정상 종료하도록 명시한다. 엔진이 예외 등으로 이 경로를 건너뛰어도 외부 게이트가 exit·분모·명명 결과·진단으로 실패 처리해야 한다.
3. `_play_and_close`는 공개 `run`이 사용하는 내부 helper다. 네 번째 시나리오를 helper 정리와 오류 반환으로 명명하고 범위를 한정한다. 공개 계약까지 주장하려면 같은 A/B envelope를 `Replay.run`에 별도로 넣고 error DTO를 정확히 비교하는 단언을 사전등록한다.
