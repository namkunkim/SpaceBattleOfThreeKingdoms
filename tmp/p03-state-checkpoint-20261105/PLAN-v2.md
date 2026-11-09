# P03 선언 변경 감지 계획 v2

2026-11-07 KST. [v1 계획](PLAN.md)의 범위, 명명 검사 13종, K6 및 보존 계약을 이어받는다. 아래 규칙이 충돌 시 우선한다. [v1 반려](REVIEW-PLAN.md)의 네 항목에 대한 재심을 기다린다. 구현 K6 사용 0. 구현 담당 gpt-6.1-sol, 독립 심사 담당 gpt-6.1-terra 배정. Astra 제외.

## 1. 소스 분모와 독립 기대값

현재 31경로. 원 관측 30경로 294행과 독립 후보 30경로 294행은 합계만 같다. 전자는 BundleLayout 12~14와 PocSetup 9의 static 4개를 놓쳤고 BattleState 71·86·90·91의 함수 local 4개를 포함했다. 독립 후보는 그 네 추가/네 제외와 stratagem 34의 다행 raw를 반영한다. P02가 추가한 adapter는 script member 0개이며 OperationPrivateState의 현재 변경은 member 7개가 동일한 코드 SHA drift다. 과거 후보와 관측의 파일을 보존한다.

별도 원문 검토 증거 `oracle-20261107.json`은 후보와 현재 바이트의 차이를 경로별로 기록한다. 검토 방식은 행 기반 목록과 직접 확인한 BattleState 두 inner 범위, stratagem 다행 원문 대조다. 구현 scanner의 알고리즘을 호출하지 않는다. 심사자가 후보의 상쇄·누락, 새 adapter 본문 및 owner 변경 hunk를 독립 검토한 후에만 P03 재고 기준을 승인할 수 있다. P02 SHA는 현재 읽기 관측으로 분리하며 P02 closeout이나 저장소 정본 승인으로 승격하지 않는다. 검토 당시에 고정한 현재 source SHA가 달라지면 재고 생성·실행 중단, 새 revision과 심사로 돌아간다.

실제 oracle 비교는 정렬된 경로 목록, 파일 SHA, scope, name, static, 파일 내 순서, 줄 번호, raw 모두를 비교한다. 숨은 차이 1개라도 실패한다. v1 candidate에 대한 별도 의도된 drift 관측은 adapter 추가 및 owner SHA 변경만이며 현재 oracle 일치 증거와 구분한다. 구현이 출력한 baseline은 독립 oracle과 대조해서 완전 일치한 뒤 별도 새 파일로 고정한다. 동일 구현의 collect/check 일치만으로 기준선을 받아들이지 않는다.

## 2. 지원 범위와 오류 경계

범위는 UTF-8 GDScript의 스크립트/inner class 선언 재고다. UTF-8 BOM은 지원하지 않으며 CRLF/LF를 읽되 raw의 행 구분은 LF로 통일한다. 실제 byte SHA는 줄바꿈을 포함한다. 파일 안 raw는 원문 들여쓰기/공백/주석/다행 전체를 유지한다. check의 schema 비교에서는 줄 번호는 진단 전용이고 raw만 변하면 선언 텍스트 변경, 파일 SHA만 변하면 코드 drift로 분리한다. class_name 없는 script scope는 경로 stem으로 표시한다.

클래스 본문은 빈 줄·주석·extends·class_name·const·signal·enum·func·static func·var·static var와 BattleState의 Missile/Swarm class만 허용한다. 그 외 class, 중첩 class 및 클래스 본문 annotation 전부, 미지 문장, 지원하지 않는 들여쓰기, 중복 이름, var 문법 미일치, 속성 접근자는 위치 있는 오류로 처리한다. var 형식은 식별자, 선택적 명시 타입 및 선택적 = initializer 또는 := initializer다. initializer는 빈 값을 거부한다. 중첩 괄호/대괄호/중괄호 다행 묶음과 일반 문자열 escape 및 # 주석을 토큰 경계에서 처리한다. triple-quoted 문자열과 backslash 줄연결은 명시 거부한다. 짝이 맞지 않는 구분자, 닫히지 않은 문자열, 함수/클래스 블록 부재 및 EOF의 미완결 구문은 오류다. 함수 본문은 선언 재고 대상에서 제외하고 문자열/구분자/블록 경계를 확인한다. 엔진 문법/타입 검증은 이 계약 밖이며 함수 본문·initializer의 임의 의미/문법 오류를 모두 진단한다고 주장할 수 없다.

