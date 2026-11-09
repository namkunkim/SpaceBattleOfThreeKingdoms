# 직접 전환 거절 V4 독립 사전심사

판정: 동결된 격리 attempt-01의 단 한 회를 수용한다. 실제 제품·엔진 실행은 이 심사에서 하지 않았다. 승인본은 DIRECT-MANIFEST-INDEPENDENT-APPROVED.json이며 review-only manifest의 status만 바꾼 것이다. 제품 원본 반영은 별도 5-b 심사와 현재 소유권 재확인 후에만 판단한다. PC0 2/2, 여덟째 K6 미사용을 변경하지 않는다. 이 조각 상한은 6회이나 이번 승인은 1회뿐이다.

검토 당시 승인 입력 11개 SHA, closure source 1480개 및 보호 대상 4개가 현재 파일과 일치한다. 실행 직전 runner 자체가 HEAD/index, closure와 대상 SHA 및 신규 attempt 경로를 다시 확인한다. 두 제품 후보 diff는 네 WorldLink 필드의 참조/값을 에러에 복원하고, 지도에서 이전 화면·brief·영역·잠금 복원 후 chip을 표시한다. scene OK 이후 새 장면 준비 완료나 자연 종료를 의미하지 않는다. 결과 카드의 동일 객체·레이블·버튼·영역과 의도치 않은 재소비/음향/타이머를 실제 로그 및 diff로 별도 확인해야 한다.

45개 reject 행은 실제 누락 scene 엔진 경로를 의도하며, F1/F2/경로와 오류 반환·원문이 필수다. 테스트 구문, resource loader, 엔진 오류 문구, 45행, 정상 direct, auto/title/restart는 아직 실제 검증되지 않았다. 예상 거절 진단이 다르거나 SCRIPT ERROR·누락·timeout이 발생하면 raw 증거를 보존하고 실패로 처리한다. before 실패는 의도된 특정 단언을 실제로 드러내야 하며 나머지 행도 존재해야 한다. 결과가 불명확하면 해당 시도를 추가 진전으로 인정하지 않는다.

직접 GUI exe의 headless root를 suspended 생성해 전용 Job에 할당하고 root HANDLE 실제 exit, active 0과 보유 member signal을 기록한다. 새 Job 구현 및 Godot GUI exe log 출력은 아직 미실측이다. 알려지지 않은 단명 member의 신원이나 엔진 stdout/stderr 캡처는 보증하지 않는다. engine.log가 없거나 판정 행이 없으면 실패다. deadline은 감독 loop·OS 반환에 의존하며 절대 벽시계 상한이 아니다. 외부 watchdog은 정확히 소유한 supervisor만 종료하고 Job kill-on-close를 이용한다. 종료 기록이 없으면 정리 완료를 주장하지 않는다.

소스 closure의 전후 동결은 기록된 파일에 한정되며 사용자 전체 저장소의 전역 스냅샷이 아니다. P03 등 병행 변경 시 실행·적용 전에 중단하고 재동결한다. 기존 run01/02 및 사용자 데이터는 보존한다. 이번 후보는 legacy 직접 전환 오류 처리이며 사용자 실제 GUI 입력, PC0 완료, operation 연계 또는 P02 완료 증거가 아니다. 실제 모델 식별은 이 런타임에서 독립 확인할 수 없어 임의로 적지 않는다.
