# P02 세 번째 조각 독립 계획 리뷰

2026-11-08. **한정 수용.** 심사 대상 PLAN.md SHA-256 `4fe0b4d9137934ecba7d08401fa116ecf138ddc83dbca4db2d1ffc05ce122f9e`. 구현 전 계획에 한한 판정이며 실제 구현·게이트·제품 통합의 수용이 아니다.

- 실제 소비 경로를 대조했다. `view/world/world_map_screen.gd`의 legacy AutoResolver는 BattleBrief와 BattleOutcome 및 진행값에 결합되어 있고, operation worker 호출은 기존 CLI에 있다. `BattleSim.replay`의 검색된 기존 호출자는 테스트다. 계획은 신규 CLI replay 소비자라고 정확히 한정하며 제품 host/WorldMap 연결을 주장하지 않는다. 이 조각은 공통 adapter/private owner를 새 명령 재생 소비자에서 쓰는 제한적 진전이다.
- 공통 factory를 한 번 사용하고 지원 밖 입력은 거부한다. 자연종료 뒤 남는 명령은 실패하고 성공 파일을 만들지 않는 계약, 명령 정렬·동틱 순서·tick 범위 및 native 전술 거부 구별은 적절하다. 기존 replay와 차이나는 초기 controls, 자연종료 stop, events는 별도 native oracle로 판정한다. 특히 원본 `BattleSim.replay`는 이벤트를 매 틱 버리고 지정 틱까지 실행하므로 전체 동등성이라고 넓히면 안 된다.
- 독립 oracle은 새 변환기/runner를 기대값에 재사용하지 않으며, 동틱 역순과 명령 제거가 실제 관측을 바꾸는 반례를 구현 전에 고정하도록 요구한다. 이것이 실패하면 테스트를 통과로 처리하지 말고 스펙/fixture를 재검토해야 한다. native 타입 대조와 실제 CLI process 실패/출력 보존을 별도로 요구한다.
- 기존 legacy, sync, worker 전후 바이트·기존 UI/clock/thread 및 WorldLink 회귀는 유지 대상으로 명시된다. 새 owner는 단일 스레드, close 1회이며 worker join이나 제품 화면 진행값을 확장하지 않는다. K6, baseline 및 실행 전후 해시, 기존 diff-check 실패와 P03 동시변경의 분리 기록은 계획에 있다.
- 조건: 구현 직전 baseline drift 및 동시 P03 변경을 확인하고, 재생 완료·오류의 모든 정상 제어 경로에서 owner close와 출력 부재를 실제로 입증할 것. source·oracle·fixture의 실행 전 동결과 후속 drift 확인, 실제 event 순서/타입 및 마지막 틱·미적용 명령 검증을 생략하지 말 것. OS 동시 writer·disk 장애·강제종료는 계약 밖이며 no-clobber를 그 이상으로 주장하지 않는다.

제품 replay, UI, BattleOutcome, checkpoint/cursor 및 외부 save는 미검증·미완료다. 구현 결과는 별도 독립 5-b를 거쳐야 한다. 이 판정은 커밋·병합·배포 승인이 아니다.
