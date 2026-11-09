# K6 V4 사전 준비

V3 및 독립 심사 원문을 보존한다. K6, Godot wrapper, editor import 및 OS 입력은 실행하지 않았다. K6는 21행 전체의 독립 재심이 필요하다.

## 단언 분모

SUITE-HISTORY-V4.json은 K3·K4의 디렉터리와 실제 원문 SHA 및 앞선 로그의 marker를 분리한다. K3은 native B/A, K4는 WorldMap complete/cancel B/A와 injected 및 GUI 시도였다. 요청된 7종 회귀 suite를 그 두 게이트에서 실행한 기록이 없다.

별도 역사 marker는 headless 13417, replay 101, private 11553, service 2202, active-replace 20099를 보인다. K1의 실패 marker에 찍힌 실행 횟수는 성공 단언으로 집계하지 않는다. WorldLink clean FAIL 1은 실패한 단언 수이고, returning PASS에는 전체 수가 없다. 역사 source/fixture·계측 및 현재 실행의 동일 분모를 독립 수용하지 않았으므로 V4에도 7종 분모 미동결이 남아 있다.

## 행 17·18

world-product-v4.gd는 앞선 실제 제품 viewport 입력 프로브의 버튼, 표준, RNG를 유지한다. complete의 결산 가시 전환 횟수, join, 결과 및 poll 두 건을 구분해 저장한다. cancel의 join, resolver 해제, browse 상태, 결과 두 경계 모두 null, 가시 전환 0회, poll false 두 건을 출력한다. 재클릭이 필요한지의 독립 계약 판단은 별도로 남긴다.

world_product_v4.py는 입력 행 및 JSON member 중복, 필드 누락·추가, 유형 차이, 예상 ID 불일치와 false를 실패 처리한다. Brief 기대는 K4에서 관측한 고정 seed 350157과 원본 anchor, edge_labels다. complete의 BattleOutcome.to_dict 15개 필드는 K4 before의 원문에서 동결했고 독립 비교 스키마로 명시했다. after와 동시에 같아도 두 lane이 이 역사 기준과 다르면 실패다. cancel의 예상 null 및 bool·상태는 취소 제품 계약에서 도출했다. 전체 B/A 결과 레코드도 같은 순서로 비교한다. 증거는 JSON이며 엔진 내부 float 타입 전체를 역추론하지 않는다.

합성 판정은 K4 원문만으로 새 lifecycle 항목이 미충족임을 확인했다. 보강 필드를 삽입한 합성 자료에서 성공 경로, 정수를 실수로 바꾼 complete와 결산 수를 바꾼 cancel의 실패를 각각 확인했다. 새 GDScript는 정적 준비이며 제품을 실행해 파싱과 결과를 검증하는 단계가 남아 있다.

## Job Object 및 GUI

소유 합성 payload가 자손을 시작한 뒤 exit 42로 즉시 종료해 broker가 종료돼도, 살아 있는 자손이 Job에 남아 종료되고 active 0이 되는 것을 관측했다. 실제 Windows 중첩 Job 정책 거부는 재현하지 않았다. 편입 API가 예외를 내는 분기만 모의해 명령 barrier가 해제되지 않고 소유 대기 브로커에 EOF만 보내는 것을 검사했다. 실제 Godot console 자손 실측을 별도 제품 실행으로 진행하려면 K6 소진 여부를 선결해 독립 수용받아야 한다.

Sky 입력의 연속 foreground와 독점 귀속은 미해결이다. Windows Job Object의 합성 성공과 JSON 비교 보완으로 GUI gate를 해제하지 않는다. V4 실행기는 검토용 명세를 시작 전에 차단한다.
