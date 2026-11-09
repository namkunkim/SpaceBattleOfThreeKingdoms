# C 실제 producer·통합과 K6 전진 경계

상태는 독립 검토 전 설계다. C v9 제한 합성 수용을 실제 자료로 확장할 다음 조각이며 기존 v4~v9 판정기를 다시 반복 개정하는 작업은 종료했다. 제품 code, 테스트, P03, Git, HTML은 수정하지 않았다. 제품/Godot/GUI/Job 실행은 0회다.

## 실제 호출 분모 정정

- tests/i01b_service_state.gd::_detection은 202행에서 시작한다. 첫 _restore, mutated-pos packet을 직접 Service.restore_into_prepared_target로 넘기는 negative control, repaired _restore 순서다. 두 _restore 각각은 145행 함수 안의 primary apply 후 detach 검사 및 마지막 repeated apply를 수행한다.
- 따라서 정상 detection segment마다 호출은 **5회**다. first.primary → first.repeat → wrong-position.primary → repaired.primary → repaired.repeat. 10 seeds×2 wanted = lane당 20 segment와 100 호출, 두 lane에서 40 segment와 200 호출이다. v6/v7 raw plan은 first/repaired의 repeat 2회를 포함하지 않고, v9는 세 의미 phase까지만 확인한다. 이 셋을 연결한다고 전체 실제 호출 분모가 되지는 않는다.
- 최초 부정값 재현과는 별개로 wrong-position은 성공해야 하는 negative control이다. Source record.pos 하나만 실제 live position으로 바꾼 잘못된 packet을 넣은 뒤 target fingerprint와 contact가 독립적으로 달라짐을 검사한다. 정상/잘못된 위치/복구에 필요한 성공 receipt를 거절 결과와 혼동하지 않는다. Normal detection segment의 위 5회와 _refusals의 기존 33 case는 별도 분모다.

## Producer 삽입 지점과 유지 조건

1. 격리 overlay에서 source path와 SHA가 승인된 두 위치만 계측한다. core/battle/detection.gd::_eval(151행)의 side 1 body 진입 직전과 tests/i01b_service_state.gd의 fixture/restore/alias/suffix 경계다. Product 변경 patch는 기존 허용 세 파일에서만 비교하며 계측은 before와 after에 동일 diff를 적용한 별도 증거 layer다. 원본 operation_private_state/P03는 쓰지 않는다. 각 anchor가 정확히 한 번 나타나는지 먼저 검증하고 diff와 SHA를 동결한다.
2. _fixture가 반환한 a/b에 각각 run-scoped simulation token을 배정한다. Instance ID를 PID나 주소만으로 표현하지 않고 producer가 생성 시점에 1회 발급해 기존 object identity와 대조한다. Fresh before/after process는 별도의 run ID를 받는다. Canonical ordinal은 원본 JSONL single-writer에서 발급한다. Mono clock과 sequence를 분리하고, 로그 손실·출력 제한·재시작·ID 재사용을 fail closed 한다.
3. _eval 앞 증인은 실제 tick, side, fixture token, 양 fleet raw positions와 offsets, alive/구성, stat, modifier 및 sensing 입력을 읽는다. Score 결과나 live contacts를 증인에 복사해서 기대를 만들지 않는다. Producer는 동일 fixture와 함수에서 실제로 수집한 값을 주석·파일명 대신 raw source record에 넣는다. Nonnegative EW와 conceal을 증명할 원재료, zero view, 각 fixture의 초기 빈 side 1, 1/11 및 이동 후 정해진 eval ticks를 모두 보존한다. 기존 v4의 보수적 geometry 조건을 충족하지 못하면 양쪽이 비어 있어도 미완료다. 동일한 케이스 내 기록 없는 side 1 contact를 자동으로 비워 채우지 않는다.
4. Restore wrapper는 한 호출마다 source/target/packet pre snapshot, actual packet bytes와 request id, source/target object tokens를 기록한다. 실제 메서드를 원래 위치에서 한 번 호출하고 바로 actual return DTO, packet bytes 및 source/target post snapshot을 기록한다. first/repaired primary 및 repeat의 request/result를 따로 구별한다. 잘못된 위치 control의 mutation source를 record.id와 독립 fixture pin에서 결정한다. 기존 조건식의 short-circuit 및 함수 호출 횟수, _check 순서, packet mutation 위치, original source/target cleanup을 보존한다.
5. _all/_outside/_selected에서 실행 전후 ordered typed raw data를 저장한다. Source·원본 packet·target 외부 상태는 호출 전후 같아야 한다. 첫/repaired primary는 selected만 expected packet으로 바뀌고 반복 적용은 _all 전체와 published typed fingerprint에 추가 효과가 없어야 한다. wrong-position에서는 동일 외부 상태에서 승인된 pos 차이만 허용한다. 반환 false/예외/누락이 나오면 성공 분모는 실패로 닫는다. 기존 refusal rows는 exact failure code, no-owner 및 source/target/packet 전체 무변이를 별도로 검증한다. 진단을 얻기 위해 실패한 호출을 다시 실행하지 않는다.
6. Detach 증거는 원문 is_same checks, module/fleet 유지 및 contact arrays/books/records의 참조 비교를 각각 ID로 기록한다. 실제 packet contact를 변경한 뒤 source와 target 원문을 다시 읽어 비교하는 기존 alias 반례를 별도 event로 보존한다. 읽기 전후 source/target 상태와 동일 fixture의 ordered suffix fingerprint/state/events 및 command log 단언은 geometry certificate 대신 사용하지 않는다.

