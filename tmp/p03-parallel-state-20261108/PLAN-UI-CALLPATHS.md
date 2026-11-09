# P03 사용자 선택 유보 8셀 호출·표시 경로 추적 계획

P03/I01/I01b/A04~A06 NOT_READY, O07 OPEN, 외부 저장 스키마 UNCLASSIFIED. 정책 원장의 35개 중 사용자 선택을 보류한 ui_publish 8개만 대상으로 한다. 제품에서 실제 호출 가능한 경로를 고정 소스와 수용된 runtime 증거로 구분해, 사용자에게 넘길 선택을 현재 근거로 좁힌다. 구현, 신규 UI/Godot 실행, 사용자 정책 확정은 이번 읽기 조각의 범위 밖이다. 독립 수용 전 runner/원장 및 5a 실행을 보류한다.

## 정확 범위

기준 [정책 원장](policy-ownership/POLICY-LEDGER.json) SHA256 f7d1d32f63f4c97e533e39fc1fce8ba9ca4f6896ec7c863017461b25dec89cdd. 아래 8개 (행, ui_publish) 튜플은 기준 원장의 user_choice 빈 집합과 일치해야 한다. 이미 선택 축이 있는 POST_FILTERED_DRAIN은 이 분모에서 제외한다. raw/filtered drain은 동일 큐의 대안 소비이며 제품 호스트가 초기 raw drain을 호출한 뒤 이후 사건을 filtered로 처리하는 사실이 동일 사건을 두 번 소비한다는 뜻은 아니다.

| 셀 | 생산 경로와 관측할 화면·게시 상태 | 판정할 경계 |
|---|---|---|
| ISSUE_RETURN | 입력 명령 → FleetBattle3D.issue → raw sim.issue → trace/표시 pump 및 rejected 사건 처리 | legacy 직접 적용·표시와 private owner restore 후의 제품 표시를 구분. trace applied 문자열과 실제 명령 효과 구분 |
| QUEUE_RETURN | 제한 owner queue의 생산 호출자와 해당 UI 상태가 있는지 조회. core queue, fresh replay와 worker를 따로 추적 | 같은 호출 명칭의 raw/local queue 및 진단/테스트 분리. UI 호출 근거가 없으면 범위 제한 미발견 |
| STEP_IN_PROGRESS | _process/TickClock, step/advance, synchronous pump 순서와 callback/await/thread 경계 | 정적 호출 순서는 실제 중간 상태 노출/동시 실행 안전 보장이 아님 |
| STEP_RETURN | raw host _process/_pump → projection 동기화 및 viewer/renderer, private worker의 DTO 결과 | 정상 frame 표시와 운영 복원 뒤 같은 UI 인수 분리 |
| TERMINAL_RETURN | raw 전투 종료·직접 결산/WorldLink, legacy worker join 후 BattleOutcome 게시, 제한 worker 반환 | 실제 제품 경로의 종료 게시와 private terminal 복원 연동을 구분 |
| PRE_DRAIN | capture에 raw 미소비 사건이 생기는 위치, raw host _pump·filtered 호출, 제한 owner 호출자 | packet의 pending raw와 제품 화면에 게시된 사건을 별도 관측 |
| POST_RAW_DRAIN | raw host 최초 publish의 초기 drain, AutoResolver 소비·trace/표시 사용 위치 | 초기 사건 폐기, worker 요약, 제품 복원 뒤 UI 중복/유실을 별도 분류 |
| BUSY_OR_CLOSED | owner guard의 busy/unprepared 반환, legacy prepare 오류 표시, 실제 product restore/close 호출자 | 가드 정적/제한 거부와 기존 host/UI 보존의 실제 제품 근거 구분 |

입력은 이 표의 source anchor와 [운영 경계 독립 조사](../p03-parallel-active-20261108/owner-operational-boundary/REVIEW-CLOSEOUT.md), [P02 공동 경계](../p03-host-responsibility-20261108/HOST-STATE-LEDGER.md), [P02 진행표](../../docs/battle-core/pc-campaign-design/P02-PROGRESS-CHECKLIST.md), [제품 격리 UI](../p03-product-resume-20261108/DETECTION-UI-CLOSEOUT.md), [lifecycle 정적 원장](../p03-parallel-cursor-20261108/remaining-cursor-drain/lifecycle-readonly/LIFECYCLE-LEDGER.md) 및 최신 읽을 수 있는 독립 결과다. 실제 정적 조사 파일은 `core/battle`, `scripts`, `hud`, `view`, `input`, `scenes`의 생산 `.gd/.tscn` 파일에서 참조 후보를 고정하고 canonical path·SHA를 작성한다. 테스트와 과거 로그는 동작 근거의 층으로 별도 읽는다. reflection, 문자열 동적 로딩, 외부 플러그인 및 최신 격리 후보가 production이라는 가정은 범위 밖이다.

## 인수 산출물

전용 `ui-callpaths/`에 8행의 경로 원장과 읽기 전용 gate를 작성한다. 각 행에 실제 source entry, 경유, 최종 게시/표시/외부 전달 위치, producer/consumer가 관측한 값, 제어 흐름, 파일:행과 SHA, P02/P03 현재 소유, 미래 공동 인수, 근거 층을 기록한다. 근거 층은 `CURRENT_SOURCE`, `OBSERVED_LIMITED_RUNTIME`, `PRODUCT_CALL_NOT_FOUND_IN_SCOPE`, `UNVERIFIED` 중 하나 이상을 사용하고 서로 다른 주장에는 별도 근거를 붙인다. 실제 호출을 찾지 못한 경우 검색 패턴·파일 집합·간접 연결 확인 한계를 기록한다. 이미 결정된 current 동작, 추가 증거만 필요한 경우, 실제 제품 선택이 필요한 경우를 구분한다. 신규 사용자 선택이 필요하다고 판단하면 기존 HOST_AUTHORITY/DELIVERY_MODE 축에 귀속하고 중복 질문을 추가하지 않는다. 근거 없는 셀은 기존 미분류로 유지한다. 공유 체크리스트·제품/코어 코드·Git 변경 없음.

## 독립 oracle·5a·5b

위 8개 정확 tuple와 기준 원장의 8개, 기존 runtime 판정/경로/공개 범위를 독립 수기로 대조한다. 5a는 소스 경로 집합과 SHA, 8개 고유 행·필수 필드·anchor, 선행 독립 수용의 범위 및 지정 차집합을 확인한다. 실제 child exit는 정상 0, QUEUE_RETURN/ui_publish 누락 1, BUSY_OR_CLOSED를 제품 UI에서 runtime 검증한 것으로 승격한 후보 1, canonical source anchor 부재 2로 고정한다. 후보는 전용 사본이다. manifest SHA, 실제 child exit/정확 차집합/stdout/stderr 및 전후 HEAD/Git 상태를 보존하고 동시 P02 변화는 별도 기록한다. PowerShell ErrorActionPreference Stop 및 LASTEXITCODE 전달을 사용한다. 신규 Godot 실행은 없다. 재시도 K=3, 사용량 제한이면 즉시 보고하고 중단한다. 사후 독립 비-Astra 검토가 원문·표시 범위·선택 축소·실행 기록을 확인한다.
