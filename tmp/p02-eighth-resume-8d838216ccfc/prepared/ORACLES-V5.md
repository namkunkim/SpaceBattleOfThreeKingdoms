# K6 V5 사전 준비

V4와 K4 원문을 보존했다. 행 17의 175초 제한 및 외부 320초 한도, 프로세스 수와 K 상한은 그대로다. K4의 재시도 175초 실패는 기존 기록으로 남는다.

행 17에서 175초에 도달하거나 정상 terminal을 검증할 수 없으면 실패를 JSON에 먼저 기록한다. product WorldMap 취소 또는 해당 resolver.cancel을 동기 호출한다. 이후 thread null, 취소, browse, 화면과 resolver 결과 없음, 가시 전환 0을 별도 기록한 뒤 exit 1을 반환한다. 취소가 블록되면 앞서 저장한 실패 JSON을 남기고 외부 소유 Job deadline이 그 프로세스 트리만 정리한다. 시간 초과나 join 실패는 결산 결과가 뒤에 관측되어도 성공으로 집계하지 않는다. 정상 경로는 worker가 null인 것을 두 차례 검사하고 나서만 sim fingerprint를 읽는다.

행 18에서 첫 취소가 통과한 다음 동일 WorldMap의 실제 출격 및 skip 버튼을 viewport로 다시 누른다. 첫 resolver와 다른 인스턴스에서 같은 Brief로 시작한 뒤 실제 취소 버튼을 다시 누른다. 두 사이클에서 join, browse, 결과 없음, 가시 전환 0, 반복 poll false를 별도로 검사한다. 첫 취소 실패를 보충하는 재시도가 아니다. 취소 버튼 뒤에도 worker가 남아 있으면 안전 취소 및 실패 경로를 사용하며 poll을 호출하지 않는다.

합성/정적 검사는 V4의 live sim 접근 구조, deadline return 누락, abort 경로의 sim 읽기, join된 timeout, join이 중단된 timeout, 정상 terminal에 섞인 timeout을 거부했다. 두 번째 취소가 없는 합성 원문도 거부했다. 이 결과는 새 GDScript의 제품 파싱, UI 재클릭, 실제 worker join 시간이나 실제 Godot wrapper의 확인이 아니다.

회귀 suite 일곱 분모, 실제 Godot/중첩 Job 및 GUI 전경·입력 귀속은 계속 차단 상태다. 독립 V5 심사 및 별도 실행 승인을 받기 전 전체 또는 부분 K6를 시작하지 않는다.
