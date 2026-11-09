# P03 cursor/drain 실행 중단 인계

2026-11-08 KST. 독립 Terra가 수용한 PLAN.md v2 SHA는 8852B8C89A2217D1967BEF431FBA6913B66FC0D4BCEC10652C19F271D4A345AF다. 실행 담당 /root/remaining_sol의 명시 gpt-6.1-sol 배정과 별도 ID가 사용자 인정 근거다. 실제 서빙 모델은 미검증이다.

| 시도 | 실제 관측 |
|---|---|
| attempt-01 | Godot exit1. Script 상수의 resource_path 멤버 해석 parse 오류 2건 및 로드 오류 1건. 실행 전후 입력 135개 일치, Job active0/total2. typed Script 지역 변수로 수정했다. |
| attempt-02 | Godot exit1. 4개 명명과 32개 ID 전부 실행, 28 PASS 및 4 FAIL. 실패는 각 케이스 8번 close 하위 조건에만 발생했다. 엔진 본체 PID/경로 확인, Job active0/total2, timeout 없음, Godot 오류·경고·누수 진단 0. 135개 입력 전후 byte/해시 일치. |

두 번째 시도의 범위 확인에서 별도 tmp/p03-product-resume-20261108/detection-ui 하위 새 경로 6건을 감지했다. run.json에서 input_stable=false는 동결 입력의 SHA 차이가 아니라 이 범위 변화가 종합 stable 조건에 들어간 결과다. 외부 생성의 실제 주체는 실행 기록으로 판정하지 않았다. 승인 계획의 hard stop에 따라 즉시 조율자에게 보고했고 추가 실행을 보류했다. 동시 실행 창을 조율하고 별도 Terra가 재시도를 수용해야 한다.

코드 대조로 close 시험의 기대 DTO 누락을 식별했다. operation_private_state.gd의 summary()는 close 뒤 {ok:false,error:unprepared_owner,path:owner}를 반환한다. probe.gd의 _closed는 path를 빠뜨렸다. 동결된 실패 runner는 그대로 보존했다. 재심사 수용 후 이 기대 DTO만 고치고 나머지 분모와 규칙을 유지하는 것이 다음 조치다.

제한 관측에서 P의 pending Q 재주입이 추가 log/사건을 생성했고, 순서 변경 및 R 누락은 각각 순서 변화와 논리 거부 사건 유실을 만들었다. P를 복원하면 테스트 외부 Array에 같은 payload가 두 번 들어갔고 D 복원은 빈 drain이었다. 수신 원문의 키는 tick/kind/sq/other/pos/value로 사건 ID 필드는 없다. 관측은 각 8번의 전체 실패 및 5-a 미통과와 함께 기록한다. 실제 host ack, 외부 저장, 내구 커밋 및 운영 Cn 판정은 별도다.

시작·종료 상태와 해시 감사는 START-*, END-* 및 PRESERVATION.json이다. 동일 HEAD와 입력 일치와 별개로 P02 긴 경로 경고 2건이 남고 status의 기존 dirty 항목은 내용 비교를 제공하지 않는다. 전용 폴더 바깥에 쓰지 않았다. 전체 diff --check는 기존 CHECKLIST-OPEN.md 33행의 후행 공백을 보고했다. 공유 파일, 외부 기록 및 P02를 수정하지 않았다.

5-a 미통과. 전체 P03/I01/I01b/A04–A06 NOT_READY, O07 OPEN, 외부 저장 schema UNCLASSIFIED.
