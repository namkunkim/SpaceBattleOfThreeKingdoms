# P02 legacy WorldMap 결산 경계 결과

2026-11-08 KST. 독립 구현 5-b **한정 수용**. 전달물 독립 마감 판정은 별도 기록한다. P02/I01/I01b/A04~A06 **NOT_READY**, 외부 save schema **UNCLASSIFIED**.

legacy 자동 해결 worker가 기존 시계와 종료 조건으로 진행한 뒤 승패·사유·시각·지문과 결산 자료의 깊은 사본을 넘긴다. 메인은 join과 취소 확인 후 현재 Brief를 읽어 결산한다. 반환 자료 누락·오류의 fallback은 join을 마친 legacy sim에서만 수행한다. 직접 지휘와 blocking은 기존 `BattleOutcome.from_sim`으로 결산한다. [구현과 실행 증거](../../../tmp/p02-fifth-20261108/IMPLEMENTATION-EVIDENCE.md) · [독립 구현 5-b](../../../tmp/p02-fifth-20261108/REVIEW-5B-INDEPENDENT.md)

- v3 사전 5개 중 4개 통과, 사후 6개 중 5개 통과. 양쪽 clean-user WorldLink는 기존 `tests/world_link.gd:239`의 prologue/brief 단언 하나로 exit 1이다. returning-user WorldLink는 동일한 격리 설정으로 양쪽 통과했다. common과 두 WorldLink의 종료 시 ObjectDB/리소스 진단은 각각 215/18, 154/20, 154/20으로 같다. 사후 전용 경계 탐침은 181/18을 기록했다. [사전 실행](../../../tmp/p02-fifth-20261108/v3-before-attempt-02/processes.json) · [사후 실행](../../../tmp/p02-fifth-20261108/v3-after-attempt-01/processes.json)
- 공통 18행·106단언은 사전·사후 각각 실패 0이다. 입문 seed 11 자동 자연 종료와 blocking 결과가 같았다. 직접 seed 777은 실제 서막 건너뛰기·자동 편성·결과 버튼을 거쳤고 10 tick에서 종료를 주입했다. 자동·직접 결과 전필드와 카드 라벨·권역 소유는 사전 고정 오라클과 일치했다. 직접 인계는 1회 소비했고 자동 중단 버튼과 씬 제거는 join·미게시를 확인했다. [고정 오라클](../../../tmp/p02-fifth-20261108/v3/original-outcome-oracle.json)
- 사후 경계 7행·33단언은 실패 0이다. null·상위/중첩 형태 오류 뒤 join fallback, cancel과 poll의 메인 호출 순서, 중첩 사본의 양방향 변이를 검사했다. worker adapter는 각각 59검사, headless adapter는 각각 8사례·13,417검사·32거부를 통과했고 headless 결과 바이트가 일치했다. [종합 판정](../../../tmp/p02-fifth-20261108/v3/gate-verdict.json)
- 최초 v2 사전 4개 실행은 별도 실패 이력이다. 공통 99단언 중 A03과 A06이 실패했고 clean WorldLink도 같은 단일 단언에서 실패했다. 그 시도의 A03은 서막 이후 제품 버튼을 우회했으므로 정본 오라클에서 제외했다. v3 사전 2차·사후 1차의 결과를 사용했다. [첫 시도](../../../tmp/p02-fifth-20261108/before-attempt-01/processes.json)
- 제품 구현 시점의 12,281개 기준선에서 소유 두 파일만 바뀌었다. 격리 사전 입력은 4,209개이고 사후 전용 탐침 하나가 추가됐다. 신규 미귀속 158개 경로는 실행 입력과 겹침이 없고 두 관측 사이 바이트가 일치했다. 첫 관측 이전 상태와 소유는 미확인이다. [독립 보존 판정](../../../tmp/p02-fifth-20261108/REVIEW-CONCURRENT-FILES-INDEPENDENT.md)

제한 operation owner는 제품 적벽 입력과 Victory 결산을 지원하지 않는다. WorldMap operation 시작·진행·취소·결산, FleetBattle3D operation 소유권과 제품 replay는 남는다. 실제 1800초 상한 도달, OS Thread.start 실패, 엔진 예외, 동시 writer와 손상 sim은 미검증이다. UI 검증은 headless 제품 경로와 라벨에 한하며 수동 GUI·Android·성능은 미검증이다.