## 3. 실패 계약과 5-a

도구는 stdout 전용이며 `--output` 인수나 자체 파일 작성 기능은 없다. 오류에서는 stdout을 비워 둔 채 stderr와 exit2를 반환한다. 파일 추가/삭제, 선언 변화, SHA 차이는 완성된 단일 JSON과 exit1이다. baseline의 기존 파일이 읽기 시작부터 없으면 정상적인 삭제 drift다. 나열 후 읽기 전에 사라지거나 읽기 불가, 읽는 중 경로 집합/bytes가 바뀌면 exit2다. 읽은 바이트와 별도 재확인한 전체 경로/바이트 SHA를 비교하고, symbolic link 및 경로 이탈은 거부한다. 시작과 끝 사이에 바뀌었다가 원복된 바이트의 검출은 보장하지 않는다. baseline 잘못된 인코딩/JSON/키/타입/중복 path·identity/불완전 문서 및 순서 검증 실패는 exit2다.

실행 증거 runner는 stdout/stderr/exit의 새 경로 예약에 exclusive create를 사용한다. 기존 output 충돌 검사는 실행 전 종료하고 이미 있는 모든 출력과 모든 입력을 그대로 보존한다. 정상 결과 payload는 프로세스가 종료된 후 읽어 검증하며 오류 스트림은 별도 로그에 보존한다. 산출물용 디렉터리가 이미 있으면 사용하지 않는다. CLI 프로세스 호출마다 executable 경로/버전 및 SHA, scanner·test runner·baseline·oracle 및 fixture 또는 정본 source 입력 manifest SHA, stdout/stderr/actual exit를 남긴다. 실제 게이트 시작 직전·직후 이 입력의 SHA와 집합을 다시 확인한다. 유효 fixture 변이는 테스트에서 명시적으로 단계 분리하고 실제 invocation 직전 기준으로 재고정한다. 불일치가 나면 해당 게이트를 실패 처리한다.

v1 명명 13종을 유지한다. 06은 타입/initializer/순서 3개, 07은 신규·삭제 2개, 09는 annotation(같은 줄/분리), 새 inner, getter/setter, 알 수 없는 문장, triple quote, 닫히지 않은 문자열/괄호, 잘못된 괄호, 미완결 var, backslash를 개별 기대 exit2로 분리한다. 10은 잘못된 JSON/중복 identity/필수키 누락/중복 path를 각각 exit2. 11은 나열 후 삭제·읽기 실패(Windows 권한 재현이 불안정하면 read 함수 주입), 잘못된 UTF-8, 입력 SHA 변경, existing output을 개별 실패로 검사하고 대상이 입력 시점에 존재한 바이트를 도구가 바꾸지 않았는지 확인한다. 13은 현재 31경로 및 294 identity/order/raw 완전 대조와 역사 후보의 의도된 drift 확인을 분리한다. 명명 13종과 실제 subcase·프로세스 호출 분모는 별도로 기록한다.

5-b에서 심사자는 대칭 누락/추가, 새로운 구문 또는 숨은 생산 변경을 반증한다. Godot/엔진/class map 미사용이다. P2c 70/11553/45와 활성교체 20/20099(명명8, 호출9)는 이전 제한 검사다. 전체 I01/I01b/A04~A06 NOT_READY, 외부 save schema UNCLASSIFIED를 유지한다. 기존 전체 diff-check exit2와 신규 산출물 게이트를 별도 기록한다.
