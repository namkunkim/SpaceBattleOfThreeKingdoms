# P02 표시용 사건 회수 이후 최신 인계

2026-11-08 KST. 독립 구현 재심에서 제한 private owner의 표시용 사건 회수 선행조건을 한정 수용했다. 전체 P02/I01/I01b/A04~A06 **NOT_READY**, 외부 save schema **UNCLASSIFIED**. 문서와 전달 ZIP의 독립 마감은 생성 시점에 대기 중이다. [결과](P02-VIEWER-EVENTS-RESULT-20261108.md) · [전용 체크리스트](P02-VIEWER-EVENTS-CHECKLIST-20261108.md)

- 새 메서드는 직렬 owner에서 정수 진영별 기존 안개 사건을 한 번 회수한다. raw/filtered는 같은 큐를 소비한다. raw와 observe가 남아 권한 보안 경계로 사용할 수 없다. 기본 17개, 신규 검사 14행·148개 단언, 격리 회귀 14개·탐침 3개를 분리해서 읽는다. 초기 반려, 이전 원경로 i01b 쓰기와 교정 전 진단도 결과와 보완 인계에 남겼다. [보완 인계](../../../tmp/p02-fourth-20261108/rebaseline-1/REBASELINE-NOTES.md)
- FleetBattle3D 제품 연결에는 후보 준비와 검증 뒤 게시, clock·초기 controls·배치/명령, 투영·사건, 선택·카메라·FX·trace 및 실패 시 기존 세션 보존의 공동 인수가 필요하다. WorldMap 진행·취소·join·BattleOutcome과 제품 replay, 외부 schema의 계약은 별도다. 다음 조각은 실제 소비자와 실패 경계를 좁히고 독립 계획 심사를 받는다. [P02 진행표](P02-PROGRESS-CHECKLIST.md)