## 하나의 입력에서만 결합

원본 JSONL의 before/after 별 hash, launcher-owned HANDLE/PID creation, run ID, engine/overlay/cache manifest, raw row offsets·sequence를 동결한다. 판정기는 승인 기록에서 가져온 manifest SHA와 source/fixture closure를 먼저 검증한다. Candidate 결과로 expected pin을 만들지 않는다. 독립 typed context는 고정 source/fixture build derivation 및 승인 record에서 얻어야 하며 아직 제품 context bytes는 확정되지 않았다.

원본 per-lane 순서를 검증한 뒤 single run/instance/case/tick/request token으로 projection한다. v4 witness, v7 causal receipts, v9 pre/post inputs와 _all/detach 확인은 **같은 원본 row bytes와 hash**를 참조한다. 서로 다른 실행의 정상 값을 조합하거나 중복 receipt를 제거해 기대 수에 맞추지 않는다. Revised causal order의 다섯 restore calls, request/result parity, expected packet bytes, target snapshot, repeated no-op과 negative-control drift를 모두 확인한다. 기존 8,960 geometry/80 initial/160 scoped capture 가정은 각각 독립 witness 수이며, 200 restore calls의 결과 분모와 합산하지 않는다.

## 전진 게이트

- 7suite 행19의 headless Q는 native policy/제품 queue/typed packet 및 fixture tick, C는 실제 pre-eval 증인, WorldLink 행21 B는 실제 ordered button/action 경로가 필요하다. Historical totals와 합성 pass는 runtime 증거가 아니다. 행20 legacy 비교 조건은 보존한다. Actual product fixture를 별도 사전 실행하는 대신 최종 단일 K6 안에서 수집한다.
- 별도 비제품 ABI 시험은 product import 없이 실행 가능한 종류의 시험이다. 정확한 두 파일 source와 argv, Godot SHA, 관측 분모를 독립 심사에 제출했다. 파일시스템 격리와 소유 Job이 입증되기 전에는 ABI도 실행하지 않는다. ABI 결과는 C semantics, GUI, 전체 K6를 통과시키지 않는다.
- GUI Sky의 요청별 OS provenance는 문서화된 API에서 입증되지 않았다. Read-only window nonce/PID/HWND snapshot은 별도 격리 환경에서 관측할 수 있으나 요청별 입력 귀속에 필요한 증거를 만들지 않는다. 승인된 per-request receipt/독점 경계가 없으면 행 15/16과 K6 전체를 대기시킨다. 활성 사용자 desktop에 입력이나 hook을 보내지 않는다.
- 실제 process/HANDLE membership, nested outer/inner Job 및 timeout cleanup, FS confinement는 비제품 W1~W5 설계와 별도 수용이 선행한다. Environment/path checks만으로 FS 격리를 주장하지 않는다. 실제 OS 지원 도구가 없거나 독립 심사자가 경계를 수용하지 않으면 미검증으로 닫는다.
- 위 선행 결과 및 실제 21행 argv/env/immutable full closure/expected cases·oracle/timeouts·Job/capture를 독립 수용한다. 175/320 및 약 5시간 38분 cap 산술과 실제 준비·정리 시간을 구분한다. Product 최초 import 또는 최초 검증 spawn부터 마지막 K6 한 회가 소진된다. 부분 성공 후 재시도하거나 기존 합성/과거 성공을 집계하지 않는다. 실제 제품 원본 반영은 완결된 K6와 별도 독립 5-b 뒤에만 검토한다. HEAD lane은 활성 P03 +9 결합을 증명하지 않는다.
