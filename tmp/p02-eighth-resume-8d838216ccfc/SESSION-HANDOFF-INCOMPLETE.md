# P02 여덟째 조각 재개 중단 인계

준비 단계에서 중단했다. 원본 제품 코드는 미적용이다. [기존 격리 후보](../p02-eighth-20261108/candidate-product.patch)와 [이전 실행 근거](../p02-eighth-20261108/IMPLEMENTATION-EVIDENCE.md)를 보존했다. P02/I01/I01b/A04~A06은 **NOT_READY**, 외부 save schema는 **UNCLASSIFIED**다.

K1~K5를 시도 한도에 포함하며 K6은 미실행이다. 한 회가 남았다. K1·K2 비정본, K3 일부 native 비교, K4 정상 완료·취소 viewport 관측 및 별도 오류 주입 후 재시도 실패, K5 입력 주체 미확인 판정은 유지한다. K4 오류 주입 후 재시도는 175초 내부 제한에 도달해 join 단언이 실패했고 exit 1이었다.

[준비 V5 독립 심사](REVIEW-PREPARED-V5-INDEPENDENT.md)는 실행 반려를 유지했다. 계획 21행, 58개 프로세스, 직렬 상한 20,270초 및 명시 의존성 201개는 사전 산정·확인이다. V5 행 17 timeout 경로는 먼저 실패를 기록한 뒤 취소·join과 결과 부재를 검사한다. 정상 분기만 join 이후 fingerprint를 읽는다. timeout·join 중단 및 혼합 결과의 정적·합성 검사와 실제 Godot 파싱·worker join·Job 처리 검증을 분리한다. 행 18 두 번째 취소·재출격, alias 프로브도 준비 상태다.

## 재개 전 필요한 검증

1. 7종 suite의 권위 있는 원문 기준선에서 케이스 및 단언 전체 분모를 동결한다. 실행 manifest에서 각 suite의 원문·기대 exit·실패 규칙·명령을 분리한다. 기존 일부 기록을 전체 분모로 대체하지 않는다.
2. [실행 계약](K6-EXECUTION-CONTRACT.md)과 [행 14·16 개정](K6-EXECUTION-CONTRACT-v2.md)의 창 소유·입력 귀속 전제부터 검증한다. 읽기 전용 Win32의 비대상 전경 조회는 API 동작만 확인했다. 승인된 사전 검증에서 실제 Godot 프로세스 생성 시각·PID·이미지 SHA, native HWND 및 소유 PID, nonce 제목, client rect/DPI, Sky의 유일한 창을 대조한다. 연속 foreground 관측의 heartbeat·손실과 목표 창 이탈을 구분할 수 있어야 한다. Sky 입력 요청·OS 이벤트·Godot 수신의 시간·종류·좌표/키를 연결하고 물리 입력이나 다른 주입과 혼재 시 실패 처리하는 절차를 독립 검토한다. 관측 및 귀속을 검증할 수 없으면 GUI는 미완료로 남긴다.
3. 실제 Godot console 자손의 소유·종료와 중첩 Job 거부를 별도 승인된 사전 점검에서 확인한다. 결과와 정리 원문을 저장하고, 실패하거나 확인이 불가능하면 실행을 보류한다. 사전 점검을 K6 제품 결과로 집계하지 않는다.
4. 단일 K6 실행 계획에서 21행 전량의 명령·입력·기대값·증거·시간 상한·SHA와 실행 소유를 확정한다. 현재 동결을 재검사하고 독립 재심 전에는 K6을 시작하지 않는다. 실행 결과의 독립 5-b를 통과해야 원본 제품 적용과 마감을 검토할 수 있다. K 상한과 기존 실패 원문을 보존한다.

[진행표](../../docs/battle-core/pc-campaign-design/P02-PROGRESS-CHECKLIST.md)의 미완료 구역만 갱신했다. 갱신 직전 바이트는 [before](P02-PROGRESS-CHECKLIST.before.md), 전후 해시는 [SHA 기록](P02-PROGRESS-CHECKLIST.sha256.json), 변경은 [diff](P02-PROGRESS-CHECKLIST.diff)에 있다. 기존 ZIP, Git, HTML, P03 및 기존 후보는 보존했다.
