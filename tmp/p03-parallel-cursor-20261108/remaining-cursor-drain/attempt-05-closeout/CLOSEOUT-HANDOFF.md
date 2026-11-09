# attempt-05 독립 마감 인계

이 패키지는 새 실행 없이 전용 폴더의 기록을 원래 바이트 그대로 보존한다. 실제 Godot 실행은 attempt-01, 02, 03, 05의 4/K6이다. 04는 사전 점검 중단으로 실행이 없었다. 01의 parse 오류, 02의 close 기대값 실패와 동시 UI 6경로, 03의 32 PASS 및 별도 clock/RNG 3경로 hard stop, 이전 사전 점검의 P02 trace 2경로 변화, 04의 보호 루트 장경로 경고는 기존 기록과 함께 남긴다. 이후 05의 수용이 앞선 판정을 변경하지 않는다.

05는 5-a와 독립 Terra 5-b에 통과했다. 실제 exit0, 정확 32 PASS, 진단 0, Job active0/total2, 동결 입력 141개와 보호 항목 82,752개 전후 일치, 예약 밖 status 변화 및 신규 trace 0을 확인했다. 역사 P02 trace에는 독립 엔진 PID가 없어 해당 숫자를 출처 판정에 사용하지 않았다. P02 외부 원본은 수정하거나 ZIP에 복사하지 않았다. 해당 경로·SHA와 동시 변화가 이미 남은 전용 기록을 포함한다. 해시 일치는 정의된 전후 관측 범위이며 전체 트리 불변을 주장하지 않는다.

ZIP은 전용 실행 원문과 계획·검증기·감사·심사 기록을 담고, 별도 manifest는 각 항목 SHA-256/크기/CRC를 제시한다. 독립 마감은 원본과 ZIP 항목의 정확 대조, ZIP 자체 SHA/크기, 경로 중복과 CRC 검사, 5-a/5-b 수용 범위 및 실패 이력 보존을 확인한다.

수용 범위는 제한 in-memory serial owner의 pending/suffix 및 테스트 외부 Array다. 실제 UI/ACK 및 운영 cursor/commit은 별도다. 전체 P03/I01/I01b/A04–A06 NOT_READY, O07 OPEN, 외부 저장 schema UNCLASSIFIED.
