# P03 선언 변경 감지 계획 v2 독립 심사

2026-11-07 KST. 판정: **계획 수용**, 승인 범위는 PLAN-v2의 읽기 전용 선언 변경 경보 첫 조각이다. 구현과 독립 심사는 분리된다. 계획·구현 담당 `gpt-6.1-sol`, 심사 담당 `gpt-6.1-terra`는 spawn 도구의 명시 배정 인수다. 실제 내부 런타임 모델 식별 및 그 차이를 독립적으로 확인한 것은 아니다. 이 기록은 사람의 최종 판단을 대체하지 않는다. v1 반려 기록은 보존한다.

## 반려 4항 재심

1. **독립 기대값:** `oracle-20261107.json`은 31개 경로별 scope/name/static/순서/행/raw 및 SHA를 기록하고 scanner를 호출하지 않는다. 심사에서 별도 행 기반 스캔으로 각 파일의 선언 identity·순서를 대조하여 차이 0, 모든 raw·행과 SHA·경로 집합도 원문과 차이 0을 확인했다. 기존 294 관측의 local 4 오탐과 static 4 누락은 서로 상쇄됐다. BattleState 내부 두 scope, P02 신규 adapter의 member 0, owner 7개 member를 직접 확인했다. 이는 현재 소스의 제한 관측이며 GDScript 전체 구문이나 실행 상태 전수의 증명은 아니다.
2. **fail-closed:** 허용 범위·미지원 문법·블록/문자열/괄호 실패와 새 inner, annotation, accessor 등의 개별 exit2 반례를 정했다. 함수 본문의 임의 의미 검증은 비대상으로 명시했다. 구현 시 이 목록의 각 사례가 실제로 오류인지 최종 5-b에서 재검증한다.
3. **기준선:** 독립 oracle 전 항목 대조 후 별도 baseline 고정, 실행 전후 입력 집합·SHA 비교, 미해결 차이 실패, P02 변경을 읽기 관측으로 분리한다. 소스가 달라지면 새 revision과 심사로 돌아가는 조건이 있다.
4. **실패 원자성:** 읽기 오류·경로 변화·인코딩·불완전 baseline에서 exit2와 빈 stdout, 출력 예약 충돌 및 기존 입력/출력 보존을 요구한다. 실행 중 변경 후 원복은 탐지 불가로 명시했다. 독립 최종 심사에서 각 subcase와 실제 exit를 확인해야 한다.

STATE-AUDIT과 COMMAND-AUDIT는 C0/Cn, 상태 수명 및 명령 접수·적용·drain의 구분과 후속 책임을 제시하지만 필드별 완전 원장과 실제 suffix 검증은 미완료다. 전체 I01/I01b/A04~06 NOT_READY, 외부 save schema UNCLASSIFIED를 유지한다. P2c 70/11553/45, active restore 20/20099(명명 8/호출 9)는 기존 제한 수용이다. 정확한 Variant type/value, Dictionary 키 타입·삽입순서, Array 순서 및 typed builtin/class/script identity는 실제 복원 후 비교의 별도 요구다. 이 도구는 이를 증명하지 않는다. Godot/class map은 미사용이며 기존 전체 diff-check CRLF exit2와 별도 게이트다.

수용은 계획 단계에 한정한다. 13명명 검사와 subcase/호출 분모, 독립 oracle, 동결 SHA, 신규 경로만의 변경 및 실제 실패 원자성은 구현 후 별도 5-b의 필수 조건이다. P02 관측 SHA는 P02 closeout 또는 전체 저장 기준선 승인이 아니다.
