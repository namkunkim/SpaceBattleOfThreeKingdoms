# P2c 1~3 보완 계획: 비어 있는 함대 진형 거부

2026-11-01 KST / 독립 5b 반례에 따른 2단계 복귀. 독립 계획 수용 전 구현하지 않는다.

## 1 의도와 확인 사실

현재 제한 private runtime 복원 구성요소의 범위와 기존 NOT_READY를 유지하고, 정상 capture가 만들 수 없는 빈 `fleet.form`이 게시되는 결함만 고친다. 외부 save schema, 수치·정책·지원 모듈·명령 subset을 추가하지 않는다.

`BattleSim._spawn`는 `BattleRules.formation_offsets`로 실제 진형 좌표를 만든다. 기존 `rules.gd:118 ship_pos`는 `form[i % form.size()]`를 사용한다. `_rand_ship`→`_fire_missiles`→`_cmd_weapon`→공개 owner.issue(missile) 경로가 이 소비자에 도달한다. 따라서 empty form은 정상 런타임 복원 상태로 허용할 수 없다. `form_t`와 route의 빈 값은 기존 정상 의미가 있으므로 같은 제약을 확대하지 않는다. form의 좌표 수·형태를 새 상수로 고정하지 않고 최소 분모 조건만 검증한다.

별도 probe1은 stock JSON 편성 float 때문에 `fleet_definition_type` exit1로 반례에 도달하지 않았다. 정수 편성의 probe2는 정상 packet prepare 성공 후 form.clear() packet도 prepare 성공하고, 공개 missile 명령에서 Modulo by zero SCRIPT ERROR 6회와 issue ok=true를 재현했다. probe2 exit0은 절차 종료이며 수용 PASS가 아니다. 두 probe의 원문/엔진 로그와 exit JSON을 보존한다. editor import는 실행하지 않았고 원본 생산·검사 코드는 미수정이다. 주 runner는 attempt4/K6 상태이며 별도 진단 probe는 2회다.

## 2 수용 기준

- `operation_private_state.gd`의 `_restore`가 정확한 기존 typed Array와 Vector2 요소 검사를 유지하면서 빈 `fleet.form`을 명명 오류로 거부한다. 유효한 비어 있지 않은 typed form은 값·순서·타입을 바꾸지 않는다.
- 거부된 packet은 deep 원값/타입/순서가 유지되고 source 및 정상 prepare로 만들어 이미 존재하는 성공 owner의 독립 oracle은 전후 불변이다. 새 owner를 반환하지 않는다. private target는 기존 실패 정리 경로로 닫힌다.
- `tests/i01b_private_state.gd`에 `empty_form_first`와 `empty_form_last` 두 named negative를 기존 거부/무변이 검사 경로에 추가한다. 각각 첫 함대와 마지막 함대의 form.clear()를 변조하며 둘 다 예상 오류 `fleet_empty_form`를 명시 검사한다. 마지막 항목 검증 실패도 packet/source/기존 성공 owner를 바꾸지 않음을 보인다. 정상 form 존재/typed metadata 보존과 missile suffix 실행은 기존 70사례의 별도 oracle·projectile 활성 검사로 유지한다. 이름 수 완결 guard는 추가된 실제 두 사례를 반영하여 43→45로 올리며 기존 이름/allowlist/skip을 줄이거나 완화하지 않는다.
- 정상 70사례와 모든 기존 43개 거부가 그대로 실행되고 신규 첫/마지막 empty form 두 거부까지 명시적으로 관측된다. main runner attempt5가 실제 exit0, SCRIPT ERROR/ERROR/종료 누수0이며 새 코드·입력·cache·engine SHA를 실행 전에 동결한다. 신규 본 검사 OUT은 `res://tmp/i01b-p2c-resume-20261101/attempt5-observations.json`으로 변경하여 기존 observations.json과 attempt4 증거를 덮어쓰지 않는다.
- 코드 변경 후 `data_rules`와 `core_rules`, 그리고 직접 선행 helper인 `i01b_service_state`만 관련 회귀로 재실행한다. service 검사는 기존 검증된 OUT-only 복사본을 사용하고 예전 관측을 덮지 않도록 새 OUT-only 복사본과 역치환 SHA 증거를 남긴다. 다른 4종 정본 회귀는 선행 소스·입력 SHA 불변 증거로 유지한다. 독립 심사가 추가 소비자 위험을 지적하면 그 검사만 추가한다.
- 3660 baseline·35 source·77격리 보존 및 문서 허용 차이를 다시 감사한다. main runner K6 중 attempt5 사용 예정, 실패 시 남은 attempt6까지만 허용한다. probe는 주 runner 횟수에 합산하지 않되 숨기지 않는다.

## 3 분해와 소유 경로

1. 독립 검토자가 본 보완 계획을 수용한다. 반려는 2단계로 돌아간다.
2. 실행 담당이 신규 소유 helper와 신규 검사에 최소 hunk만 적용한다. 기존 core/P2b/data/HTML/다른 작업 파일은 수정하지 않는다.
3. attempt5 스냅샷·SHA 동결 → 주 runner → 직접 관련 최소 회귀 → 보존/결과 manifest를 만든다. Godot는 `--headless --script`만 사용하며 editor import를 하지 않는다.
4. 구현 비참여 다른 모델이 수정 diff·반례 해결·전체 기존 증거를 최종 5b 재심한다.
5. 수용 뒤 결과 문서·체크리스트·최종 감사·압축 인계를 마감한다. 전체 I01b/A04~A06 NOT_READY와 외부 schema UNCLASSIFIED를 유지한다.

소유 생산 경로는 기존 P2c 신규 `core/battle/operation_private_state.gd`, `tests/i01b_private_state.gd` 두 파일뿐이다. 새 증거는 `tmp/i01b-p2c-resume-20261101/`에 생성하며 기존 evidence를 덮어쓰지 않는다. 커밋·푸시·main 병합·worktree 생성은 범위 밖이다.
