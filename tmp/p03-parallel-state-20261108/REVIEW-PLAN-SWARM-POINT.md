# Swarm 점 숫자 타입 계획 독립 심사

판정: **PASS — 첫 점 r의 float→int 단일 변이 사례에 한함**. 심사 계획 SHA256은 `9db2257a8b599872a0e0a2a67bb2d48c8433ed7b4884a454665cc846754746a9`이다.

- 원문 `_launch_fighters`는 event ID 하나를 Swarm ID로 쓰고 `pos,a,r,w` 순서로 점을 만들며 POC 값은 점 22개, life 9050, r 기초 20 및 추가 범위 50이다. `_move_swarms`는 하위 걸음마다 life를 50ms 줄이고 각도에 w×dt를 더하므로 한 틱 후 life 8950과 두 번의 각도 갱신 기대가 부합한다.
- 단일 경로와 타입 차이, 구조 통과 후 정확 `swarm_point_number`, 기존 객체·첫 점·warm cache·packet 보존을 분리해 확인하고, 원본 양성 복원의 새 객체·논리 ID 연결과 다음 틱의 세 capture를 대조한다. 개별 RNG 및 위치 수치를 독립 oracle로 과장하지 않는 범위도 명시돼 있다.
- canonical outer script 상수와 중첩 Swarm script의 identity, 실제 raw path 보존은 승인된 Missile guard의 원리와 같다. runner, 실제 두 종료/marker·Job 및 전후 동결은 별도 사후 5b가 확인해야 한다. 타입 실패 대조는 검사기가 실제 비정상 종료하는지 입증해야 한다.

실제 플레이 발진, 피해, 다른 점·참조 변이 및 운영 복원은 범위 밖이다. PASS는 실행 성공이나 전체 Swarm 안전성을 의미하지 않으며 P03 NOT_READY 등 기존 상태를 유지한다. 최신 rollout turn_context `01a1ba7c-e66e-7962-9de0-dc83dfdb662f`의 모델은 `gpt-6.1-terra`다.
