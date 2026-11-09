# 복귀 거절 attempt-02 사전 독립 심사

판정: 고정 격리 attempt-02 한 회 수용. 1/6은 이미 소진됐다. 기존 PC0 2/2와 다른 후보 K6은 별개다. 엔진/제품 실행 및 삭제는 이 심사에서 하지 않았다. 승인 파일은 review-only SHA e795cddea904e9019e81816d69867e3305b88d30ade31de5dc01caac7c25fc98에 결합한다.

G.state 존재와 값을 분리하고 prepare는 G가 빈 Dictionary임을, result/pause는 state 존재와 end/pause 값을 검사한다. 거절 전후에도 같은 조건을 검사하므로 단순 default를 사용해 부재를 감추지 않는다. 38개 입력·1480 source·baseline 경로가 검토 시점 일치하며 attempt-02는 없다. 실제 엔진·scene rename·loader·동일 전장 retry는 미검증이고 strict rows/진단과 actual root exit/Job 정리를 유지한다.

검토 시 가용 공간 5,019,287,552 bytes다. attempt-01의 before project는 import 후 약 1.004GB, after project는 import 전 약 0.670GB여서 두 새 project 및 유사 import 후 약 2GB 규모를 예상할 근거가 있다. 실행 전 4,000,000,000 bytes 바닥은 예상 두 project를 생성해도 약 2GB 잔여 공간을 남기는 합리적 출발 조건이나, 다른 작업의 동시 사용과 생성물 증가를 막는 실시간 예약 또는 전 과정 보장은 아니다. 디스크 부족/쓰기 오류는 실패로 보존하며 자동 반복하지 않는다. 이전 원문과 격리 데이터는 삭제하지 않았다.

경고 및 teardown 진단은 실제 before/after 원문을 독립 5-b에서 대조한다. 사용자가 직접 본 화면·OS 입력·자연 종결, 제품 전체 및 P03 복원은 이 테스트 범위 밖이다. 제품 원본 반영 전 별도 심사와 보호 경계 재확인이 필요하다.
