# P02 여섯째 조각 독립 구현 5-b

판정: **한정 수용**. `IMPLEMENTATION-EVIDENCE.md` SHA-256 `356efaa5e9c6d1bedbe0883414ae6a8e3c952c567fff0cc4d0499b9227a620dc` 확인. 이 세션의 실제 모델 ID는 도구 메타데이터로 독립 확인할 수 없다. 이 판정은 계획의 지정 bench patch 두 오류와 제품 동기 호출 경계에 한정하며 P02 전체, 제품 operation 및 마감 수용이 아니다.

- 세 제품 diff를 직접 대조했다. `init_game`은 후보 프로필/별도 sim을 준비하고 지정 profile 오류는 sim 생성 전 반환·엔진 진단한다. 성공 시 기존 VM/FX 및 trace 등을 교체한다. `_ready`, `_restart`, deck 시작·재시작·타이틀, org 자동/복구에서 실패 후 후속 변경을 차단한다. 일반 profile 검증, RNG rollback 및 publish 중 예외는 계약 밖이다. 실제 세 제품 파일 SHA가 사후 동결 프로젝트 파일과 일치함을 확인했다.
- 사전/사후 공통 8행 27단언 결과가 비교 기록상 동일하고 사후 atomic 10행 546단언은 통과했다. 원문은 실패 결과, UI와 편성 변경, 대기 사건, trace와 시계 등의 체크를 포함한다. organization 및 BattleFlow와 returning WorldLink 통과, clean WorldLink의 서막 실패 exit 1을 별도로 보고한 점이 적절하다. 수동 GUI·Android·성능은 검증하지 않았다.
- 기존에 지적한 trace 오라클 누락은 보강됐다. `verify-trace-v4.py`가 사전 trace 원문 SHA를 확인하고 전체 start/close 행에서 wall_time과 mono_ms만 제외해 비교하며 control/pos 변조를 거부한다. 이 심사에서 비교 스크립트를 재실행해 통과했다. 기존 prefix 및 단일 close/start 검사도 유지한다. 사전 trace는 제품 편집 전 실행의 원문이며 오라클 가공은 사후임을 구분한다.
- common 및 organization의 after01 종료 진단 차이는 숨기지 않았다. after02는 각각 pre03 숫자를 재현하고, 별도 verbose 전후 쌍은 객체 유형 및 리소스 목록이 일치한다. 이는 이번 관측의 근거이지 누수 원인 전체를 확정하거나 향후 종료 진단이 항상 같음을 보장하지 않는다.
- 공유 checkout 차이 118개 중 제품 3개를 제외한 115개(기록상 P03 106개 및 PNG 9개)는 미귀속으로 기록되며 실행 입력 비중첩 근거가 제시됐다. 이 심사는 전체 19,365개 baseline과 미귀속 파일의 현재 바이트를 독립 재해시하지 않았고, 순차 관측으로 변경 주체나 앞선 시점 바이트를 확정하지 않는다. 마감 직전 별도 보존 감사 및 마감 심사가 필요하다.

기존 clean-user WorldLink 실패, ObjectDB/resource 종료 진단, 사용자 HUD 오류 미표시, 제품 operation 비연결과 외부 save schema UNCLASSIFIED를 그대로 보고해야 한다. 전체 P02/I01/I01b/A04~A06은 NOT_READY다.
