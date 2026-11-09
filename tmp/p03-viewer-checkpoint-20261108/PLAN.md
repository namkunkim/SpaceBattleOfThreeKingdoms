# P03 다음 후보 — 표시용 사건 회수 전후의 packet

2026-11-08 KST. **독립 계획 심사 대기, 코드/Godot 미착수, 새 K6=0.** Sol 실행, Terra 독립 심사 명시 배정. Astra 제외.

P02 viewer-events는 안개에서 `drain_events_for(side)`가 같은 raw queue를 파괴적으로 회수하며 가려진 사건도 소진함을 인수했다. 기존 P03 suffix는 raw queue의 restore를 검증했다. 이 후보는 두 경계의 접합을 한정한다. **표시용 소비 전 packet은 원 raw queue를 복원하고, 표시용 소비 후 packet은 숨긴 사건까지 소진된 상태를 복원해야 한다.** 이는 packet 시점의 인메모리 상태이며 외부 게시/소비자의 ack·dedup 계약은 별도다. [P02 viewer 결과](../../docs/battle-core/pc-campaign-design/P02-VIEWER-EVENTS-RESULT-20261108.md) · [P03 suffix](../p03-command-suffix-20261107/RESULT.md)

P02 공통 owner/adapter/host/replay와 공유 체크리스트를 수정하지 않는다. 새 전용 폴더만 쓰고, P02 서비스 fixture를 읽기 입력으로 사용할 경우 원본 SHA를 동결한다. 새 테스트는 `Private.create`에 typed 제한 profile을 직접 전달해 P02의 CLI normalize와 자동결산 결과에 의존하지 않는다. P02 제품 자동결산 작업의 현재 소유는 별도다. [P02 계획](../p02-fifth-20261108/PLAN-V3.md)

독립 raw BattleSim은 packet과 owner drain 메서드를 호출하지 않는다. P02 viewer의 far 제한 services fixture를 바탕으로 직접 typed roster/config를 만들고 양쪽 stop과 실제 advance로 서로 다른 진영의 식별 가능한 사건과 비대칭 visibility를 만든다. P02 fixture의 재현 조건을 읽고 정확한 raw/filtered 수치와 가려질 사건 ID를 런 전 고정한다. 최소 guard는 실제 raw queue에 숨겨질 사건이 적어도 한 개, 양쪽 filtered 결과가 서로 다르며 raw와 같지 않은 상태다. 계획한 guard가 성립하지 않으면 fixture 변경을 숨기지 않고 명시 실패로 남긴다.

| 이름 | 독립 성공 조건 |
|---|---|
| viewer_cut_01_capture_nonempty_and_filter | live 전진 후 raw queue/contacts exact 및 숨김 사건 전제. 소비 전 packet A capture, side0 filtered 결과를 별도 native core oracle과 수기 visible/hidden ID로 대조. 이어 raw/side1 drain 비어 있음 |
| viewer_cut_02_restore_preconsume_raw | 실제 side0 소비와 추가 advance 이후 같은 owner에 A 복원. active checkpoint state/contacts/queue와 bindings exact. raw drain이 필터 전에 있던 숨김 사건까지 원 순서·타입으로 반환. 즉시 두 번째 drain 빈값 |
| viewer_cut_03_restore_preconsume_other_side | 같은 A에서 복원한 fresh sim에 side1 drain. 독립 native side1과 exact 및 side0 결과와 차이 확인. A는 소비/복원 중 변하지 않음 |
| viewer_cut_04_restore_postconsume_empty | side0 소비 후 capture한 B를 A의 nonempty 상태에 복원. raw/양쪽 filtered 모두 빈값, contacts/clock과 B는 exact. 외부 효과 ack는 구현하지 않음 |

정확성은 Variant 타입, Dictionary key 타입·삽입순서, Array typed metadata 및 순서, object Script/참조, raw event와 공개 결과 분리로 비교한다. P02 기존 side filter matrix나 P03 raw suffix를 이 신규 조합의 실행 분모로 세지 않는다. 새 4명명/1 fixture, 실제 assertion은 별도 보고한다. 실행 전 새 dirty 분모·branch/HEAD/index, 실제 engine console/본체 SHA 및 runtime PID/경로, 전용 Job, 정본 cache/Script guard, fixture·전이 입력 SHA 직전/직후 및 actual exit/diagnostics를 동결한다. 새 K6, 독립 계획 수용 전 실행 금지, 사용량 제한 즉시 보고·반복 금지. 전체 P03/I01/I01b/A04~A06 NOT_READY, O07 OPEN, 외부 스키마 UNCLASSIFIED. Dictionary metadata 격차와 shared 소유 의존성은 [별도 계획](../p03-dictionary-context-fix-20261108/PLAN.md)을 따른다.
