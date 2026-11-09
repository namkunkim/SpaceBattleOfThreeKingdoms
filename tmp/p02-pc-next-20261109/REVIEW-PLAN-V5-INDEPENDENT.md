# V5 정적 계획 독립 심사

판정: 동결된 attempt-02 단 한 회 수용. 이 심사에서 엔진·제품은 실행하지 않았다. attempt-01은 이미 1/6 소진이며 이번 실행은 2/6이다. PC0 2/2와 별도 K6 미사용을 유지한다. 원본 반영은 별도 5-b 및 소유 상태 확인을 요구한다.

V5는 확인된 editor folding 파일의 정확 경로·SHA·여섯 줄만 허용한다. 대상 scene 부재와 import 이후 사본의 나머지 바이트 일치, 다른 유사 cache 이름 거절, 모든 .import/.remap 텍스트와 project 설정의 대상 경로 검사 및 F1/F2/실제 ERR_CANT_OPEN을 유지한다. 이는 편집기 기록과 로드 가능한 리소스를 구별하는 한정 예외다. 다만 정적 경로 검사는 모든 가능한 엔진 해석을 증명하지 않으며 실제 오류와 원문 로그가 필수다. 다른 참조 또는 다른 진단이 있으면 중단하고 증거를 보존한다.

11개 승인 입력, 1,480개 source, 보호 4개 파일의 SHA가 심사 시점에 일치하고 attempt-02는 아직 없다. V4의 제품 후보·테스트·직접 Job 감독기·명령 계약은 동일하다. 최초 실행 시 runner가 SHA 및 HEAD/index를 다시 검사한다. 엔진 로그/실제 root exit/Job cleanup 및 각 테스트 행은 아직 미검증이고 stdout/stderr 엔진 capture를 주장하지 않는다. Job deadline은 OS 호출 반환을 전제로 하며 정리 증거 누락은 실패다. 직전 동시 변경이나 raw 진단 불일치는 조용히 허용하지 않는다.

승인 manifest는 DIRECT-MANIFEST-V5-INDEPENDENT-APPROVED.json이며 review-only 원문에서 status만 변경했다. 결과는 legacy 오류 처리 범위에 한정되며 실제 PC 입력·자연 종료·operation 또는 P02 완료가 아니다. 실제 모델 ID는 이 런타임에서 독립 확인되지 않았다.
