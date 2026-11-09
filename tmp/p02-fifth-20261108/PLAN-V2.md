# P02 다섯 번째 조각 수정 계획 v2

2026-11-08. 독립 재심 대기. PLAN.md 원문 SHA-256 8815a7de71980fe46b2ce1cbe744bb05ff8f7529731d3a1b645482333e7689da. 원 계획의 동결, 보존, K6, 비Astra 독립 심사를 승계한다. 아래가 계약 및 검사 분모의 정본이다.

## 계약과 허용 hunk

- legacy WorldMap 결산 경계만 변경한다. 제한 owner는 제품 적벽 및 Victory result를 지원하지 않아 summary로 BattleOutcome을 만들 수 없다. 향후 owner와 새 내부 자료의 호환성을 단정하지 않는다. 제품 operation 진입/공통 adapter, FleetBattle3D 시계·controls·배치·명령·투영·사건·선택·카메라·trace, WorldMap operation 진행·취소·결산, replay는 미완료다. P02/I01/I01b/A04~A06 NOT_READY, 외부 save schema UNCLASSIFIED.
- 기존 _loop를 worker에서 동일 시계·종료 조건·진행 갱신으로 실행한다. 미취소 시 worker가 st.win/end_reason/clock_s/result 깊은 사본 및 fingerprint를 반환한다. live sim은 worker 작업 중 외부에서 읽거나 수정하는 계약을 지원하지 않는다. poll은 is_alive 확인과 wait_to_finish 이후 반환을 소비하고 현재 공개 brief의 seed/mode/difficulty를 읽는다. sim/brief 필드의 수명, null 기본값, blocking의 기존 1800초 상한 처리 및 FleetBattle3D의 종료 시에만 결산하는 조건을 유지한다.
- worker 반환값이 null, 누락 또는 형태 오류면 미취소 poll이 join을 끝낸 뒤 기존 BattleOutcome.from_sim(sim, brief)로 복귀한다. 정확한 facts 키 집합(win bool, reason String, t_s float, result Dictionary, fingerprint String)과 사용되는 중첩 cost/양측 original·remaining 숫자, army_morale_bp 최소 두 숫자, commanders 문자열, limited bool을 확인한다. 기존 빈 result와 생략 필드 기본값을 수용한다. 잘못된 반환 자료로 성공을 게시하지 않고 유효한 기존 sim의 원본 결과를 구성한다. OS Thread.start 실패, 엔진 예외 및 손상된 live sim은 미주입이며 복구를 보장하지 않는다.
- 메인에서 poll보다 cancel을 먼저 소비하면 join 반환을 폐기하고 poll false 및 outcome 미게시. 성공 poll 뒤 cancel은 게시 결과를 회수하지 않는다. 동시 start/poll/cancel, 외부 sim 변경은 지원 밖이며 기존 _cancel·진행 공유 필드 동기화 강화는 없다.
- 허용 hunk는 BattleOutcome.from_sim과 facts 추출/결산 함수, AutoResolver legacy start callable/poll join 소비 및 같은 파일의 반환 검증 helper와 legacy worker callable 한 개다. 기존 operation worker와 UI 소스 동결. 하위 클래스가 worker 반환만 대체하는 테스트 전용 대역으로 실제 start/poll/join/fallback을 검증한다. 생산 주입 훅은 추가하지 않는다.

## 제품 호출 및 oracle

