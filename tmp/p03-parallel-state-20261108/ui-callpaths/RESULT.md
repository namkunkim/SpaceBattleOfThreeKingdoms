# 유보 8셀 UI 호출·표시 경로 결과

[경로 원장](UI-CALLPATHS.json)은 기존 8개 ui_publish 셀에 현재 생산 source, 제한 실관측, 범위 내 직접 제품 호출 미발견 및 미검증을 구분했다. 생산 .gd/.tscn 95개와 지정 lexical 후보 32행을 고정했다. lexical 행에는 정의, 주석, 내부 호출이 포함된다. 관련 실제 producer/consumer 위치는 별도 anchor다.

현재 raw FleetBattle3D의 issue→sim.issue→trace→pump, frame step→projection→filtered event, 최초 게시의 별도 raw drain, terminal→WorldLink를 추적했다. 제한 worker와 fresh replay는 별도 owner 경로다. 조사 범위의 capture/restore와 제한 operation 시작/종료는 정의만 확인했고 정상 제품 호출을 찾지 못했다. 테스트·동적 로드·reflection·외부 경로는 범위 밖이다. _process의 _sync는 경우에 따라 마지막 틱 전의 이미 끝난 상태를 보간 기준으로 읽는다. 이 정적 순서로 step 내부 노출이나 동시 실행 안전성을 확정하지 않았다.

raw/filtered는 같은 큐의 대안 소비다. 최초 raw drain과 후속 frame filtered pump는 서로 다른 시점이다. legacy UI 오류 안내와 private owner busy/closed는 다른 경로다. P02가 기존 UI/worker 게시, P03이 내부 상태/가드를 소유한다. 운영 restore 후 제품 UI의 8셀은 미검증으로 유지한다. 사용자 질문을 추가하지 않고 실제 제품 연결 여부는 기존 HOST_AUTHORITY, 필요 시 외부 전달은 DELIVERY_MODE에 남겼다.

첫 준비 호출은 P02 진행표 SHA 동시 변경을 검출해 exit 2였다. [실패 기록](prepare-01/stderr.txt)과 기존 SHA/후보를 보존했다. 최신 진행표와 여덟째 재개 인계 및 준비 V5 독립 심사를 재확인했다. V5는 K6 실행 반려이며 제품 적용 증거가 없다. 새 두 근거를 포함해 production 95개 범위와 8셀 판정은 그대로 두고 106개 source/근거를 다시 동결했다.

| 사례 | 실제 exit | 결과 |
|---|---:|---|
| normal | 0 | 8개 정확 tuple 및 근거 필드 |
| row_omission | 1 | QUEUE_RETURN/ui_publish 누락 한 건 |
| busy_misclassification | 1 | BUSY_OR_CLOSED의 제품 UI 검증 승격 한 건 |
| missing_anchor | 2 | absent.gd 경로 오류, 비교 결과 없음 |

[attempt-02 suite](attempt-02/suite.json) actual exit 0, 4/4 일치. manifest SHA256 4d344c30ddb6754969f917428f0023d023cf279975fa75fffc918ad7d74811c5. 118개 입력 SHA 및 HEAD 전후 일치. [Git 비교](attempt-02/git-comparison.json)의 10행은 모두 전용 경로이며 실행 중 P02/외부 변화 0이었다. 사전 준비 시 P02 drift와 실행 전후 상태 비교는 별도다. 전체 dirty 파일 바이트 불변을 주장하지 않는다.

신규 Godot/UI 실행, 생산 코드·공유 체크리스트 변경 및 정책 채택은 없었다. P03/I01/I01b/A04~A06 NOT_READY, O07 OPEN, 외부 스키마 UNCLASSIFIED. 독립 사후 5b 대기.
