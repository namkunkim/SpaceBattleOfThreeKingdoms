# 복귀 거절 실행 V3 독립 심사

판정: 고정 manifest의 격리 attempt-01 한 회 수용. 제품 원본과 엔진을 심사 중 실행하지 않았다. 승인 파일은 EXECUTION-INDEPENDENT-APPROVED.json이며 V3 review-only SHA에만 결합된다. 이 조각 0/6에서 첫 회이며 PC0 2/2와 기존 여덟째 K6은 별도다.

V1 root signal과 exit 혼동은 signal=0, exit=expected로 정정됐고 lane별 정확한 ID 순서와 PASS 행을 대조한다. 20 lane/각 timeout 합계 1950초는 준비 및 정리 포함 전체 벽시계 보장이 아니다. 검토 시 승인 파일 12개, source 1480 및 baseline 경로는 현재 SHA와 같고 attempt-01은 없다. 승인은 실행 직전 runner의 Git/index 및 source 전체 재대조에 종속된다. V1/V2의 준비 이력은 보존한다.

격리본에서 live battle을 만든 뒤 미캐시 WorldMap만 임시 rename하고 실제 버튼으로 엔진 오류를 발생시키며 복원 후 같은 버튼으로 재시도한다. actual parse/cache/rename/엔진 오류/scene_changed·1회 소비는 가설이며 불일치·timeout·누락은 실패로 기록한다. 강제 종료 결과는 자연 종결이 아니고 signal 발화는 OS 입력이 아니다. 파일 이동은 격리 project에만 적용하고 중단시 held 파일과 원문을 보존한다. 원본 및 다른 사용자 데이터를 건드리지 않는다. 결과·pause·준비 실패 각 화면과 이전 queue identity를 구분하며 기존 go_battle 회귀를 보존한다.

직접 root Job 및 root 실제 종료와 active 0 증거를 요구한다. OS 호출과 파일 I/O의 절대 deadline은 보장하지 않고 보유하지 못한 단명 자손의 정체도 주장하지 않는다. 엔진 stdout 대신 engine.log를 사용한다. 종료 진단의 패턴 분리는 5-b의 before/after 원문 비교 대상이며 자동 허용만으로 무누수 또는 신규 진단 부재를 주장하지 않는다. 예상된 로더/경고 수·스크립트 오류는 실제 결과에 의해 검증하고 예외를 넓히지 않는다. 원본 반영은 별도 독립 5-b 및 보호·소유 재대조 후 결정한다.
