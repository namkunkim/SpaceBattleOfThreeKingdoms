# P03 명령·사건 교차 경계 계획

기준 HEAD fb660cea69207fd332e26128643007694910a253. 이 작업의 소유 범위는 이 전용 tmp 폴더다. 공유 코드·문서·다른 실행 산출물은 읽기 전용으로 다룬다. 전체 P03/I01/I01b/A04~A06 NOT_READY, O07 OPEN, 외부 저장 스키마 UNCLASSIFIED.

## 증거와 차별점

기존 suffix는 Q/Q/S 접수와 즉시 적용 I의 교차, B/R 즉시 적용과 이후 step, step 다음 drain을 역사 입력에서 검증했다. 기존 viewer 경계는 같은 tick의 필터 drain 전후 복원으로 raw 큐 소비를 검증했다. 이번에는 명령 prefix/suffix가 있고 pending이 살아 있는 같은 tick에 raw drain을 끼워 넣는다. 교차 경계마다 어떤 입력을 새로 실행하고 어떤 사건이 남아야 하는지 독립적으로 판정한다. 전역 cursor 표현이나 외부 전달 확인 방식은 설계 범위 밖이다.

## 사전등록

1. 기존 fixture와 리터럴 payload를 참조한다. tick T에서 Q/Q/S를 queue, I를 issue한다. log=[I], pending=[Q,Q,S], raw=[stop]. Q 중복은 각각 한 접수다.
2. A를 캡처한다. 실제 raw drain이 stop 하나를 반환한다. B를 캡처한다. B의 tick, 명령 log, pending, 이동 상태는 A와 같고 raw는 비어 있다.
3. 같은 tick에 B 명령(move)과 R 명령(no_selection)을 issue한 뒤 advance한다. 예상 log=[I,B,R,Q,Q,S], pending=[], S로 이동이 멈춘다. 구조상 접수 성공과 전술상 R 거부를 별개로 단언한다. 최종 raw drain의 명령 사건 prefix는 [move,no_selection,move,move,stop]이다. 후속 drain은 빈 배열이다.
4. 실제 owner를 A에서 복원한 경우 drain부터, B에서 복원한 경우 B 명령부터 재생한다. pending은 복원본에서 적용된다. 각 복원 전 다른 실행 분기로 owner를 전진시키고, restore 뒤 보유 참조를 갱신한다. 같은 과거 raw 결과를 B에서 다시 drain할 수 없음을 별도 B 복원에서 확인한다.
5. 동일 입력의 별도 raw BattleSim 실행과 단계별 tick/log/queue/이동/raw drain 결과를 대조한다. 수기 순서·payload와 명령 효과의 독립 단언도 요구한다. 교차 시점 한 번의 drain을 생략하면 stop이 재출력되고, 이미 소비된 B에서 stop이 재출력되지 않는다는 점을 실측한다. 같은 tick 또는 log 길이만으로 소비 이력을 분류할 수 없는 반례다.

## 실행과 인계

- 계획 독립 다른 모델 수용 후에만 runner 작성. 현재 class map과 실제 엔진 console/본체를 사용하고 입력 경로·SHA 및 변경 전후를 기록한다. 기존 gate와 Job 회수 코드는 읽어 재사용 가능성을 먼저 확인한다. 실패 시 stdout/stderr·actual exit·timeout/자식 종료를 기록하고, 독립 5-b에 전량 제출한다.
- 5a는 명명 단계·단언 결과, 정확 payload 및 raw oracle, 오류 진단과 SHA, 전용 산출물 공백과 타 변경 보존을 확인한다. 마지막에 독립 5-b 및 closeout 판정을 인계한다.
