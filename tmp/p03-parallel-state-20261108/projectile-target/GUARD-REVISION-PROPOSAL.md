# 중첩 Missile 원문 확인 기준 변경안

승인된 PLAN-PROJECTILE-TARGET의 중첩 스크립트 경로 조건을 실제 Godot 4.7.2 관측에 맞춰 바꾸는 제안이다. 현재 독립 수용 대기다.

attempt-01은 실제 Missile prototype과 여섯 발의 raw resource_path를 초기 발사 및 양성 복원 뒤에 두 번 기록했다. 전부 빈 문자열이었다. outer BattleState 원문 경로를 nested path의 접두사로 요구한 두 guard가 실패했고 본시험 실제 exit 1이다. 빈 문자열 자체에 원문 provenance 의미를 부여할 수 없다.

제안된 확인 기준은 실제 state 객체의 get_script().resource_path가 res://core/battle/battle_state.gd에 정확히 일치하고, 그 Script의 get_script_constant_map().get("Missile")과 BattleState.Missile.new().get_script()가 is_same이며, 여섯 실제 missile 객체의 Script도 각각 이 객체와 is_same인 것이다. 초기와 양성 복원 뒤를 각각 확인한다. raw nested path와 enclosing path를 그대로 출력한다. 단순 이름 문자열과 타입 일치만으로 통과하지 않는다.

변이, 구조 검사, 오류, raw events, identity, 다음 틱, exact 비교 및 다른 클래스의 원문 경로 guard는 변경하지 않았다. attempt-02 변경 runner SHA256 fba74d68ee04ee73427ca72c01b8145e4859467dd2b17daa2e3e250cb9d11d222를 정적·독립 심사 대상으로 요청한다.

조율자의 재실행 전 독립 수용 요청이 도착했을 때 attempt-02는 이미 시작됐다. 두 번째 실행의 성공은 잠정 관측으로 보존한다. 기준 수용 전 정식 완료 판정이나 추가 실행을 하지 않는다. K=3 중 2회 사용.
