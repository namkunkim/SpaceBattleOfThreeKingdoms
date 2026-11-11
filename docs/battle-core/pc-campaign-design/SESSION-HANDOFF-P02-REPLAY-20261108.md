# P02 제한 fresh replay 이후 최신 인계

2026-11-08 KST. 기존 운용 CLI의 새 제한 fresh replay 소비자는 구현 독립 5-b에서 한정 수용됐다. 전체 P02/I01/I01b/A04~A06 **NOT_READY**, 외부 save schema **UNCLASSIFIED**. 문서와 ZIP의 독립 마감은 별도 상태다. [결과](P02-REPLAY-RESULT-20261108.md) · [전용 체크리스트](P02-REPLAY-CHECKLIST-20261108.md) · [P02 진행표](P02-PROGRESS-CHECKLIST.md)

- 기존 CLI에 `--operation-replay`를 추가했다. 재생 모듈은 owner 한 개에서 검증된 명령을 순서대로 큐에 넣고 종료하거나 제한에 도달하면 닫는다. 새 결과 파일의 raw 입력 SHA와 동일 파일 반복 실행 SHA를 검증했다. [코드](../../../core/battle/operation_replay.gd) · [입력 예제](../../../tests/fixtures/p02/replay-commands.json)
- 2/K6의 74/75와 3/K6 BattleFlow 단일 재실행을 합쳐 75사례가 통과했다. 1·2차의 실패 판정과 원문, 기존 종료 진단, 세 legacy 옵션의 분류 편차, 기존 전체 diff-check exit 2는 그대로 기록했다. [5-a 기록](../../../tmp/p02-third-20261108/IMPLEMENTATION-5A-NOTES.md) · [구현 5-b](../../../tmp/p02-third-20261108/REVIEW-5B-INDEPENDENT.md)
- 다음 조각의 독립 계획에서 실제 제품 소비자와 종료·실패 경계를 확정한다. FleetBattle3D/UI, WorldMap 진행·결산, 제품 replay와 legacy trace, checkpoint/cursor, 외부 save, Android·성능의 검증 범위는 진행표를 따른다. [P02 진행표](P02-PROGRESS-CHECKLIST.md)
