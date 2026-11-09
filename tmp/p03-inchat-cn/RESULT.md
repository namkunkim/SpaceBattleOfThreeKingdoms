# Cn 실제 호출 경계

현재 소스에서 자연적으로 같은 private owner에 대한 제품 Cn 복원이 겹치는 진입 경로를 찾지 못했다. `ledger.json`은 제품 raw host, legacy worker, 제한 worker, 제한 replay, owner API, 제품 join 경계 6개와 객체 공유 비교 4쌍을 기록한다. 제한 worker는 복제한 입력을 넘기고 스레드 안에서 fresh owner를 만들어 전진·소비·종료한다. join 뒤에는 결과 DTO를 복제해 반환한다. WorldMap은 legacy resolver를 쓰고 FleetBattle3D는 raw sim을 생성한다. worker의 시작 거부와 owner의 `_busy`는 별개다. worker mutex는 취소 플래그를 보호한다.

독립 계획 조건에 따라 현재 HEAD와 95개 생산 .gd/.tscn, P02 진행표와 계획·심사 문서 3개를 실행 범위에 포함했다. 검색어·결과·경로별 SHA는 attempt-02의 before/after stdout에 보존했다. 32개 검색 행을 정렬해 스캔 출력 순서 차이를 제거했다. HEAD는 `0be09755b70378286105972f35ac5b7031715664`이며 98개 입력의 전후 snapshot SHA는 `8f08554ec1b7809f5f5351fb7d39a86608b0381c838c7fea116272f73c287836`으로 일치했다. 생산 소스의 초기 읽기 조사에는 전수 해시가 없었으며 실행 전후에 전수 동결했다. 전체 Git 상태 전후 감사와 범위 밖 동시 쓰기 확인은 수행하지 않았다.

첫 시도는 rg 병렬 출력의 순서 차이로 비교에 실패해 실제 자식 exit가 모두 2였다. 기존 로그는 보존했다. 두 번째 시도는 정상 0, 제한 worker 행 제거 1, 자연 경합의 허위 승격 1, 근거 경로 누락 2로 기대와 일치했다. 각 독립 사본·변이와 stdout/stderr·exit를 보존했다. 2/3회 사용.

호출자 탐색은 고정된 생산 소스의 정적 조사다. 동적 호출이나 범위 밖 소비자를 포함하지 않으며 자연 경합을 실행하지 않았다. 기존 busy 직접 설정 fixture의 결과를 자연 경합으로 승격하지 않는다. 생산 파일 변경과 Godot 실행은 없다. 전체 P03/I01/I01b/A04~A06 NOT_READY, O07 OPEN, 외부 저장 스키마 UNCLASSIFIED.
