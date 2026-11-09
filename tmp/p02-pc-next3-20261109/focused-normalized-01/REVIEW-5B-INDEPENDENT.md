# 축소 난이도 실행 독립 5-b

판정: 14개 격리 lane의 축소 자동 검증은 수용한다. 현재 후보 전체의 원본 반영은 아직 수용하지 않는다. 후보가 invalid routed 거절 정책·POC/편성 fallback에도 영향을 주는 반면 이번 분모에는 해당 행이 없고, 사용자 요청은 첫 PC 필수 작업에 한정되기 때문이다. 실제 영향 경로를 최소한으로 별도 확인하거나, 범위 밖 정책을 제거한 후보를 만든 뒤 변경분에 맞는 회귀와 독립 심사를 해야 한다. GUI 물리 행은 미검증이며 그것을 이 자동 결과로 대체하지 않는다.

실제 14개 command JSON은 승인 manifest에 일치하고 각 root signal·실제 exit, Job active 0 및 보유 자손 signal 0을 확인했다. before D01/D03/D04는 각 정확한 4개 red·exit1, D02/D08/D09 전 PASS, after D01–04/D08/D09 전 PASS다. raw의 고정 ID 및 실패 집합이 승인 명세와 일치한다. 실제 진단은 양쪽 D08의 invalid_candidate_profile at profile 각 1건뿐이며 SCRIPT ERROR 또는 예상 밖 ERROR/WARNING은 발견하지 못했다. results.jsonl SHA 5733a70fb1ca7ee2d1273ace99b9642fe745879d7f0f90971211d5d3888b8d65이다.

이 범위에서 네 난이도의 실제 routed 후보 host 값·독립 데이터 기반 AI 및 초기 할당 roster/wait, 결과 seed/difficulty를 확인했다. D08은 profile_patch 거절 전후 sim·seed·난이도·G·시계·선택·trace·link 보존과 정상 재준비를 검사하나 재준비 후 변경된 난이도 규칙을 다시 대조하지 않는다. D09는 standalone 기본과 재시작이다. signal은 프로그램 호출, 결산은 강제 종료 fixture이며 실제 OS 입력이나 자연 전투가 아니다.

승인 파일 및 source 1480은 현재 해시가 일치하고 HEAD·빈 staged가 확인됐다. 이 확인은 전체 사용자 파일 또는 다른 작업의 장래 쓰기 잠금이 아니다. 이전 파서/D02 실패와 독립 타입 진단은 보존하고 기존 실패를 소급 PASS로 바꾸지 않는다. PC0 2/2 및 별도 K6은 변함없다. 이 심사에서 제품 파일을 수정하지 않았다.