- tests/world_link.gd:218 _round_trip은 직접 출격·skip→FleetBattle3D 씬→결과 버튼→WorldMap 결과카드와 링크 소비를 검사한다. tests/world_link.gd:111 _determinism은 제품 AutoResolver의 start/poll/cancel과 blocking을 호출하나 WorldMap 자동 결과카드는 별도 probe가 필요하다.
- 직접 probe는 WorldMap 출격/skip → WorldLink.go_battle → FleetBattle3D 브리핑/시작 → 결정적으로 고정한 tick에서 native _end 주입 → 실제 결과 버튼 → FleetBattle3D.back_to_world → WorldLink.back_to_world → WorldMap._ready/take_outcome/_show_result를 실행한다. 고정 tick은 fixture에서 미리 확정하고 실제 tick을 증거로 기록한다. 해당 호출 경로를 못 밟으면 행 실패로 남긴다. 결과 카드 및 인계 1회 소비(brief/outcome null 및 추가 take null)를 확인한다.
- 자동 probe는 실제 WorldMap 입문 seed 11 출격/skip → _finish_sortie/_start_resolve → _process/poll → _show_result, 별도 실행의 실제 취소 버튼 → _cancel_resolve 및 씬 제거 → _exit_tree의 cancel/join을 검증한다. 성공은 카드 visible, resolver null, resolve 종료, 취소/제거는 미게시와 보유 resolver의 join 후 poll false를 검증한다.
- 양 제품 경로 to_dict 전필드와 ending_text/line_text 및 카드 라벨(eyebrow/title/ending/time/loss_a/loss_f/cao/line/src/seed/regions) 사전/사후 대조. 권역 색/결과 소비도 확인한다. GUI 수동·Android·성능은 미검증.
- 편집 전 baseline 일치 원본 두 파일 사본, 전체 실행 리소스 manifest, 동일 common runner/fixture bytes·SHA, 엔진·classcache와 실제 클래스 경로, 명령·exit·stdout/stderr·전체 결과 SHA를 동결한다. 사후 oracle은 고정 결과를 읽는다. 새 코드로 재생성하지 않는다. 변경 파일 외 실행 입력은 전후 해시 대조하고, 분모/fixture/기대값 수정은 재심한다.
- 별도 상수 표 oracle에서 cost 100/70 및 200/50의 손실 30/75, 999/1000/2999/3000/5999/6000bp의 무승부/근소 우세/근소 우세/우세/우세/결정적 승리, killed/captured/severe/unhurt, limited, time_limit/simultaneous/liu_flagship_lost, null brief·빈 result, E1/E2/E4/E5/E6/E9/E11의 후보 순서 및 seed 선택을 기대한다. 기대값은 새 함수나 native 변환 호출로 산출하지 않는다.

## 분모

- 사전/사후 각각 공통 4 프로세스. product-outcome-common, tests/world_link.gd, tests/p02_worker_adapter.gd, tests/p02_headless_adapter.gd. 사후 product-outcome-boundary 1개를 추가해 사전 4 및 사후 5. 실제 명령·timeout·exit·행·단언을 각기 기록한다. 예상 trace/import 및 생성 파일은 원본 실행 전에 격리한다. 동일 엔진·캐시 및 실행 리소스 경로를 확인한다.
- 공통 probe 18행. A01 실제 자동 성공, A02 동일 blocking, A03 실제 직접 성공, A04 취소 버튼, A05 씬 종료, A06 실제 적벽 profile 지원 밖 거부 code/path, A07 POC 빈 result/null brief, A08 미종료의 기존 fallback, A09~A14 여섯 grade 경계, A15 limited/장수/후일담 후보, A16~A18 세 패배 이유. A09~A15에서 cost 및 후일담 후보 순서·장수 상수도 대조한다. A08/A16은 결산 의미 대조이고 실제 1800초 상한 도달은 미검증이다.
- 사후 전용 probe 7행. B01 null 반환, B02 잘못된 facts 키/타입, B03 잘못된 중첩 타입에서 join 뒤 동일 원본 결산. B04 worker 완료 후 poll 전 cancel에서 비게시. B05 성공 poll 뒤 cancel/반복 poll에서 게시 유지. B06 facts 추출 뒤 원본 cost/array/commanders 변경 시 facts와 이전 결과 불변, 반복 추출은 바뀐 원본 반영. B07 facts 중첩 변경 시 원본과 이전 결과 불변, 새 추출·결산은 고정 원본과 일치. B04/B05는 메인 호출 순서만 증명한다.
- 각 분모와 기대값을 최초 실행 전 고정하고 K6 내 실패/비정본을 보존한다. 원본 checkout·index·HEAD·기존 ZIP·P03·허용 외 전 경로 SHA 보존. 독립 비Astra 계획 재심 뒤에만 구현하며 최종 구현/마감도 독립 모델과 세션 증거를 남긴다. 사용량 제한 발생 즉시 상위 보고 후 해당 작업 중지.
