# P03 pending과 suffix의 순서 및 외부 소비 관측 계획

2026-11-08 KST. 독립 Terra 계획 심사 대기. 구현과 실행은 심사 수용 후 시작한다. 구현 담당 /root/remaining_sol의 명시 gpt-6.1-sol 모델 배정 및 별도 ID를 사용자가 인정한 근거로 기록한다. 실제 서빙 모델은 미검증이다. 시작 HEAD, porcelain, 경고, 읽은 입력의 SHA-256을 별도 기록했다. P02 긴 경로 경고 2건으로 전체 status는 완전한 보존 근거가 아니다. 쓰기는 이 새 폴더만 사용한다.

## 범위와 가설

H2-02, D04 ST02/ST18 및 §4, I01 K05~K07·A06을 기준으로 공개 in-memory owner API의 serial 경계를 관측한다. 구조 접수는 적용과 다르다. battle_sim.gd:95–102,142–180에서 queue는 append만 하고 issue와 step 첫머리가 당시 tick으로 log를 쓴다. operation_private_state.gd:189–248,272–294의 owner 결과는 구조/호출 가드와 raw 소비를 제공한다. 논리 rejected는 사건이고, pending 및 미소비 사건은 packet 내부에 있다. 현재 API에는 외부 커밋·ack가 없다. 이전 역사 suffix는 올바른 이어붙임과 배열상의 잘못된 절단점을, 별도 viewer 검사는 필터 소비 전후를, v2 fresh replay는 terminal의 지역 미소비를 관측했다. 이번에는 실제 owner API에서 잘못된 suffix의 **실행**과 같은 packet 재복원 이후 **owner 밖 수신기**를 함께 비교한다.

기존 command_suffix.gd의 프로필·seed·hz·controls, tick2까지의 전진 방식 및 Q/S/I/R 명령 리터럴을 재사용한다. 시작 시 양측의 초기 raw 사건을 소비한다. tick2에서 동일 형식의 Q(move id1), S(stop id1)를 순서대로 queue한 뒤 I(stop id1)를 issue한다. 이후 패킷 P를 캡처한다. 기대 P는 log [I], pending [Q,S], 미소비 [say(stop)]이며 raw oracle과 대조한다. 구조 거부 X는 R의 kind만 unsupported_for_probe로 바꾼 후보이고, R은 존재하지 않는 id999의 stop이다. 이후 suffix의 큐 접수 정책은 관측용으로 명시하며 제품 계약으로 간주하지 않는다.

독립 raw oracle은 같은 fixture의 별도 BattleSim 직접 호출로 작성한다. adapter/owner/replay의 명령, capture/restore, fingerprint 단독 비교를 oracle로 쓰지 않는다. raw oracle은 각 case의 접수 순서 및 드레인 호출을 코드에 별도 명시하고, 적용 log와 사건·tick·clock·fleet 주요 상태를 직접 읽는다. P 이후 raw oracle은 같은 prefix를 fresh에서 재현하며 checkpoint 복원 자체를 모사하지 않는다. 정확한 명령 값, Variant 타입과 배열 순서에 대한 수기 기대 및 raw 동작을 모두 요구한다. say/rejected의 전체 raw payload는 원문 독립 oracle과 비교하고, 수기 기대값은 해당 사건의 kind/value와 순서다. unrelated 사건은 raw 전체 대조에는 포함하고 수기 명령 사건 배열에서는 say/rejected만 선택한다.

## 사전등록 검증 분모

이름당 정확히 8개 단언, 4명명·32개다. 각 번호는 묶음 조건을 가진 단일 Boolean 단언이다. 실패 시 케이스·ID와 실패한 분기/세부 조건을 따로 기록한다. 2–4는 P와 동일 context에서 새로 준비한 owner를 복원해 별도 실행한다. 각 owner는 검사 후 닫는다. close 실패는 해당 항목의 실패에 포함한다.

