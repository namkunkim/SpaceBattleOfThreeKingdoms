# P03 계획 v4 — 인라인 접근자 경계

2026-11-07 KST. attempt-02는 5-a 13종/46호출을 통과했으나 독립 5-b가 `var x: int = 0: get = _get`를 member로 승인하는 반례를 확인했다. PLAN-v2의 접근자 거부를 구체화하고 기존 증거를 보존한다. K6 현재 2회.

문자열, 주석 및 균형 잡힌 구분자 안의 문자를 제외한 최상위 토큰에서 var 선언의 첫 콜론을 확인한다. 이 콜론은 이름 다음의 타입 구분 또는 붙여 쓴 `:=` 하나만 허용된다. 두 번째 최상위 콜론 또는 assignment 뒤 콜론은 exit2다. 콜론 하나라도 타입 문법과 일치하지 않는 inline/accessor 꼬리는 exit2다. 클래스 수준 세미콜론은 여러 문장이 한 논리 행에 들어와 선언을 숨기지 않도록 exit2다.

기존 p03_09에 typed+initializer inline get, inferred+initializer inline set, typed+no initializer inline get, untyped+no initializer inline set과 동일 행 이중 선언의 exit2 5개를 추가한다. p03_03의 성공 fixture에 명시 타입, 문자열 콜론, dictionary 중첩 콜론을 동시에 포함하고 raw/identity를 대조한다. 동일한 13개 명명을 유지하고 실제 프로세스 수는 결과에 별도 기록한다. 승인된 정본 source와 baseline은 그대로 고정한다. 이 계획의 독립 수용 후 구현 및 새 5-a를 실행한다.
