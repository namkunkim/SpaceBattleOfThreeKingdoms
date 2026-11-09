# K6 v2 정정 독립 심사

판정: **행 9 계약 정정과 후속 구현 분해를 수용한다. 제품 실행과 최종 manifest는 미승인이다.** `K6-SINGLE-RUN-REVIEW-v2.md` SHA-256 `b67a2d30d8d750eb632f6bd931b2601064581a2f782a1de7b7b17bdf63010717`, `K6-V2-MANIFEST-DELTA.json` `5f8b914555a19d1b8d755aa6ac2f5c159b88016321d608fcf72b11a0cbbb8adf` 확인. 심사 turn 실제 metadata는 gpt-6.1-terra다. 제품 실행·import·GUI·Job 시험은 하지 않았다.

행 9의 direct/auto × -1/4294967296 네 성공과 invalid/빈 mode 두 거절, 성공 계측 `[1,1,0,0]`, 거절 `[1,0,0,0]`, 10/14 단언은 `prepared/rejection_v2.gd`의 `factory_contract`와 일치한다. 성공 sim 미생성으로 state 단언이 생략되면 실패라는 조건도 필요하다. 이는 정적 계약 정정이지 실제 통과가 아니다. Key 2의 select 경로는 `input/battle_input.gd`에 있으나 play 상태·할당된 group 2·선택·focus 및 실제 OS 입력은 아직 입증되지 않았다.

현재 HEAD는 `0be09755b70378286105972f35ac5b7031715664`다. P03 active 파일은 HEAD 대비 +9행, SHA `46b6fe191166ec3dcdb620f51c3ccd391a9080f52289517ae804bf86cecc1ea3`; worker는 +2행, SHA `393b20d8e72eb86d13ab7ee10d5d36d97a592e9c03b2e4664f380e34c4f3237e`로 앞선 관측과 일치한다. 이는 한 시점의 정렬일 뿐 동시 작업의 향후 변경이나 관측 사이 불변을 보장하지 않는다. HEAD 기준 lane은 활성 P03과의 결합을 검증하지 않으므로 명시된 한정 범위만 판정한다. 적용 전에는 현재 hunk·입력과 P03 보호를 재확인해야 한다.

다음 준비는 다음의 독립 산출물로 나눌 수 있다.

1. Q/C/B의 참조 함수·fixture·type·ID와 제품 측 관측을 각각 코드/입력 SHA로 동결한다. 특히 B의 네 stage 예상 경로를 scene과 동적 구성에서 사전 유도한다. 동일 결과를 기대에 복사하는 순환과 누락·중복·순서·type 변형의 합성 반례를 거부한다. 미확정 값은 제품 실행 전에 임의로 채우지 않는다.
2. 제품 없는 최소 프로젝트에 V5 broker와 동일 구조의 outer/inner Job 및 global watchdog을 구현한다. blocking stage와 실제 engine의 정상/timeout, 비소유 sentinel, 실패 기록·bounded cleanup을 검증하고 nested assign 거부가 재현되지 않으면 미검증으로 둔다. 작업 전후 원본/인덱스 및 격리 경로를 관측하고 filesystem 쓰기 경계와 reparse escape 차단을 별도로 검증한다. Job 소유만으로 filesystem 차단을 주장하지 않는다.
3. GUI는 실제 사용 API가 Sky 요청과 OS 이벤트를 독립 결합할 수 있는지를 우선 확인한다. 이를 증명하지 못하면 행 15/16과 전체 K6은 대기한다. 별도 승인된 대체 입력 계약은 새 기준과 반례 심사가 필요하다. 관측 수단 부재를 viewport 또는 injected flag로 대체하지 않는다.
4. 위 산출물과 비제품 시험 결과를 독립 심사한 뒤 21행 전부의 정확 argv/env·input/overlay/oracle/engine SHA·expected exit·raw output·global/per-job deadline·소유권을 포함하는 실행 불가 기본값의 최종 manifest를 작성해 별도 심사한다. 산술 20,270초는 실제 총 wall time 보증이 아니다. 행 17의 175/320과 K4 실패를 보존한다.

K1~K5는 계속 한도에 산입하고 최초 제품 import를 포함한 제품 프로세스 시작으로 마지막 K6이 소진된다. Q/C/B나 GUI·Job 실측, 전역 watchdog 및 최종 manifest가 없는 현재 제품 실행은 금지다. 본 심사 파일 외 기존 파일은 변경하지 않았다.
