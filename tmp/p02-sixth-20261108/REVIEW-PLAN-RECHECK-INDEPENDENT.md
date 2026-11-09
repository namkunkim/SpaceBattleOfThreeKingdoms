# P02 여섯째 조각 독립 계획 재심

판정: **수정 후 재심**. 대상 `PLAN.md` SHA-256 `1c7909b6ed929286fa33ff86c5a162785a52831a1661c04405d84db73271fbd2`를 확인했다. 이전 보류 기록은 유지한다. 이 실행의 실제 모델 ID는 도구 메타데이터로 독립 확인할 수 없어 확인 불가다.

## 차단 사항

1. **실제 호출자의 실패 후 동작이 원자성 주장과 맞지 않는다.** `hud/ui_kit/command_deck.gd:260`의 `begin_battle`, `restart`, `to_title`은 `init_game()` 뒤 반환을 검사하지 않고 `_clear_log`, `_start`, 화면 전환 등을 실행한다. `begin_battle`은 그 전에 `battle.org`도 바꾸며, `hud/ui_kit/org_screen.gd:165`는 `b.org`를 먼저 바꾼다. `scripts/FleetBattle3D.gd:148`의 `_ready`와 `:295`의 `_restart`도 결과를 무시한다. 계획의 두 실패 시험은 직접 `init_game`만 호출하므로 실제 호출자에 의해 기존 UI/선택/로그/편성이 보존되는지를 입증하지 못한다. 실패가 측정용 patch에서만 발생한다는 제한은 실제 caller가 patch 상태에서 호출될 수 있다는 반례를 없애지 않는다. **선택:** 실제 caller가 실패를 전파하고 후속 변경을 중단하도록 범위와 각 실패 사례를 확장하거나, 이번 인수를 명시적으로 `init_game` 함수 내부의 직접 호출 경계로 축소하고 UI caller 경유 실패 원자성·입력 org 변경·실제 제품 호스트 전체 보존은 미인수로 남겨라. 후자라면 계획의 의도와 완료 문구도 같은 한계로 고쳐야 한다. UI caller 실패를 검사하지 않고 전체 호스트 실패 원자성으로 표현하면 안 된다.
2. **사후 회복 및 독립 비교의 관측 기준을 구체화해야 한다.** `recover_publish_once`의 “한 번 게시”는 어떤 관찰로 계수할지, trace 파일 `session_closed/session_start`, 기존 FleetView 제거와 새 생성, 기존 이벤트 폐기, `_sync` 및 HUD 갱신 중 어느 것을 세는지 명시되지 않았다. `BattleTrace.start`는 기존 파일에 close 기록을 쓰고 새 파일을 여는 외부 효과다. 정상 복구에서 기존 trace에 close 1개와 새 trace에 start 1개, 실패에서 파일 바이트/핸들 및 sequence 불변 등 독립 관측을 구체화하고, 시스템 시각·임시 경로만 정규화하라. 비교 대상은 동등한 독립 native 초기화 및 사전 기록된 구체 값으로 고정해야 한다.

## 확인된 범위와 필수 조건

- 제품 코드는 `init_game` 진입 즉시 3D 함대 제거, `vm.reset`, `placing=false`, `fx.clear` 후 seed와 프로필을 준비한다. 제안한 준비/게시 분리는 해당 직접 호출의 두 명시적 profile patch 실패에 유효한 목표다. 실제 `profile_patch`는 반환값이 아니라 프로필을 제자리 수정한다. 후보 검사 전 `BattleSim.new`, roster map/filter가 실행되지 않는지 검증해야 한다.
- `FleetBattle3D._process`는 TickClock, 배치 정지, 보간 및 `_pump`를 소유하며 `_pump`는 side 0 projection과 filtered drain/trace를 사용한다. raw drain과 viewer drain은 공유 큐다. 계획의 시계·동틱 명령·사건 시험은 유지하고, 사건 fixture가 실제 발생했음을 단언해야 한다. 빈 사건끼리의 비교는 충분하지 않다.
- owner의 `_profile_error`는 증원, scenario, AI와 여러 전투 모듈을 거부한다. 계획의 실제 적벽 첫 거절만 진단하고 나머지 검사 성공으로 추론하지 않는 제한은 적절하다. WorldMap의 legacy `start/poll/cancel` 및 `BattleOutcome`과 operation worker summary/events는 별개로 유지한다.
- `baseline.json`의 19,365개 주장 자체는 파일 존재만 확인했으며 전수 해시를 재계산하지 않았다. 구현 전·실행 전후·마감 전 전체 경로 목록/바이트 및 index를 비교하고 P03 또는 기타 미귀속 차이를 덮어쓰지 않으며 실행 입력·허용 hunk 충돌 시 보류해야 한다. 사전 캡처와 결과 비교는 격리 전후 프로젝트에서 클래스 실제 경로, 자원 해시, 개별 user 데이터 및 고정 returning fixture를 확인해야 한다.
- `tests/organization_ui.gd`는 실제 편성 오류/복구와 `init_game`을 여러 번 호출한다. 계획의 `battle_flow`와 `world_link` 외에 이 기존 회귀를 사전/사후 정본으로 포함하거나, 그것과 동등한 실제 org 화면 복구 및 각 caller 테스트를 명시하고 기존 테스트를 뺀 이유를 기록해야 한다. 4/5 프로세스 숫자는 변경 시 분모를 명시하고 계획 재심을 거친다.
- 측정 콜백 자체의 부작용, 전역 RNG 소비, 엔진 예외 및 게시 중 노드/GPU 오류는 계획상 보장 밖이다. 특히 unrouted `randi()`는 실패 시에도 전역 RNG를 소비하므로 RNG를 포함한 완전한 실패 불변이라고 주장하지 않는다. 수동 GUI, Android, 성능, 실제 operation 연결 및 외부 저장 schema도 미인수다.

5-b는 구현자와 별개 심사자가 사전 관측과 실제 diff 및 반례를 검증해야 하며, 계획 수정 후 본 판정을 자동 승인으로 간주하지 않는다.
