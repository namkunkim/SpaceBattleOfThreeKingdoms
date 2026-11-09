# PC0 owned-v3 독립 사전심사

판정: 동결 manifest 861a06ac52f13d9a470acef7f5601bf9c1a7b3f59042984d93e52c39d8120702의 legacy PC0 run-02 단 한 회 수용. 실제 실행은 하지 않았다. 전체 2회 중 run-01이 1회이며 첫 엔진 생성 요청 시 잔여 1회가 소진된다. 실패 또는 관측 불명확 시 자동 재시도 금지. 독립 수용 기록은 PC0-OWNED-V3-APPROVAL.json이다.

16개 manifest 부품 해시와 run-01 보호 8개 파일 및 recovery lock을 대조했고 run-02는 아직 없다. oracle, overlay, trace reader는 수용된 terminal 후보와 동일하다. verify.py의 차이는 run-02 경로 및 Job 정리 검증 추가다. 합성 Job 1 양성/10 부정, terminal 2 양성/8 부정은 실제 OS 또는 Godot 증거가 아니다.

이전 차단 사유였던 미지 자식 이미지 전체 해시는 제거됐다. root 이미지 사전 해시와 suspended 생성, Job 할당 후 resume, 보유 HANDLE 및 Job active 관측으로 범위를 제한한다. 단명 자식의 신원과 내용은 증명하지 않으며 unknown 자식을 GUI 입력 대상으로 신뢰하지 않는다. 소유 Job 외 프로세스를 종료하지 않는다. 루프 deadline은 OS 호출과 파일 I/O가 영원히 막히지 않는다는 조건의 운영상 제한이며 독립적인 커널 보장 시한은 아니다. 로그 누락이나 cleanup 신호 부재는 실패다.

실행 직전 모든 입력 및 엔진, 원본/P03, run-01 보호 해시와 run-02 부재를 다시 확인하고 차이 발생 시 중지한다. isolation/import 성공과 root 소유 창, foreground/DPI/좌표 일치가 확인되기 전 제품 입력을 하지 않는다. 행동·스크린샷과 이벤트를 별도 검증하고 자연 종료 및 지도 복귀를 관찰한다. 이 실행은 legacy PC0 확인이며 P03 operation, 전체 P02 완료 또는 별도 후보 K6 성공을 의미하지 않는다. 실제 engine/GUI/Job 동작은 아직 미검증이다.
