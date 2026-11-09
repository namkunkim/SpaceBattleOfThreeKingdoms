# K6 준비 V5 독립 심사

판정: **실행 반려 유지**. `MANIFEST-V5-REVIEW-ONLY.json` SHA-256 `79f3534bc0d415630ecaea71dbe204d9502425e9f498c386f8ad3319c42610a5` 직접 확인. 현재 명시 dependency 201개 bytes/SHA 일치. 58 jobs, 총 상한 20270초이며 행 17 내부 175초·외부 320초는 유지된다. 심사 turn metadata: gpt-6.1-terra / low. 제품 실행과 OS 입력은 수행하지 않았다.

V5 complete 분기는 deadline 도달 또는 terminal 불능 시 false 결과를 먼저 파일에 저장하고 제품 취소 또는 resolver 취소 후 join·결과 부재를 검사해 exit 1을 요구한다. 이 실패 경로는 sim을 읽지 않는다. 정상 분기는 thread null 확인 뒤에만 fingerprint를 읽는다. 동기 join이 멈추면 외부 소유 Job 상한이 적용되며, 그 경우 기록된 실패를 성공으로 바꾸지 않는다. 정적 순서 검사 및 timeout·join 중단·정상 결과와 timeout 혼합의 합성 반례를 확인했다. 실제 Godot 파싱, worker join 및 Job 처리 실측은 아니다.

행 18은 실제 제품 버튼에 viewport 입력으로 재출격·skip하고 다른 resolver의 시작, 같은 Brief, 두 번째 취소·join·결과 없음·반복 poll을 관측하도록 구성됐다. 두 번째 사이클 누락 합성 자료를 거부한다. 취소 실패 시 별도 실패 경로를 타며 정상 결과로 집계하지 않는다. 실제 버튼·결과의 동작은 아직 검증되지 않았다.

alias probe는 실제 두 callback 및 별도 synthetic patch를 동일 시점에 독립 BattleSim 기준과 비교하고 reinf/combat 참조, 사후 원소 변경 및 강제 증원 사건을 확인하도록 구성됐다. callback 실행과 제품 경로의 실측 및 transform 재적용 표식, typed 원문 전체의 완전성은 실행 전 oracle·결과 심사 대상이다. 기존 기록만으로 통과를 주장할 수 없다.

7종 suite 분모, GUI 연속 foreground·입력 출처, 실제 Godot console 자손 및 실제 중첩 Job 거부가 미해결이다. manifest와 runner의 fail-closed를 유지하고 21행 전체의 완성된 명령·입력·판정·SHA·소유권을 별도 독립 재심하기 전 K6을 시작하지 않는다. K1~K5와 실패 기록, 원본 checkout/Git/HTML/P03을 보존한다. 이 판정은 제품 적용이나 5-b가 아니다.
