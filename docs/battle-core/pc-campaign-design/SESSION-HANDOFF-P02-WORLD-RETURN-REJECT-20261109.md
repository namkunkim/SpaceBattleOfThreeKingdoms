# P02 전장 → 천하 전환 거절 복구 인계

한정 수용 범위는 기존 `WorldLink.back_to_world`의 즉시 로더 거절이다. `scripts/world_link.gd` 적용 SHA-256은 `42f98746255011935166770bfd070ed60218a227f6051a166adaa3b6353bbb56`이다. 브랜치 `codex/feature-i01b-not_remove`, HEAD `0be09755`, staged 비어 있음. 최초 복귀 후보의 한 함수만 적용했고 기존 출격 및 WorldMap 변경을 보존했다.

격리 시도 2/6. 1회차 준비 fixture 오류와 2회차 20개 실행·210개 단언은 별도 기록을 사용한다. 실제 전환 거절, 같은 전장과 버튼의 재시도, 결과 일회 소비 및 결과 없는 복귀를 격리에서 확인했다. 원본 적용 뒤 Godot은 실행하지 않았다. [결과](P02-WORLD-RETURN-REJECT-RESULT-20261109.md) · [체크리스트](P02-WORLD-RETURN-REJECT-CHECKLIST-20261109.md) · [독립 적용 확인](../../../tmp/p02-pc-next2-20261109/REVIEW-POST-APPLY-INDEPENDENT.md)

사용자 우선순위는 첫 PC 플레이 → 같은 규칙 버전 저장·재개 → 후속 검증이다. PC0 2/2 소진 및 여덟째 K6 미실행을 유지한다. 프로그램 신호로 누른 기존 버튼, 강제 종료 fixture와 개발 경고를 실제 OS 입력·자연 종료·사용자용 안내 근거로 쓰지 않는다. 적벽 제품 operation, P03 복원 및 P05/P07 제품 연결, 외부 저장 스키마 판정은 해당 정본에서 별도로 추적한다.
