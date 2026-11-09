# UI 호출·표시 경로 독립 5b

판정: **PASS — 고정 생산 소스의 유보 8셀 읽기 조사**. 보존 기록을 검독했으며 gate나 UI를 독립 재실행하지 않았다.

- 기준 정책 원장의 user_choice 빈 8개 튜플과 결과 8행이 정확히 일치한다. 고정 생산 파일 95개에서 지정 패턴의 32행을 별도 계수했고, 원장 anchor 경로가 존재한다. lexical에는 정의·주석·내부 호출이 들어가며 reflection·문자열 조립·외부 플러그인 등은 범위 밖이다. 직접 제품 호출 미발견은 이 집합의 결과이지 전역 부재의 증명이 아니다.
- 초기 raw drain과 후속 filtered pump, 동기 step의 이전 완결 상태 보간, legacy 준비 오류와 private busy/closed의 분리, 제한 worker와 제품 restore 미연결의 주요 source anchor 및 기존 증거 수준을 대조했다. 신규 제품 runtime 또는 모든 간접 호출의 실행을 입증하지 않는다. 사용자 선택은 기존 HOST_AUTHORITY/DELIVERY_MODE에 남긴다.
- 첫 준비 실패 기록은 P02 진행표 source drift와 exit 2를 보존한다. 재동결 범위에 포함된 최신 P02 준비 V5 독립 심사는 실행 반려 유지로, 이를 제품 수용으로 승격하지 않았다. 4개 child의 기록 exit 0/1/1/2와 지정 누락·busy 승격·부재 입력 출력을 확인했다.
- manifest SHA `4d344c30ddb6754969f917428f0023d023cf279975fa75fffc918ad7d74811c5`, 전후 목록 및 현재 118개 입력 SHA가 일치한다. 기록 HEAD는 `fb660cea69207fd332e26128643007694910a253`, Git 상태 변화 10행은 전용 경로다. 상태 비교는 사전 drift와 구분하며 전체 dirty·무시 파일의 바이트 불변을 입증하지 않는다.

실제 제품 restore UI, 동시성 안전, 외부 전달과 사용자 정책은 미검증이다. P03 NOT_READY 등 기존 상태를 유지한다.