1. correct_pending_and_suffix — ① 전진한 P 캡처와 raw tick2/clock 일치 ② P의 log/pending/event 리터럴과 raw 일치 ③ X queue 정확 구조 거부 및 P와 전체 packet 동일 ④ R queue 수용, log/events 유지, pending [Q,S,R] ⑤ advance 성공, pending 빈 배열, log [I,Q,S,R], 각 tick2 ⑥ raw와 tick/clock·fleet 상태 대조 ⑦ ordered drain 전체 raw 대조 및 stop/move/stop/no_selection 순서 ⑧ 재드레인 성공·빈 배열 및 close.
2. duplicate_pending_in_suffix — ① P 복원 후 packet 정확 일치 ② 외부가 이미 packet에 든 Q를 재주입하면 구조 수용 ③ R도 수용하고 적용 전 log/events 동일·pending [Q,S,Q,R] ④ advance 성공·pending 비움 ⑤ 적용 log 정확 [I,Q,S,Q,R], 두 Q 같은 값 ⑥ raw와 tick/clock·fleet 상태 대조 ⑦ ordered raw 사건 전체 일치 및 stop/move/stop/move/no_selection 순서 ⑧ 올바른 대조군과 적용 log 및 사건 차이·재드레인 빈 배열·close.
3. reordered_or_omitted_suffix — P에서 외부 후속 S,R을 큐잉하는 별도 올바른 비교군과, R,S 및 S 단독의 별도 owner/독립 raw 분기를 실행한다. ① 세 복원에서 packet P 정확 일치 ② 세 큐 배열 및 접수 반환 정확 ③ 세 advance 성공·pending 비움 ④ 정상 [I,Q,S,S,R] ⑤ 변경 [I,Q,S,R,S] ⑥ 누락 [I,Q,S,S] ⑦ 세 분기의 ordered drain 및 tick/clock·fleet 상태 raw 비교, 수기 사건 순서 정상 [stop,move,stop,stop,no_selection], 순서 변경 [stop,move,stop,no_selection,stop], 누락 [stop,move,stop,stop] 확인 ⑧ 세 owner 재드레인 성공·빈 배열·close. 모든 log 행은 tick2다.
4. consumer_outlives_restore — ① P 복원 동일 ② raw drain 성공·P의 사건 전체와 동등·외부 Array에 수신 append ③ 같은 tick의 소비 후 packet D 캡처, P와 tick/clock/log/pending 동일 및 events만 빈 배열 ④ P 복원 후 외부 Array 유지·owner P 동일 ⑤ 두 번째 raw drain 성공 및 첫 payload와 순서/값/ID(실제 제공되는 키만) 동등·외부 Array에 재수신 append ⑥ 외부 Array는 전체 ordered payload 두 번 보유 ⑦ D 복원 및 raw drain은 성공·빈 배열이고 외부 Array는 두 사본 유지 ⑧ close 성공. 수신기는 테스트 코드의 Array이며 실제 UI, 효과, persistence 또는 ack를 검증하지 않는다. 원문 raw event에 ID가 없다면 ID 부재를 기록하고 같은 ID를 주장하지 않는다.

## 게이트와 범위 제한

승인 후에만 runner를 작성한다. 정본 프로젝트와 class cache, class map이 가리키는 스크립트·core·autoload·필요 데이터와 실행 설정, runner, 실제 Godot console 및 엔진 본체를 SHA-256과 크기로 동결하고 실행 전후 대조한다. preflight에서 실제 실행 파일, canonical resource path의 파일 매핑, class map의 모든 해석 대상 및 필요 데이터/설정과 runner를 확정 목록으로 기록하고 존재·SHA·크기를 확인한다. 누락·해석 실패·확정값 불일치는 원문을 기록하고 Godot을 실행하기 전에 중단한다. 종료 후 같은 목록을 재검사하며 목록 변경·파일 누락·SHA 또는 크기 차이는 실패다. 기존 Job launcher 방식의 전용 프로세스 종료 제한을 재사용하고 canonical resource_path와 엔진 본체를 확인한다. 파일 단위 범위 및 동시 변경은 시작/종료 status와 입력 전후 해시로 확인한다. 시작 status 기록은 자체 기록 파일을 생성하므로 상태 출력에 경로가 나타날 수 있다. 기존 P2c CRLF 편차와 신규 변경 검사를 분리한다.

5-a는 actual exit 0, 정확한 CASE_START/CHECK/CASE_END 순서와 32 PASS, 신규 SCRIPT ERROR/ERROR/WARNING/누수 0, timeout 없음, Job 종료, 입력 전후 해시 일치를 요구한다. 시도별 stdout/stderr 원문, 실제 종료 코드 또는 미실행, 시작·끝 목록과 실패 이유를 보존한다. 수정 가능한 코드 게이트는 K=6이다. 환경/사용량 제한, timeout, Job 종료 실패, 입력 해시 불일치, 예상 밖 범위 변경은 즉시 중단·보고하고 원인 해소와 재심사 전 자동 반복을 금지한다. 가설·분모가 달라지면 스펙 재심사. 5-b는 구현과 별도 Terra가 oracle 독립성, fixture와 단언, raw 로그, 해시 및 범위 차이를 검토한다.

전체 P03/I01/I01b/A04–A06 NOT_READY, O07 OPEN, 외부 저장 schema UNCLASSIFIED. 운영 Cn, 글로벌 seq/cursor/commit, 실제 host 게시·ACK와 idempotency, worker/concurrency 및 지원 밖 모듈은 별도 인수다. 패킷 변경이나 공통 구현 변경 없이 관측하며 P02 작업의 적용 책임을 재배정하지 않는다.
