# 제한 owner 공개 복원 집계 수정 계획

사용자가 앞선 16 대 17 집계 오류의 수정을 승인했다. 부모가 이 계획 turn의 실제 모델을 rollout에서 확인했다. 2026-11-08T09:03:22Z, gpt-6.1-sol. 구현 turn에서 최신 rollout turn_context를 다시 확인한다. 모델 확인 불가, Astra 또는 사용량 제한이면 중단한다.

attempt-03은 원문에서 17개 단언 모두 true, 진단 0이었고 실제 exit 1이었다. 프로브 및 게이트의 기대 개수 16이 실패 원인이다. 이 조각은 결과 집계만 수정한다. 프로브의 fixture, 공개 호출, 시점, 상태 비교와 대조군은 앞선 심사 범위를 따른다. 공유 소스나 정책은 이 조각의 범위 밖이다.

## 수정과 인수 조건

- [ ] Terra 독립 계획 수용 후 전용 경로의 probe 집계와 gate만 수정한다. 프로브는 17개 단언이 모두 성공할 때만 성공 코드를 반환한다. Python 게이트는 아래 정확한 이름 집합과 각 true 값을 검사한다. 정적 대조에서 코드에 있는 단언 라벨과 아래 집합이 정확히 일치해야 한다.
- [ ] 기존 attempt-01~03 디렉터리의 모든 파일을 바이트로 동결해 재개 전후 SHA를 비교한다. 새 실행 증거는 전용 `cycle-02/attempt-NN/`에 배치한다. 전용 경로만 쓴다.
- [ ] 새 실행 전후 이전 PLAN-INPUT-SHA 기준선 및 HEAD 일치를 확인한다. 새 승인 계획·심사·probe·gate의 SHA를 실행 분모에 추가한다. 기존과 동일한 longpaths 옵션의 status를 비교해 동시 작업 표시를 기록한다.
- [ ] 새 5-a는 최대 총 3회이며 이전 시도와 같은 엔진·30초 제한을 사용한다. 실제 exit 0, 단일 결과, 정확한 단언 17개 모두 true, 진단 0, 남은 job 프로세스 0, 입력 전후 SHA 일치 및 HEAD 일치를 요구한다. 실행별 원문·probe 사본·argv·엔진 버전·실제 exit·입력 SHA를 보존한다. 게이트를 통과하면 재실행을 중단한다.
- [ ] 5-b는 구현에 참여하지 않은 Terra 심사자가 원문과 실측 결과를 검사한다. 집계 분모와 집합, 이전 실패 보존, 새 성공 실행의 원래 행동 조건, 범위 한계 및 SHA를 대조한다. 독립 수용 후 결과·인계·closeout을 기록한다.

기대 단언 집합은 attempt-03의 원문에 보고된 아래 이름이다.

```text
candidate_bytes_preserved
canonical_classes
entire_public_capture_preserved
exact_public_refusal
fixture_active_with_pending_and_events
fixture_public_actions
fixture_public_capture
immediate_logged_before_pending
ordered_events_drained_with_original_prefix
owner_and_sim_identity_ready_idle
pending_logged_exactly_once_in_order
positive_capture_and_advance
positive_restore_exact_on_separate_owner
scenario_only_packet_delta
second_drain_empty
three_distinct_owners
tick_pending_and_ordered_events_preserved
```

범위는 제한 owner에서 지원되지 않는 scenario를 포함한 패킷 거부와 후속 진행이다. 제품 호스트 연결, 운영 복원 정책, 활성 DecisionBoard 강제 주입 반례, UI 게시 및 외부 효과 원자성은 미해결이다. P03/I01/I01b/A04~A06 NOT_READY, O07 OPEN, 외부 저장 스키마 UNCLASSIFIED.
