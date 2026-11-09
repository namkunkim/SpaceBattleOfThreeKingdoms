# P03 Dictionary context 수정 전 관측 결과

2026-11-08 KST. **Dictionary value metadata가 다른 6개 중 6개가 계약 MISMATCH다.** 현재 private owner는 value builtin(int↔Variant), native class(Node↔RefCounted), Script identity(FleetState↔BattleState)의 차이를 모두 양방향에서 수용했다. 실제 키·순서·key metadata 및 나머지 context를 같게 두고, 유일 metadata 차이가 정상 create/capture/prepare를 통과함을 확인했다. 각 성공에서 동일 owner handle에 새 sim이 들어갔고 원 owner context와 packet은 보존됐다. 6개 중 1개는 기존 단방향 재현, 5개는 새 분모다. [독립 5-b](REVIEW-5B-before.md)

정본 attempt-01 actual Godot exit0은 **현행 관측 절차의 완료**다. 명명5·논리입력13·188 단언, 동일 typed context 성공 1과 기존 거부 controls 6, value MISMATCH 6을 따로 기록한다. 실제 console/본체, 정본 class map 및 입력46 전후 SHA 동일, 엔진 오류/경고/누수0이다. 공유 owner 변경 및 after 검증은 미실행이다. [실행 원문](attempt-01/run.json)

원 dirty/untracked 16717 재해시에서 누락0/변경0, 실행 입력46 drift0이다. P02 새 경로 34를 따로 분리했고 status 전후 달라 원자 스냅샷으로 표현하지 않는다. 기존 P2c diff-check actual exit2와 신규 전용 파일 검사도 분리했다. [보존](preservation.json)

다음 단계는 소유 계약을 명시적으로 정리한 후 최소 비교 수정 및 after conformance다. 전체 P03/I01/I01b/A04~A06은 NOT_READY, O07 OPEN, 외부 save schema UNCLASSIFIED다.
