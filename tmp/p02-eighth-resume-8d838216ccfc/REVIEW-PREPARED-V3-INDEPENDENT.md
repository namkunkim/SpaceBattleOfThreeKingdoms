# K6 준비 V3 독립 심사

판정: **준비 자료로 보존, 실행 반려**. `MANIFEST-V3-REVIEW-ONLY.json` SHA-256 `774746349548ff39bbb5ab3259c6015b95b01f39d4f7830e7622d87e7e801279`를 직접 확인했다. 실제 심사 turn metadata: gpt-6.1-terra / low. 제품 실행과 GUI 입력은 하지 않았다.

58 jobs, 비교 그룹 27개, 상한 20270초(외부 18490 + 정리 580 + 예약 1200)를 확인했다. 113개 명시 dependency의 현재 bytes/SHA가 모두 일치하고 계약 v2가 포함된다. 이는 다른 모든 실행 입력, 4개 lane의 현재 상태와 최종 preflight가 검증됐다는 뜻은 아니다.

Job Object는 인자 없는 대기 broker를 Popen의 live handle로 소유 Job에 편입한 뒤 명령을 전달한다. 중단 시 해당 Job만 종료하고 active 0 및 broker wait를 확인하며 PID 이름 검색이나 외부 프로세스 종료를 사용하지 않는다. 합성 원문의 정상·timeout·STOP과 시작 전 STOP, 소유 Python 자손 완료 표식 부재, 독립 witness 생존 및 부정 assertion 결과를 직접 확인했다. 이는 실제 Godot console 자손, 중첩 Job 편입 거부, broker 비정상 종료 및 모든 예외 상황의 실측이 아니다. 실행 전 해당 경계와 실패 처리의 독립 검증이 필요하다.

판정기는 probe ID 다중집합과 bool을 확인해 거짓·누락·중복을 실패 처리하고 suite 순서 및 선택된 raw 바이트 비교를 구현한다. 합성 원문의 정수/실수 차이, 누락, clean 편차 조건은 확인했으나 합성 데이터가 실제 Godot multiline 형식 및 전체 제품 oracle을 입증하지 않는다. 특히 14개 suite job의 정확 분모가 미동결이고 17·18행 JSON lifecycle 비교는 별도 근거로 남았다. 비교 그룹에 `independent` 4개가 있어 자동 통과가 아니며 별도 평가가 필요하다. 완료된 각 행의 필수 필드·타입·전후 차이, trace/결과 및 제외 항목을 재심해야 한다.

GUI는 연속 foreground와 독점 입력 출처가 미해결이다. Sky Promise<void> 호출과 전후 창 관측의 시간 일치만으로 귀속을 증명할 수 없다. runner의 GUI 및 미동결 분모 차단은 유지해야 한다. GUI를 제외한 부분 실행도 단일 잔여 K6의 고정 21행 조건을 충족하지 않는다. 완료된 manifest·명령·fixture·전체 oracle·소유권 절차와 재동결 입력을 독립 재심하기 전 실행하지 않는다. K1~K5 및 실패 원문, 원본 checkout/Git/HTML/P03을 보존한다. 본 판정은 제품 적용·5-b 인수가 아니다.
