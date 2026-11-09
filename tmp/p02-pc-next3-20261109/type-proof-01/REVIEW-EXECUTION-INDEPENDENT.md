# D02 타입 단일 진단 독립 심사

판정: review-only SHA e815919d6c77240f786b3c96d0e6f8dc92a921996f1de892513c161b9b7d24e0에 결합된 import와 D02 각 한 회의 격리 진단을 수용한다. 이 심사에서 엔진·제품 실행이나 원본 변경을 하지 않았다. 기존 focused D02 실패를 PASS로 변경하지 않으며 candidate·GUI·PC0·K6을 실행하지 않는다.

승인 입력 27개와 source 1480개는 심사 시점 해시 일치, attempt 부재, 가용 10,963,591,168 bytes다. 240초 import exit0 및 120초 D02 exit1(정확히 roster.full/wait red)을 별도 실제 root/Job cleanup과 로그로 확인한다. 이는 timeout 합계이며 OS 호출의 절대 상한이 아니다. 검사 전후 source/HEAD/index 재확인, 격리 APPDATA와 시간/공간 바닥을 유지한다. 다른 예상 오류·누락은 진단 실패다.

진단은 기존 단언을 바꾸지 않고 양측 ID·진영·순서·값을 독립 JSON과 대조하며 실제 wait/morale int와 기대 float 타입을 기록한다. 계측 GDScript 파싱 및 실제 피연산자 유형은 아직 확인되지 않았다. 타입 가설이 관측돼도 제품 후보의 동작 또는 수정된 probe의 성공은 증명하지 않는다.

정규화 v2 diff는 타입 확인 뒤 float 유한성·0..2147483647 범위·정수성을 확인하고 두 기대 필드만 int로 변환한다. 순서·ID·값 비교는 그대로며 비정상 값은 fixture 실패로 남긴다. 해당 probe는 이번 진단의 실행 대상이 아니다. 오류나 확인되지 않은 타입은 정직하게 기록하고 기준선 실패를 소급 재분류하지 않는다.
