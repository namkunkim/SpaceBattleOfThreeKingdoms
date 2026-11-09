# K6 V3 사전 검토 자료

V2와 독립 심사 원문을 보존한다. V3는 58개 프로세스와 외부 18,490초, 정리 580초, 예약 1,200초를 유지한다. Godot 및 K6는 미실행이다.

## 소유 프로세스 트리

runner_v3.py는 검토 전용 상태, 승인 SHA, 전체 분모, GUI 근거, suite 분모, workspace 및 Git을 실행 전에 검사한다. owned_job_v3.py는 이름 없는 Windows Job Object를 만들고, 실행 인자가 없는 대기 브로커를 시작한 뒤 그 Popen 인스턴스의 프로세스 핸들로 Job에 편입한다. 편입 성공 뒤에만 파이프로 명령을 전달한다. Job을 상속하거나 breakaway시키는 설정은 없다. console wrapper와 그 자손은 Job에 속한다.

STOP, timeout, 예외 및 wrapper보다 오래 사는 자손의 경우 같은 소유 Job만 종료하고 ActiveProcesses=0 및 브로커 wait를 확인한다. 제한 시간 안에 확인하지 못하면 실패하고 Job 핸들을 닫는다. OS가 Job 편입을 거부하면 인자를 전달하지 않고 브로커에 EOF를 보내며 런 전체를 보류한다. 기존 PID/이름 검색이나 전역 종료 명령을 사용하지 않는다. 소유 외 P03 및 사용자 프로세스는 종료 대상에 들어가지 않는다. 브로커는 이 Windows CPython 환경의 Popen 프로세스 핸들에 의존한다.

합성 검증은 prepared/v3-synthetic에서만 실행했다. 일반 종료, timeout, STOP, 시작 전 STOP, Job 내 Python 자손의 시작과 종료, Job 밖 독립 witness 생존을 검증했다. 재현 코드와 원문은 체크 파일과 v3-synthetic에 있다. 실제 Godot console wrapper, 중첩 Job 거부 및 브로커 비정상 종료 실측은 아직 없다.

## 판정과 무결성

manifest는 계약 v1·v2, 독립 V2 리뷰, 원래 manifest, 이번 실행기/평가기와 합성 원문을 해시에 포함한다. 제품 probe는 예상 ID 다중집합과 참/거짓을 확인하며 false·누락·중복은 종료 0이어도 실패다. Suite는 반복 라벨의 원래 호출 순서와 ordinal을 보존하고 양쪽 전체 순서를 비교한다. 합의된 clean 서막 편차는 같은 단일 false, 종료 1, 정확한 원문 진단이 모두 맞을 때만 별도 집계한다. Typed 기록은 명명된 키의 보존 바이트를 비교하며 필수 키 누락 및 중복은 실패다. WorldMap 공개 progress 시간, 파일 이름 등 비교에서 제외하는 항목은 명시된 키 목록에 들어가지 않는다. 수집·판정의 부정 사례는 합성 자료에서 확인했다.

행 17·18의 B/A JSON lifecycle 필드별 비교와 행 15·16의 독립 OS 근거는 별도 확인으로 남아 있다. 기존 로그에서 실패한 suite 수를 성공 기대 분모로 재사용하지 않았다. 일부 suite의 정확한 분모, 행 14 버튼 /open의 두 번째 조건 분기, raw multiline 및 화면 timestamp의 제품 형식 검증이 남아 있으므로 현재 manifest는 실행 승인이 불가능하다.

원본 guard는 Git 선택 잠금을 끄고 branch/HEAD/index/stage 및 추적/표준 ignore 제외 untracked 관측을 남긴다. P03 차이는 시점별로 분리하고 귀속하지 않는다. 새 준비 경로 외의 미귀속 변화나 제품 입력 SHA 드리프트는 보류 사유다. 기존 4개 동결 lane과 복제 전후 해시·전용 fixture·overlay를 비교한다. 보호 검증은 실행하지 않은 제품 원문을 통과로 취급하지 않는다.

Sky 호출의 Promise<void>와 전후 창 정보에는 독점 OS 이벤트 귀속 및 연속 전경 증거가 없다. 승인된 구별 수단을 확인할 때까지 GUI 두 행이 빠진 부분 실행도 금지다. 원본 적용과 5-b는 미완료다.
