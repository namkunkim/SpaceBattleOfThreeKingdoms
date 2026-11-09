# P03 지원 밖 활성 모듈 독립 closeout

2026-11-08. **제한 관측·패키지 수용**. 실행 gpt-6.1-sol / 심사 gpt-6.1-terra는 spawn 명시 배정이며 실제 내부 런타임 모델 확인이 아니다. 심사자는 구현·패키지 작성에 참여하지 않았다.

감사 분모는 각 실행의 동결 입력45개와 refs/index이며 dirty 전체 전후 보존을 주장하지 않는다. attempt-01 이후 runner만 바뀌었고 당시 snapshot이 보존됐으며 attempt-02 입력 SHA는 독립 5-b에서 재계산 일치했다. ZIP 35226 bytes, SHA-256 `197c317801f73b0af6753f0247c103b05a1907f961695c2366f6a501c17f75f2`, 31 entries, CRC/중복0, 내외 manifest 및 payload30 SHA·디스크 바이트 불일치0. 독립 심사는 패키지 밖이다. 기존 전체 diff-check exit2와 전용 새 파일 검사는 별도다.

강제로 붙인 DecisionBoard에 capture는 거부했지만 동일 context restore가 성공해 새 sim에서 모듈을 잃은 실제 관측은 유지한다. 자연 제품 경로 도달·정책/host 원자성은 미입증이다. 전체 P03/I01/I01b/A04~06 NOT_READY, O07 OPEN, 외부 save schema UNCLASSIFIED 및 기존 미해결 계약 유지.
