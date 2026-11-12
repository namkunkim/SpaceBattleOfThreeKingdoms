# 세션 요구사항 통합 체크리스트

## K6 정식 검증 재개 — 2026-11-12

사용자가 K6 정식 검증과 필요한 마우스·키보드 사용을 승인했다. GitHub main `5ef3537b`를 기준으로 EntryBoot부터 GUI 15·16행의 경로와 입력 증거, 17·18행의 입력과 판정 기준을 21행·58작업·27비교 실행 계획에 다시 결속한다. 새 실행 입력의 동결과 독립 리뷰가 남았다.

**5ef3537b 집중 검증 — 2026-11-12.** 격리 입력 3종의 임포트가 통과했고, 별도 모델이 실행 5건의 증거·로그 해시와 경로 코드를 독립 검토했다. 공개 적벽 버튼은 EntryBoot와 승인 첫 작전으로 연결됐다(10/10). 구형 카드 준비를 합성한 격리 실행은 17행 완료 전후 각각 16/16, 18행 취소 전후 각각 24/24였다. 17행은 양쪽 11,350틱·1,134,950ms·연합군 승리이며 같은 오답을 양쪽에 넣은 반례를 거부했다. 공개 경로 변경으로 현재 main의 기존 정식 15~18행을 같은 조건에서 실행할 수 없다. 정식 실행기와 실제 Windows 입력은 이 검증에 포함되지 않았다. [집중 검증](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/K6/main-5ef3537b-successor-01/FOCUSED-MAIN-RESULTS.json)

**현행 main K6 경로 검토 — 2026-11-12.** `5ef3537b`의 공개 항로도에서 타이틀로 돌아간 뒤 구형 출격 준비로 진입하면 직접 배치·Space 일시정지·재시작을 확인할 수 있다. 이 경로는 재시작 시 시드를 다시 뽑고 타이틀을 거쳐 지도로 복귀하므로, 기존 16행의 고정 시드와 직접 지도 복귀 조건은 남았다. 승인 첫 작전은 EntryBoot를 통해 별도 호스트에서 시작한다. 구형 자동해결 완료·취소(17·18행)의 공개 진입이 막혀 있어 현행 집중 검증은 격리 시험 결과로 유지한다. 공개 경로의 실제 입력 결과는 아래에 기록했다. 현행 제품 경로에 맞춘 정식 판정 기준은 독립 검토를 거쳐 동결해야 한다. [현행 검증 계획](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/K6/main-5ef3537b-successor-01/PLAN.md)

**현행 main 타이틀 경로 집중 검증.** `5ef3537b`의 기존 저장 사본을 사용하는 새 헤드리스 프로세스에서 EntryBoot → 항로도 → 타이틀 → 구형 브리핑에 진입했다. 합성 viewport 입력으로 0틱 배치 명령 1회, Space 일시정지 두 번, 재시작의 새 시뮬레이션·다른 시드, 타이틀 경유 지도 복귀를 검증했다. 40/40 통과, 종료 코드 0, 저장 SHA 유지다. 정식 K6의 실제 Windows 입력 및 공개 AutoResolver 증거는 남았다. [집중 검증 결과](F:/WorkSpace/campaign-p03-20261111/tmp/k6-title-route-5ef3537b/RESULT.json)

**현행 main 타이틀 경로 Windows 검증 — 1600×900.** 정확한 `5ef3537b`의 Godot DEBUG 실행에서 공개 항로도와 타이틀을 거쳐 브리핑에 진입했다. 실제 우클릭으로 0틱 배치 명령 1회를 기록했고, 실제 Space 일시정지 두 번, 새 시드의 재시작, 타이틀 경유 지도 복귀를 확인했다. 별도 모델이 전체 캡처 17건, 입력·엔진 기록, 저장 SHA 유지와 종료 코드 0을 대조했다. 기존 고정 시드·직접 지도 복귀 조건 및 공개 AutoResolver 경로는 남았다. [Windows 증거](F:/WorkSpace/campaign-p03-20261111/tmp/k6-title-route-5ef3537b/windows1600/RESULT.json)

**현행 main 승인 첫 작전 Windows 검증 — 1600×900.** 정확한 `5ef3537b`의 새 격리 프로필에서 공개 EntryBoot로 적벽을 준비했다. 시작 전 0틱 유지와 명령 버튼 비활성, 명시 시작과 실제 이동 반응을 확인했다. 결산 전에 항로도로 돌아와 공개 버튼으로 재진입하자 다시 0틱에서 시작했고, 두 차례 복귀에 결산 화면·슬롯·원장은 없었다. 별도 모델이 전체 캡처 14건, 실제 입력, 중간·최종 프로필과 종료 코드 0을 대조했다. 내부 명령 수와 구형 AutoResolver는 별도 검증 범위다. [Windows 증거](F:/WorkSpace/campaign-p03-20261111/tmp/k6-approved-product-5ef3537b/windows1600/RESULT.json)

**`b2ba73ff` main EntryBoot 검증 준비 — 2026-11-12.** 설정된 EntryBoot 씬을 열어 보이는 컨트롤에 합성 입력을 보내는 헤드리스 시험에서 30/30을 통과했다. 명시 시작 전 0틱 대기, 공개 항로도의 `적벽으로` 재진입, 두 차례 조기 복귀 뒤 슬롯·결산 파일 부재를 확인했다. 첫 탐침은 중간 확인 화면을 잘못 가정해 실패했으며 원본을 보존했다. 독립 검토한 준비 계약에 15~18행의 현행 공개 경로와 역사 판정 기준을 기록했다. [집중 검증](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/K6/main-b2ba73ff-entry-contract-01/focused-run-143221/RESULT.json) · [K6 준비 계약](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/K6/main-b2ba73ff-entry-contract-01/ACCEPTANCE-CONTRACT-02.md)

**`b2ba73ff` 승인 첫 작전 결산·리플레이 보강 검증.** 월드맵에서 승인된 적벽 정면 작전을 시작한 헤드리스 호스트 시험이 26/26을 통과했다. 시드 208에서 0틱·751틱에 경유점을 지정해 5,107틱·510,700ms에 목표를 달성했다. 별도 재생과 독립 검토에서 순서가 보존된 이벤트 74개, 정산 1건과 저장·원장·리플레이의 동일 작전 ID, 내보낸 정산 필드 6개의 값과 자료형을 확인했다. 공개 EntryBoot 전체 실기와 정식 K6 판정은 남았다. [호스트·리플레이 증거](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/K6/main-b2ba73ff-first-operation-reference-01/PRODUCT-REFERENCE-EVIDENCE.json)

**`b2ba73ff` 21행 대응 시험 — 기존 지도 검사 FAIL.** 제품 소스를 그대로 사용한 초기·복귀 프로필 두 실행에서 129개 단언 중 125개가 참이고 4개가 거짓이었다. 기존 검사는 단일 CTA와 구형 Z2 카드 진입을 가정한다. 실제 첫 버튼은 `WatchReplay`이며 이름으로 찾은 `OpenRedCliffs`는 EntryBoot를 연다. 시뮬레이션 결정성 지문은 일치했다. 기존 기록을 보존하고 공개 EntryBoot 검증과 구형 지도 조작 검증을 각각 명시한다. [실패 원문과 독립 검토 근거](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/K6/main-b2ba73ff-row21-analogue-01/FINDINGS.md)

**현행 21행 지도 테스트 수정 후보.** 공개 시험은 이름이 고정된 `OpenRedCliffs`를 선택해 EntryBoot 준비까지 확인했다. 구형 지도 시험은 카드 진입을 명시적으로 준비해 기존 터치 크기 36건, 핀치·권역·뒤로 가기와 전투 왕복 검사를 유지했다. Windows 리플레이 버튼의 터치 크기 3건도 검증했다. 초기·복귀 프로필은 각각 같은 순서의 149/149, 공개 시험은 27/27을 통과했다. 제품 변경 없이 테스트 두 파일만 독립 검토 후 작업 브랜치에 푸시했다. [테스트 커밋](https://github.com/namkunkim/SpaceBattleOfThreeKingdoms/commit/27ee7e8ba4e7f523eedb9a112fbb1b4bc55d346f) · [검토 증거](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/K6/main-b2ba73ff-row21-tests-candidate-02/REVIEW-HANDOFF.json) 두 테스트 수정은 별도 모델의 통합 검토를 통과해 `main` 대상 PR #1을 열었다. [통합 PR](https://github.com/namkunkim/SpaceBattleOfThreeKingdoms/pull/1)

**`b2ba73ff` 21행 절대 결과 참조.** 별도 초기 프로필의 직접 스텝과 동기 AutoResolver가 공유 코어에서 모든 종결 값과 재귀적 Godot 자료형에 일치했다. 320초 제한 안에 종료 코드 0이며, 11,470틱과 지문 `ac12b629…c8e8`을 확인했다. 현행 정식 매니페스트는 별도로 동결해야 한다. [절대 결과 참조](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/K6/main-b2ba73ff-row21-typed-01/run-once/RESULT.json)

**`b2ba73ff` 17·18행 격리 AutoResolver 확인.** 사설 헤드리스 프로필에서 구형 자동해결 완료 16/16과 두 차례 취소 24/24를 통과했다. 완료 결과는 11,350틱·1,134,950ms·연합군 승리와 절대 지문 `c0e18c8c…80acb`에 일치했다. 실행 뒤 이전 원본과 비교한 결과, 자동 생성된 컨트롤 경로 번호만 달랐고, 명시된 이름·정확한 좌표와 결과·취소·정리 단언은 일치했다. 원본 불일치를 보존했다. 공개 적벽 버튼은 EntryBoot로 연결되므로 공개 AutoResolver 진입과 정식 K6 판정은 남았다. [격리 실행과 원본 비교](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/K6/main-b2ba73ff-legacy-world-focused-01/FOCUSED-REFERENCE-HANDOFF.json)

K6 15~18행 실행 전 점검과 17·18행 오프라인 비교 초안을 상위 모델이 독립 검토했다. 기존 현행 격리 표본의 16개·24개 단언을 과거 양쪽 실행 근거와 대조했고 실패 대조군 38건을 거부했다. 15·16행의 기존 경로와 동일 시드 및 1600×900 실제 입력 증거, 17·18행의 공개 진입 요건과 양쪽 현행 실행은 남았다. 계약 개정과 정식 실행은 미승인이다. [사전 점검](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/K6/main-b2ba73ff-row15-18-launch-preflight-01/PREFLIGHT.md) · [오프라인 검증](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/K6/main-b2ba73ff-row17-18-offline-draft-01/OFFLINE-RESULTS.json)

**K6 17·18행 실행 기록 교환 대조.** 과거 실행 패키지 4개가 각자의 실행 구분에서 통과했고, 반대쪽 관찰·실행·결과·로그 묶음으로 바꾼 4건은 모두 거부했다. 관찰 바이트가 같아도 실행 기록에 묶인 경로로 교환을 검출했다. 상위 모델 독립 검토를 통과했다. 정식 실행과 공개 진입 인수는 남았다. [대조 결과](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/K6/main-b2ba73ff-row17-18-offline-draft-02/OPPOSITE-LANE-CONTROLS.json)

**K6 15·16행 경로 대조.** 과거 실제 입력 실행 4건을 대조했고, 15행의 기존 실행 원문에는 배치 명령 tick 값이 없음을 확인했다. 16행 과거 원문은 같은 시드의 sim 교체와 지도 직행 복귀를 뒷받침한다. 현재 공개 적벽은 승인된 첫 작전 호스트로 연결되고 구형 타이틀 경로는 시드 및 복귀 조건을 충족하지 않아 오프라인 점검에서 거부됐다. 상위 모델 독립 검토를 통과했다. 승인된 현행 경로 또는 명시적 계약 개정과 1600×900 실제 Windows 입력을 동결 매니페스트에 묶는 작업이 남았다. [경로 점검](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/K6/main-b2ba73ff-row15-16-offline-route-gate-01/README.md)

**K6 15·16행 현행 경로 계약 변경안.** 승인 적벽 EntryBoot의 0틱 대기·명시 시작과 동일 요청·시드의 새 작전 진입·무결산 지도 직행을 제안했다. 기존 직접 배치, Space 일시정지와 구형 재시작은 별도 범위로 기록했다. 과거 실제 입력 5건은 원본 창 이미지에 결속했으며 신규 1600×900 입력 좌표는 미결속이다. 상위 모델은 미서명 제안 범위만 검토했다. 관찰기, 실행 매니페스트 동결, 계약 승인과 정식 실행은 남았다. [미서명 제안](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/K6/main-b2ba73ff-row15-16-entryboot-amendment-01/README.md)

**K6 15·16행 수동 관찰 프로토타입.** 정확한 `b2ba73ff` EntryBoot SELECT를 입력 없이 관찰했다. 첫 스모크의 임포트 오류를 보존했고, 두 번째는 종료 코드 0·진단 0이었다. 독립 리뷰에서 빈 요청·C0 및 잘못된 float 인코딩을 허용하는 판정 오류를 찾아 v2에서 보강했다. 실제 C0·지도 복귀·소유자 종료와 Windows 네이티브 입력은 남았다. 정식 검증은 실행하지 않았다. [관찰기 증거](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/K6/main-b2ba73ff-row15-16-passive-observer-01/REVIEW-HANDOFF.json) · [판정기 보강](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/K6/main-b2ba73ff-row15-16-passive-observer-02/REVIEW-HANDOFF.json)

**K6 15·16행 실제 제품 헤드리스 전이 — `b2ba73ff`.** 외부 합성 버튼 신호로 명시 시작 전 C0 대기, 같은 승인 요청·시드의 두 작전과 동일 C0, 두 소유자 종료 및 결산 없는 Atlas 직행 복귀를 관찰했다. 양수 프레임의 hz 위치와 보조 StringName 키 처리 문제를 고친 뒤 원본을 재판정해 2/2를 통과했다. 초기 실패를 보존했고 상위 모델이 독립 검토했다. 계약은 미서명이며 1600×900 실제 Windows 입력과 정식 실행은 남았다. [제품 전이 증거](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/K6/main-b2ba73ff-row15-16-passive-observer-product-01/REVIEW-HANDOFF.json)

**K6 같은 채팅의 독립 리뷰 증명 초안.** 과거 정식 실행기는 서로 다른 리뷰·실행 채팅 ID를 요구한다. 같은 채팅에서 별도 상위 모델을 쓰는 제안의 오프라인 판정은 합성 양성 1건과 음성 21건을 통과했고 상위 모델이 독립 검토했다. 현행 도구 응답으로는 독립 실행기가 검증할 플랫폼 신원 증명을 확보하지 못했다. 신뢰할 수 있는 플랫폼 증명과 원자적 일회 승인 소비가 남아 있으며 정식 실행 자격은 보류다. [증명 초안](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/K6/main-b2ba73ff-same-chat-proof-01/REVIEW-HANDOFF.json)

**K6 일회 승인 원장 오프라인 검증.** SQLite 원형에서 동시 예약과 소비는 각각 한 프로세스만 성공했고, 프로세스 종료 경계·만료·재사용·손상 원장 등 합성 대조 21/21을 통과했다. 상위 모델이 독립 검토했다. 보호된 공용 원장, 신뢰 시간, 플랫폼 신원과 정식 실행기 연동은 남았다. [원장 검증](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/K6/main-b2ba73ff-nonce-ledger-01/REVIEW-HANDOFF.json)

**K6 과거 정식 실행의 중복 대조.** 21행 58개 실행과 27개 비교를 보존 원본으로 확인했다. 작업별 경로를 정규화한 뒤에도 58개 입력 지문이 달랐다. 출력이 동일한 전후 14쌍은 별도의 고정 입력·관찰 조건을 사용했고 7·8행은 이미 실행을 공유했다. 안전한 삭제를 입증한 사례는 0개였다. 상위 모델이 독립 검토했으며 현재 미서명 15~18행 초안의 실행 가능 작업은 0개다. [중복 대조](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/K6/main-b2ba73ff-job-identity-audit-01/REVIEW-HANDOFF.json)

**K6 차기 정식 실행 준비 묶음.** 역사 정식 실행의 21행·58작업·27비교와 현행 15~18행, 동일 채팅 리뷰·일회 승인 원형의 근거 17개를 결속했다. 잘못된 SHA·경로 이탈·정식 자격 위조 등 4개 대조를 거부했고 상위 모델이 독립 검토했다. 현행 실행 가능 작업은 0개다. 행 계약 선택, 새 실행 입력 동결, 1600×900 Windows 실제 입력, 독립 리뷰·일회 승인 결속이 남았다. [준비 묶음](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/K6/main-b2ba73ff-formal-readiness-bundle-01/README.md)

**K6 15·16행 보존 원본 관계 대조.** 행별 실행 영수증과 출력 SHA를 결속한 뒤 기존 판정기에 입력 순서·시각, 같은 실행의 작전 관계, 소유자 종료와 Atlas 요약 대조를 추가했다. 보존 헤드리스 원본 2/2를 통과하고 다른 행 혼합·Start 누락 등 10건을 거부했다. 상위 모델 독립 검토를 통과했다. 실제 Windows 입력과 정식 실행은 남았다. [관계 대조](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/K6/main-b2ba73ff-row15-16-archive-relations-01/REVIEW-HANDOFF.json)

**`b2ba73ff` 15·16행 공개 타이틀 경로 합성 검증.** 실제 승인 호스트에서 만든 113틱 저장 사본으로 시작해 40개 단언을 기존 순서대로 통과했다. 0틱 배치 명령 1회, Space 일시정지 두 번, 새 시뮬레이션의 0틱 재시작, 타이틀을 거친 지도 복귀와 저장 보존을 별도 모델이 확인했다. 이전 원본과 달라진 생성 경로·시드 등 13개 관측도 보존했다. 정식 15·16행에는 이 비라우팅 경로의 판정 기준과 새 실제 Windows 입력이 남았다. [타이틀 경로 검증](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/K6/main-b2ba73ff-title-route-focused-01/RESULTS.json)

**264f47b9 호환성 사전검증 — 2026-11-12.** 구형 공개 브리핑을 여는 마지막 main 커밋에 기존 21행·58작업·27비교를 결속했다. 14~18행 사전 시험 11/11 및 비교 3건이 통과했다. GUI 15·16행은 합성 viewport 입력을 사용했다. 별도 현행 Godot 창은 시작됐으나 Computer Use 앱 접근 승인이 시간 초과돼 실제 캡처와 입력은 0건이었다. 이 사전 시험에서는 실제 입력 증거를 요구하는 정식 실행기를 시작하지 않았다. [역사 사전검증](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/K6/historical-264f47b9-review-01/HISTORICAL-FOCUSED-RESULTS-R02.json) · [Windows 입력 사전확인](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/K6/main-5ef3537b-successor-01/windows-entry-smoke-01/INPUT-PREFLIGHT-RESULT.json)

**264f47b9 정식 실행 2회 — 2026-11-12.** 두 실행 모두 15-before 작업에서 중단됐다. 각 실행은 계획 58작업 중 1작업 관측·0통과·57미실행, 21행 완료 0, 27비교 실행 0이다. 첫 실행은 캡처 유효시간을 넘겨 등록한 클릭이 호출되기 전에 차단됐고, 출처를 특정할 수 없는 별도 입력이 관측됐다. 재시도는 실제 입력 6건과 함대 배치 명령·확정을 확인했지만, Windows에서 관측한 5번째 동작의 우클릭 해제에 대응하는 Godot 관찰 기록이 없어 실패했다. 두 런처 exit 1, 첫 작업 exit 125 및 잔류 Job 0을 확인했다. [첫 집계](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/K6/historical-264f47b9-review-01/run-once/aggregate.json) · [재시도 집계](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/K6/historical-264f47b9-retry-02/run-once/aggregate.json)

**264f47b9 3차 정식 실행 — 2026-11-12.** 시험 관찰기의 입력 처리 순서를 조정해 15-before의 실제 조작 6건과 Windows·Godot 이벤트 각 12건을 확인했다. 16-before에서 Space 입력은 게임에 도달했으나, 조작 기록에 키 입력 스키마가 허용하지 않는 화면 캡처 ID가 포함돼 중단됐다. 58작업 중 2작업 관측·1통과·56미실행, 런처 exit 1이다. 4차 실행 전 실제 Space 입력으로 수정한 기록 형식을 검증했다. [3차 집계](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/K6/historical-264f47b9-repair-03/run-once/aggregate.json)

**264f47b9 4차 정식 실행 — FAIL.** 58작업 중 35개를 관측해 34개 통과·1개 실패·23개 미실행이었다. 15·16행 변경 전후의 실제 Windows GUI 4작업이 모두 통과했다. 별도 모델은 실제 조작 26건, MAIN 도구 호출 52건, Windows 이벤트 52건, Godot 이벤트 52건과 증거 해시를 확인했다. 첫 실패는 21행 새 프로필의 변경 전 작업이다. 엔진은 종료 코드 0과 `WORLD_LINK_PASS`를 기록했지만, 단언 141개가 동결된 127개와 순서·지문에서 달랐다. 전체 27비교와 정식 GUI 증거 승인 단계는 실행되지 않았고, 런처는 종료 코드 1로 끝났다. 이전 판정은 보존하고 별도 기준선에서 21행의 차이를 검증한다. [4차 집계](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/K6/historical-264f47b9-operator-04/run-once/aggregate.json) · [독립 GUI 검토](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/K6/historical-264f47b9-operator-04/operator-tools/independent-gui-evidence-four-jobs.json)

**21행 독립 기준선 — `264f47b9`.** 후보 네이티브 변경을 넣지 않은 별도 기준선에서 새 프로필·복귀 프로필을 각각 실행했다. 기존 127개 단언의 대응을 사전 정의했고, 두 모드에서 실제 141개가 모두 참이며 순서가 일치했다. 직접 시뮬레이션과 동기 AutoResolver는 공유 코어를 사용하며 전체 결과 값과 타입이 같았다. 종료 11,470틱과 절대 지문 `ac12b629…c8e8`을 별도 모델이 확인했다. 두 지도 시험의 ObjectDB·리소스 종료 진단과 이전 127개 기준의 정식 FAIL은 보존한다. [독립 기준선](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/K6/historical-264f47b9-row21-independent-01/INDEPENDENT-REFERENCE-EVIDENCE.json)

**19행 시간 초과 보강 진단.** `i01b_active_replace` 변경 전 조건을 별도 프로세스에서 단독으로 실행했다. 기존 400초 제한 안에서 252.465초에 종료 코드 0으로 끝났고, 단언 20,099개가 고정 순서와 모두 일치했다. 이전 시간 초과의 단일 원인은 확인되지 않았다. 변경 후 조건과 정식 판정은 남았다. [단독 진단](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/K6/row19-historical-264f47b9-timing-01/result.json)

**264f47b9 5차 정식 실행 — PASS.** 2026-11-12 14:21 KST에 런처 종료 코드 0으로 완료했다. 21행·58작업·27비교를 모두 통과했고, 누락·실패·중단과 잔류 시험 프로세스가 없었다. 21행 변경 전후의 새 프로필·복귀 프로필 4작업은 독립 기준선의 정확한 단언 141개와 절대 지문을 충족했고, 19행 활성 상태 교체는 양쪽 모두 기존 400초 제한 안에서 통과했다. 정식 실행기가 Windows GUI 4작업, 실제 조작 26건, MAIN 호출 52건, Windows·Godot 이벤트 각 52건의 독립 승인까지 검증했다. 매니페스트 SHA `34ec8a6eaa54f8930457caa9c1c8a6e11f0b73bec735c559ab702bc749286832`, 집계 SHA `f6dd943ecc24e1a6eff9071032755fd1339c1d3ac6d388cd3660612554da0d00`다. 이 판정의 범위는 구형 공개 경로가 남은 `264f47b9`이며, `5ef3537b`의 현행 제품 경로는 위의 집중 검증과 별도 정식 판정 기준을 따른다. [최종 집계](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/K6/historical-264f47b9-row21-05/run-once/aggregate.json) · [실행기 GUI 승인 검증](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/K6/historical-264f47b9-row21-05/run-once/gui-transcript-validated.json)

**별도 헤드리스 보강 시험.** 12작업 중 8개, 비교 6개 중 4개가 통과했다. 19행 i01b_active_replace 양쪽은 400초 제한에 도달했고, 21행 양쪽은 exit 0이었지만 141개 관측 단언과 기존 127개 기대 단언 및 지문이 달라 실패했다. 정식 집계에는 포함되지 않는다. [보강 시험 결과](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/K6/historical-264f47b9-review-01/headless-supplement-01/RESULTS.json)

당시 무입력 후속 상태: K6 무입력 revision 02 독립 PASS. 양성4·음성15·경계9 및 예제16 바이트 대조. 30초 경과 캡처에서 클릭/Space 각각 0건, 캡처25초와 사용자 만료 중 이른 경계부터 입력0건. 무입력 준비 범위 마감. 실제 MAIN 도구 원문, Win32/Godot 및 16-after 제목 증거는 당시 정식 실행에서 확인할 조건이었다. [독립 재심](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/K6/review15-main-input-dry-check-02/P02-INDEPENDENT-REVIEW.md), SHA `3111cf2ea9eba1b150ec03456c2f294d3280c9d4080285133ffc96cbc8733d17`.

무입력 독립 검토: 모의 양성 4·음성 15 재현. 30초 지난 사전 캡처가 사용자 입력 시간 안이면 모의 클릭을 호출하는 추가 반례를 확인했다. 클릭 직전 사전 캡처 25초 제한과 사용자 입력 만료를 함께 확인하고 오래된 캡처의 입력 호출 0건을 재검증하도록 기존 담당에 배정했다. 실제 MAIN 도구 원문 검증은 별도 조건이다. [독립 기록](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/K6/review15-main-input-dry-check-01/P02-INDEPENDENT-REVIEW.md), SHA `71ef8c5ff7a425cb986cf4dec746da6a634d01dddf39748cac1ce76e1b5daece`.

REVIEW-15 후속 무입력 준비: 작성자 모의 Sky 양성 4건 통과, 음성 15건 거부, 기존 원본 act 실패 재현. 동일 MAIN turn·도구 반환 스키마 검증 자료를 독립 재심에 인계했다. 실제 입력이나 정식 재실행 인수가 아니다. [무입력 검증](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/K6/review15-main-input-dry-check-01/RESULT.json).

실행 결과 독립 판정: 계획 21행/58작업/27비교 중 1작업 관측, 통과 0/58·0/21, 비교 0/27. 18:29:24 claim, 18:43:16 STOP, 첫 작업 exit125 및 Job 잔류 0, 18:48:04 런처 exit1(모두 KST). 첫 좌클릭·카드 전환은 확인했다. act 결과/인수/post nonce와 버튼 형식 문제로 정식 귀속 실패. 16행 지도 복귀 및 후속 행은 미실행이다. [독립 종료 판정](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/K6/P02-REVIEW15-EXECUTION-INDEPENDENT-REVIEW-20261111.md), SHA `4fe0668dd94fab5fcb09ab55d83643fda49bc5f7bd647b76f0b4f454c8d55365`. 다음 후보 준비는 실제 입력 없는 형식 사전 검증으로 제한한다.

최신 정식 결과(2026-11-11 KST): REVIEW-15 SHA `19991b5b473e9185303dfdf3b900cbfb52968390238320b74d5dcc27b87054f4` 독립 ACCEPT 및 1회 승인 후 실행. 첫 15행 before에서 MAIN 실제 클릭 1회와 카드 열림을 Godot 원문으로 확인했다. MAIN의 도구 반환 기록이 고정 스키마와 달라 귀속 검증을 충족하지 못해 STOP으로 종료했다. 첫 작업 exit125, 집계 FAIL·관측 1/58, 그 이후 작업 미실행. 키보드·마우스 반환 및 런처·시험 창 종료 확인. 해당 1회 권한 소진, 본선 반영 없음. 당시 재실행 조건은 기록 형식 사전 검증·독립 확인·별도 실행 승인이었다. 사용자는 2026-11-12 새 정식 검증을 승인했다. [공식 집계](E:/WorkSpace/SpaceBattleOfThreeKingdoms/tmp/p03-k6-review-20261109/review15/run-once/aggregate.json) SHA `fc9cac1c907455cda41c8a7a6bd5381bb0ef98d68108da85854470dcec68a80f`.

- [x] 2026-11-11 사용자 지시로 REVIEW-15 1회 실행을 승인받았다. 해당 실행의 결과는 아래 이력에 보존한다.
- [ ] 기존 실행 담당 `(ING)` 01a1c45c-fe91-7a50-9c34-975d02be61a9: 17행 현행 11,350틱·연합군과 역사 10,550틱·조조군 기대값의 입력 차이 및 근거를 정리하고, F 사본의 21행 계획·입력 SHA를 재동결한다. 통과를 위한 임의 기대값 변경은 하지 않는다.
- [ ] 기존 독립 검토 담당 `(ING)` 01a1be56-78b2-7cb2-a937-1a49615fa2e0: 역사 증거 보존, 승인 현행 입력, before/after 동등성, 15·16행 실제 입력 출처와 정식 실행 계획을 재심한다. 현재 두 담당의 작업 재개를 확인했으며 재심·정식 실행은 아직 미완료다.
- 사전 검토 증거 확인(2026-11-11 17:46 KST): 현행 11,350틱·연합군 결과의 이동장 입력 근거를 확인했다. 최신 지도에서는 과거 SYS-13/SystemPicker 경로를 그대로 사용할 수 없어 행17/18 및 GUI15/16을 새 manifest에 재결속해야 한다. 최종 재심은 후보 인계 대기이며 통과 판정이 아니다. [독립 사전 검토](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/K6/P02-ROW17-SUCCESSOR-PRE-REVIEW-20261111.md), SHA `ac3c00219a4b5a443826811c119a02815bb8f790adb44f9ffedfeb0e4c2a3d95`.
- 현행 기준 인계(2026-11-11): 행 17의 이전 최신 지도 격리 결과는 11,350틱·1,134,950ms·연합군 승리(결과 SHA-256 `c0e18c8c758f6767e67761630cc68cd2a5aeb2e9a5e87d0bf5cd14da5d880acb`)다. 같은 코어·Brief에 역사 이동장을 사용하면 10,550틱·조조군 승리(`3028c9c61eadaa2fb1c7a6ea2934f6d2c6b6d079491b4cd0aa1cc1f17e3835c8`)를 재현했다. 이동장 격리 영수증 SHA-256 `d75f1e240408fd81be790f4d7d82b31124578891e783dfcaca6dc8805537a0d6`. 기준 main은 EntryBoot에서 시작하므로 GUI 15·16행과 17·18행을 포함한 전체 manifest 재동결 및 독립 재심이 남았다. REVIEW-15의 이전 입력 범위 독립 ACCEPT와 정식 FAIL, revision 02의 무입력 PASS는 위 기록을 따른다. [기준 및 증거 SHA](../../integration/ef-20261111/wip/README.md#k6).
- K6 재심 후보 인계(2026-11-11 18:02 KST): [REVIEW-MANIFEST](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/K6/k6-current-product-review-01/REVIEW-MANIFEST.json) SHA42b7190bb1728eb2e9557b3d9e44a20de2aac9746d8633c40db1ba589c913166 확인. 작성자 행17 현행 before/after 및 잘못된 승자/지문 거부, 행18 두 lane24단언, 행15/16 내부 합성입력 경로 확인 보고. 기존 독립 담당01a1be56에 재심 인계했으며 물리입력 인수·정식실행은 미완료다. 최종 체크리스트 바이트/실행기 결속과 Windows 입력75분 창 확인이 남으며 사용자에게 시간대를 문의했다.
- 현행 후보 독립 재심: [판정 보고서](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/K6/P02-42B7190-INDEPENDENT-REVIEW-20261111.md), SHA80eb39de2bb2818cd476bdaaaf6fd33dfd95263782167756f18d37d08b313948 확인. 1028의존성·21/58/27·현행 행17 oracle 및 행18 격리 결과 수용. 다만 양 lane을 동일11351틱으로 바꾼 반례를 비교기가 수용하므로 11350틱/1134950ms 직접 검사 보완을 기존 실행 담당이 진행 중이다. successor 실행기·최종 문서·GUI 실제 입력 결속에 대한 최소 재심과 입력 시간 확정이 남았다. 정식 실행 완료가 아니다.
- [ ] 독립 재심 통과 후 정식 실행. Windows 실제 조작 준비와 필요한 입력 시간을 확인한다. 실패 시 무단 반복하지 않고 결과·원인을 기록한다.
- 신규 진입 구현 01a1c9b9-6356-7953-bb0e-0c1697c15a96와 독립 검토 01a1c9ce-efd1-7db3-8c3e-3bd3ca470280는 R1 수정·재심 범위 (DONE), 단일 통합01a1c9dd-2cc7-7ce1-8bf1-241ca4eb5ad3는 (ING), P02·P03 기준선 회귀 01a1c9c0-1427-7e82-a1a4-071641f31d73는 담당 범위 (DONE). K6는 고정 F 사본을 사용하고 공통 연결부 동시 편집을 금지한다. 차단된 다중호스트 시험 재실행 금지와 부수 검사기 작업 범위 제한은 유지한다.


## 신규 진입 화면 병행 조율 — 2026-11-11

Windows 전경 시험 완료: 후보 EXE 2f353f27…에서 1600×900·800×600·800×450·480×270 실제 창과 키보드·마우스를 확인했다. 주요 버튼의 잘림·겹침은 관찰되지 않았다. 1600×900에서 실제 전장 준비 Tick 0, 800×450에서 아니오 정상 종료를 확인했다. 800폭에서 글자가 작고, 480×270은 본문·버튼·지도 라벨이 지나치게 작아 가독성 미수용이다. 최소 지원 크기 판정·개선이 남는다. 시험 창 종료와 입력 반환 확인. [전경 검증 기록](E:/WorkSpace/SpaceBattleOfThreeKingdoms/docs/entry/windows-foreground-verification-20261111-ko.md).

Windows 검증 후보 준비 완료: 담당 01a1ca22는 패키지·전경 인계 범위 (DONE). 후보 EXE SHA `2f353f27429151090193f95931e5da16b0e029690181a1ac71e2c7757c9426d3`를 실제 파일에서 확인했다. E 런타임 1,855개 일치, 후보 EXE 기본 headless exit0, 내장 최종 PCK 합성 진입 15/15. release EXE 외부 탐침 120초 timeout은 별도 기록. 후보 준비 당시의 상태이며 전경 시험 결과는 위 최신 기록에 있다. [후보 보고서](F:/WorkSpace/entry-windows-01a1ca22/RESULTS.md), [전경 인계](F:/WorkSpace/entry-windows-01a1ca22/FOREGROUND-HANDOFF.md).

E 소스 반영 담당 01a1c9dd는 제품 5파일과 의존성 사후 대조 및 1,855파일 일치 F 화면 검증 사본 준비를 마쳐 (DONE). 후속 Windows 화면·EXE 검증을 새 `(ING)` 01a1ca22-76b0-77e0-ae5d-7618951b9740에 배정했다. 격리 사본에서 배포 후보와 창 크기별 화면을 확인하고, 실제 입력이 필요하면 입력 시간과 절차를 조율한다. [검증 사본 인계](F:/WorkSpace/entry-integration-01a1c9dd/render-prep-E-01/PREPARE.md).

E 소스 반영 완료: 독립 R3 통과한 revision-02 제품 5파일을 단일 통합 담당이 반영했다. 오케스트레이터가 E에서 실제 SHA 5/5를 기대값과 별도 대조했다. 소스 독립 검토 채팅 01a1c9fd는 (DONE). 화면 검증용 F 사본 준비는 통합 담당이 이어가며 실제 화면·물리 입력·배포 EXE 인수는 미완료다. [E 반영 기록](F:/WorkSpace/entry-integration-01a1c9dd/apply-E-01/RESULTS.md), SHA `02e96a612f37049ae73e844ffea01b69e63499491aa586aa7c7aa85f7c817bdb`.

최신 독립 R3: revision-02 정확한 패치 SHA `3591fe713c46cffa55ffaeceaaf56b0b5c6d0161f1ad4434e9d104b22e988ba3`로 P3 13/13·통합 24/24·복구 6/6·새 프로세스 8/8 모두 exit0. 제품5파일·원장 1건·저장 SHA를 확인했다. E 소스 반영 가능 판정에 따라 단일 통합 담당에 사전 SHA 확인과 5파일 반영을 배정했다. 반영 결과 및 실제 화면·물리 입력·배포 EXE 인수는 대기. [독립 R3 최종](F:/WorkSpace/entry-review-01a1c9fd-r02/REVIEW-R3-FINAL.txt), SHA `7a6b32f148bcc5ddf2b39e480d9907de08e67a18a71fda0e3bcb9b46400ddad2`.

통합 최신 후보 revision-02: 반복 부트 오류 패널 누적 수정, 3회 실패 후 재시도·포커스 13/13 PID23384 exit0, 패치 5/5 SHA 일치. 패치 SHA `3591fe713c46cffa55ffaeceaaf56b0b5c6d0161f1ad4434e9d104b22e988ba3`. 수정 전 결산 7/7 및 실제 재부트 8/8을 독립 R2로 수용했고 새 후보의 최소 재심을 인계했다. E 반영과 화면·물리 입력은 남았다. [후보 보고서](F:/WorkSpace/entry-integration-01a1c9dd/revision-02/RESULTS.md).

통합 결산 후속: 작성자 격리 실행에서 결산 7/7·새 프로세스 재부트 8/8, 모두 exit 0. 완료 슬롯 반복 거부와 원장 1건·슬롯/원장 SHA 보존을 보고했다. [결산 후속 증거](F:/WorkSpace/entry-integration-01a1c9dd/followup-20261111-02/RESULTS.md). 독립 R1은 패치 5/5와 기존 시험 증거를 확인했고 반복 부트 실패 시 오류 UI가 누적되는 P3를 발견했다. 기존 통합 담당이 F에서 이를 수정 중이며 독립 담당이 결산 증거 및 수정본을 재심한다. 화면·물리 입력 인수와 E 반영은 남았다.

통합 후보 패치 `ebe3ef76…`는 F 격리본에서 실제 연결 24/24·준비 실패 복구 6/6·진입 21/21·손상 190/190을 보고했다. 자연 종료 후 지도 결과 화면까지 관측했으나 결산 탐침 원장 키 오류로 재부트·중복 방지·완료 슬롯 거부 재검증이 남았다. 기존 통합 담당이 후속을 진행하며 [후보 결과](F:/WorkSpace/entry-integration-01a1c9dd/RESULTS.md)를 독립 검토 `(ING)` 01a1c9fd-edb1-7cc2-84a9-43ebd37a1eac에 인계했다.

최신 판정: R1 손상 지도 결함은 수정 SHA에 대해 독립 재심 통과. 원래 반례·복구9/9·정상21/21·손상190/190 실제 exit0, ERROR/WARNING0. [재심 보고서](F:/WorkSpace/new-entry-fix-20261111-review-01/REVIEW.md), SHA256 9DFDEDB066A4F3B198EE2B8BC4E7082FBF96A27B6116BD4085C4CF01530DCD4F 확인. 아래 최초 차단 기록은 과거 증거로 보존한다. 독립검토01a1c9ce는 해당범위 (DONE). 새 단일 통합 담당 `(ING)` 01a1c9dd-2cc7-7ce1-8bf1-241ca4eb5ad3가 F 사본에서 실제 캠페인 연결·회귀·패치를 작성하며 독립 검토 전 E 공통 연결부에 반영하지 않는다. 표시용 준비와 실제 제품0틱, 저장/재개/결산·물리입력 인수는 구분한다.

과거 R1 차단 기록(위 재심으로 해소): 손상 operation routes.front 삭제 시 prepare 성공·READY(5)·prepared_count1 이후 entry_map.gd:104 Invalid access, atlas width 삭제도 prepare 성공. 독립 재현 로그 F:/WorkSpace/new-entry-review-20261111/review-negative-final.log, exit1. 기존 구현 담당에게 필수 데이터 선검증·오류/재시도 처리 수정을 배정했으며, 같은 독립 검토 담당이 수정 SHA를 재심한다. 정상21/21 통과만으로 이 오류를 인수하지 않는다. [독립 검토 R1/P2](F:/WorkSpace/new-entry-review-20261111/REVIEW.md), SHA256 F83C884821A85B2BD0F4192E4F67D93C26EFC6C20BFED14F1AD04249B20CB1F5 확인. 검토 담당은 수정 후보 재심을 위해 (ING) 유지.

사용자가 신규 진입 구현과 기존 P02·P03 체크리스트 작업의 병행을 승인했다. P02·P03 최우선이며 K6 정식 보류는 사용자 지시로 해제했다.

- [x] 신규 독립 진입 UI 구현·자체 검증: 01a1c9b9-6356-7953-bb0e-0c1697c15a96. R1 후속 수정과 독립 재심 통과로 구현 범위 (DONE) 마감 확인. 작성자 보고 기준 상태 회귀 21/21·합성 입력·정상 종료 확인. 표시용 준비 화면이며 실제 전투·저장 연결 및 물리 입력 인수는 미완료다. [구현 계약](E:/WorkSpace/SpaceBattleOfThreeKingdoms/docs/entry/implementation-contract-20261111-ko.md), 증거 F:/WorkSpace/new-entry-20261111/SHA256.csv.
- [x] 캠페인 연결 계약 검토: 01a1c907-1cf5-7680-8dbc-4eb530ab3f99 및 충돌검토01a1c9b5-3a46-7bf3-bdb7-128666be56f2는 `(DONE)`. 승인 적벽v1 요청·seed208·표준/direct/front 유지, 상세맵 준비0틱과 명시 시작 분리, 재개/결산은 기존지도 경유, 오류/취소 복구 계약을 화면 담당에게 전달했다. 검토 범위 완료이며 통합 인수 완료가 아니다.
- [x] P02·P03 통합 전 캠페인 기준선 회귀: `(DONE)` 01a1c9c0-1427-7e82-a1a4-071641f31d73. 승인 입력4/core40 SHA 일치, 개발 플래그 없는 제품 경로12/12·실제 PID23404·exit0: 준비0틱, 첫명령1회, tick2 저장/복원과 재개 프레임 일치. 실패 경계 단언PASS는 초기 F import 오류를 포함하며 무오류 실행으로 확대하지 않는다. 취소는 기존 개발 분기, 결산은 기존67f9 전경 증거를 재사용했다. E 공통 파일 미수정. [결과·제한](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/I01/p02-p03-entry-baseline-01a1c9c0/RESULTS.md). 새 화면 실제 연결 검증은 미완료이며 독립 검토 담당01a1c9ce에 인계했다.
- [ ] 통합·독립 검토·회귀: 독립 검토01a1c9ce는 R1 재심까지 (DONE). 단일 통합 `(ING)` 01a1c9dd-2cc7-7ce1-8bf1-241ca4eb5ad3를 배정했다. 실제 연결 후보·회귀 후 독립 통합 검토와 E 반영이 남았다. project.godot, WorldLink, FleetBattle3D, world_map_screen, deck_screens, first_operation_host의 동시 편집을 금지한다. 화면 담당은 공통 연결부 패치 제안만 제출하며 원장·저장·규칙·논리맵 수치를 변경하지 않는다.
- 체크리스트 공통 편집은 오케스트레이터 단독 담당. 과거 '독립 착수 가능한 추가 작업 없음'은 당시 승인 범위의 기록이며 신규 진입 구현은 이번 승인으로 추가됐다. 검증된 실행본과 사용자 저장은 보존하고 검증 임시물은 F:/WorkSpace를 사용한다.


**P02 기본 지도 리플레이 — 2026-11-12.** Windows 공개 항로도의 리플레이 보기를 승인된 적벽 v1 재생과 연결했다. 독립 헤드리스 재실행에서 제품 지도 26/26, 개발 지도 19/19, 개발 뷰어 23/23을 통과했다. 1600×900·800×450 버튼 배치, 취소·오류 뒤 지도와 포커스 복원, Enter의 적벽 진입을 확인했다. 당시 검증 범위는 헤드리스였다. [GitHub 변경](https://github.com/namkunkim/SpaceBattleOfThreeKingdoms/commit/60b51f2e44c356e5daf4fb448c25bdbf7f2e458b)

**P02 공개 항로도 리플레이 Windows 릴리스 — 2026-11-12.** `60b51f2e` 패키지의 1280×720 창에서 실제 마우스·키보드로 파일 선택기, 취소·재진입, 손상 JSON 오류와 지도 복귀를 확인했다. 승인된 2틱 기록은 종결까지 재생했고, 실제 호스트의 5,107틱 기록은 검증을 마쳐 재생 가능한 0틱 화면에 도달했다. 긴 기록의 종결은 별도 내장 PCK 탐침에서 확인했다. 보존된 캡처 20건 중 14건은 이미지 기록이 잘려 전체 화면 배치 인증은 남았다. 시험 파일 7/7 SHA 일치, 종료 코드 0, 엔진 오류·경고 0이다. [전경 증거](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/P02-windows-product-replay-20261112-60b51f2e/foreground-20261112-095153/FOREGROUND-RESULT.md)

**P02 승인 적벽 v1 종결 대조 — `b2ba73ff`.** 공개 호스트 18/18, 두 CLI 진입 각각 8/8을 통과했다. 같은 승인 정면 작전에서 5,487틱·548,700ms에 목표 성공으로 종결했고, 결산·최종 전장 상태·사건 78건의 순서와 내용·초기 입력 메타데이터가 일치했다. 두 CLI는 공통 제품 어댑터를 사용하며 전체 C0 상태와 일반 입력 인수는 남았다. 상위 모델 독립 검토 후 테스트 전용 브랜치에 푸시했다. [테스트 커밋](https://github.com/namkunkim/SpaceBattleOfThreeKingdoms/commit/6ab92333bd1c74b5c5beec1524c3ad4f0d0fc236) · [검토 증거](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/P02-consumer-parity-b2ba73ff-01/REVIEW-HANDOFF.json)

**P02 승인 적벽 v1 C0 대조.** 공개 호스트와 두 CLI 경로의 공통 초기화에서 전체 0틱 전장 프레임, 초기 사건 2건과 지원 범위의 체크포인트가 일치했다. 엔진 검사 19건과 저장 결과 비교 4건을 통과했다. 전체 C0 검증은 공통 초기화 경계에서 했고 CLI 자체 출력은 초기 메타데이터를 제공한다. 상위 모델 독립 검토 후 테스트 전용 브랜치에 푸시했다. [테스트 커밋](https://github.com/namkunkim/SpaceBattleOfThreeKingdoms/commit/50d3cff4ded90101034d355eaa80d367b0843fc5) · [검토 증거](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/P02-c0-parity-6ab92333-01/REVIEW-HANDOFF.json)

**P02·P03 테스트 통합 후보.** `b2ba73ff` 위에 PR #1의 월드맵 테스트와 별도 검토된 P02·P03 테스트를 모았다. 테스트 파일 7개가 리뷰본 Git blob과 일치했다. 통합 작업본에서 P02 C0 23건과 P03 복구 55건을 통과했고, 보존된 종결 결과 16건을 엔진 재실행 없이 대조했다. 상위 모델 독립 검토 후 통합 테스트 전용 브랜치에 푸시했다. [통합 커밋](https://github.com/namkunkim/SpaceBattleOfThreeKingdoms/commit/b18ac5fa8e6245711e7b4d2900c412e9f8dde0c4) · [검토 증거](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/P02-P03-test-stack-b18ac5fa-01/REVIEW-HANDOFF.json)

**P02 공개 리플레이 규칙 지문 거부.** 승인 호스트 내보내기의 `rules_digest` 한 바이트만 바꾸고 본문과 유효 체크섬을 유지했다. 헤드리스 공개 Atlas에서 17/17을 통과했다. 변형은 어댑터·재생·프레임 생성 전에 거부됐고, 같은 버튼으로 원본을 선택하면 비공개 0틱 검증을 열 수 있었다. 진행 전에 닫은 뒤 지도·포커스와 파일 바이트를 보존했다. 상위 모델 독립 검토 후 테스트 브랜치에 푸시했다. 전체 재생·실제 입력 인수와는 별도다. [테스트 커밋](https://github.com/namkunkim/SpaceBattleOfThreeKingdoms/commit/e0ee30dc3e1dba83a2aee788aa7efeb465300aa4) · [검토 증거](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/P02-public-replay-guard-b08ed389-01/REVIEW-HANDOFF.json)

**P02 공개 리플레이 종결 검증.** 승인된 2틱 원본에서 예상 종결 사유만 바꾸고 본문 체크섬을 다시 계산했다. 헤드리스 공개 Atlas에서 24/24를 통과했다. 변형은 검증기가 2틱 진행한 뒤 재생 게시 없이 거부됐고, 같은 Atlas 버튼으로 원본을 다시 열어 2틱·200ms의 종결 ID와 사유를 확인했다. 원본과 저장 바이트를 보존했고 상위 모델 독립 검토 후 테스트 브랜치에 푸시했다. [테스트 커밋](https://github.com/namkunkim/SpaceBattleOfThreeKingdoms/commit/1ad51fb456cd1bc3bebb2bdc573aa9ba275c4521) · [검토 증거](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/P02-public-replay-terminal-e0ee30dc-01/REVIEW-HANDOFF.json)

**P02·P03 이어하기와 리플레이 연결.** 승인 적벽 작전에서 1틱에 적용된 철수와 대기 중인 종결 명령을 저장했다. 새 프로세스에서 공개 이어하기로 재개해 중단 없는 실행과 바이트가 동일한 2틱 리플레이를 내보냈다. 세 번째 프로세스의 공개 Atlas 재생도 전체 종결 프레임·사건 순서·결산이 일치했다. 세 프로세스에서 47/47을 통과했다. 최초 비교기의 결산 필드 범위 오류를 보존했고 상위 모델 독립 검토 후 테스트 브랜치에 푸시했다. 동일 작전의 헤드리스 검증 범위다. [테스트 커밋](https://github.com/namkunkim/SpaceBattleOfThreeKingdoms/commit/02ffda964c35ebc3404ad4d3880425741da0829a) · [검토 증거](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/P02-P03-resumed-replay-1ad51fb4-01/REVIEW-HANDOFF.json)

**P02·P03 재현 안내.** 47개 검사의 러너는 세 격리 프로세스에서 입력 파일을 직접 만든다. 새 Windows x64 작업 트리의 DLL 빌드·임포트·CLI 실행 순서를 문서화했고, CLI 옵션과 PowerShell 구문 및 기존 증거를 대조했다. Godot는 재실행하지 않았다. 상위 모델 독립 리뷰 후 PR #2 브랜치를 `a102f412`로 갱신했다. [초안 PR](https://github.com/namkunkim/SpaceBattleOfThreeKingdoms/pull/2)

**P02·P03 검토 완료 테스트의 main 반영.** PR #1을 먼저 병합했고, 같은 파일 트리를 기준으로 PR #2를 `main`에 다시 지정했다. 변경 파일 14개의 이름·Git 지문·상태가 동일함을 대조한 후 병합했다. 원격 `main` `680c1b2c`에서 두 검토 이력을 확인했다. [PR #1](https://github.com/namkunkim/SpaceBattleOfThreeKingdoms/pull/1) · [PR #2](https://github.com/namkunkim/SpaceBattleOfThreeKingdoms/pull/2)

**P02·P03 테스트 PR 인계.** 원격 `02ffda96`을 PR #1 브랜치 위에 초안 PR #2로 연결했다. 독립 검토한 8개 커밋과 테스트 13개 파일만 차이에 포함된다. PR #1이 병합되면 `main` 재대상 지정 전 차이를 다시 대조한다. [초안 PR](https://github.com/namkunkim/SpaceBattleOfThreeKingdoms/pull/2)

**2026-11-12 P03 제한 회귀 재확인.** GitHub main `5ef3537b`에서 제한 체크포인트 38/38, 비공개 상태 70건, 활성 교체 20건, 개발 호스트의 새 프로세스 4틱 재개 및 동일 슬롯 SHA를 별도 모델이 독립 확인했다. 개발 플래그 없는 제품 WorldLink 직접 경로는 첫 명령 1회, 2틱 저장·복원과 다음 프레임 일치까지 11/11을 통과했다. 이 제품 시험의 범위는 동일 호스트 내부 복원이다. 이후 공개 항로도 새 프로세스 복원은 아래 결과에 기록했다. [제한 회귀](F:/WorkSpace/campaign-p03-20261111/tmp/p03-main-5ef3537/summary.json) · [제품 경로](F:/WorkSpace/campaign-p03-20261111/tmp/p03-main-5ef3537/product.receipt.json)

**2026-11-12 P03 공개 항로도 이어하기.** 저장이 있는 새 프로세스의 기본 Windows 항로도에 첫 작전 이어하기를 노출했다. 독립 코드·증거 검토에서 정상 31/31, 백업만 있는 저장 17/17, 손상 슬롯 오류 후 재시도 18/18, 빈 프로필 6/6을 확인했다. 공개 EntryBoot에서 만든 2틱 저장을 새 프로세스가 복원했고, 저장 바이트와 대기 명령을 보존해 다음 프레임에서 명령을 한 번 적용했다. 이 시험의 범위는 헤드리스였다. 전체 운영 Cn 및 전역 명령 커서 인수는 남았다. [GitHub 변경](https://github.com/namkunkim/SpaceBattleOfThreeKingdoms/commit/b2ba73ff5b3c18a7ab0885d00cebf0c25be7fed1)

**P03 공개 항로도 재개 Windows 릴리스 — 2026-11-12.** `b2ba73ff` 패키지의 실제 입력으로 저장한 103틱·10.3초를 새 프로세스가 일시정지 상태로 복원했고, 계속 진행한 뒤 117틱을 관측했다. 800×450에서 백업 전용 복원과 기본 슬롯 미생성을 확인했다. 손상 기본 슬롯은 오류를 표시하고 파일을 보존했으며, 격리 시험의 기본 슬롯을 복구한 뒤 같은 창에서 Enter로 재개했다. 네 프로세스 모두 종료 코드 0, 엔진 오류·경고 0이다. 대기 명령 적용은 이전 헤드리스 검증 범위다. [전경 증거](F:/WorkSpace/campaign-p03-atlas-resume-20261112/tmp/p03-windows-b2ba73ff/RESULTS.md)

**P02·P03 통합 Windows 릴리스 — 1600×900.** 사용자 지정 해상도에서 `b2ba73ff` 패키지의 공개 항로도에 리플레이·이어하기·적벽 진입 버튼이 모두 보였고, 전체 파일 선택기 화면을 확인했다. 처음 Escape가 선택기를 닫지 않아 창에 다시 포커스를 준 뒤 Escape로 취소했고 Enter로 다시 열었다. 손상 파일 오류와 지도 복귀, 승인 2틱 리플레이 종결, 저장 103틱 재개와 지도 복귀를 실제 입력으로 확인했다. 독립 검토에서 전체 창 캡처 14건과 조작 기록, 저장·시험 파일의 SHA, 프로세스 정상 종료를 확인했다. [통합 전경 결과](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/P02-P03-layout-b2ba73ff-20261112/RESULTS.md)

**P03 백업 전용 Windows 릴리스 — 1600×900.** 같은 패키지의 새 프로세스에서 실제 클릭 한 번으로 `.previous`만 있는 저장을 103틱·10.3초에 일시정지된 상태로 복원했다. 백업 SHA가 유지됐고 기본 슬롯은 생성되지 않았다. [백업 전용 결과](F:/WorkSpace/campaign-p03-atlas-resume-20261112/tmp/p03-windows-b2ba73ff/foreground-previous-1600/RESULT.json)

**P02·P03 GitHub main 반영 — 2026-11-12.** 독립 검토 후 `5ef3537b`에서 `b2ba73ff`로 fast-forward했다. 공개 항로도 리플레이와 이어하기가 들어간 커밋이며, 1600×900 통합 Windows 릴리스와 백업 전용 실기 검증에 사용한 정확한 소스다. GitHub main을 다시 읽어 커밋을 확인했다. [통합 커밋](https://github.com/namkunkim/SpaceBattleOfThreeKingdoms/commit/b2ba73ff5b3c18a7ab0885d00cebf0c25be7fed1)

**P04 외부 저장 실패 원자성 — `b2ba73ff`.** 헤드리스 개발 호스트에서 기존 외부 저장 회귀 36/36, 새 프로세스 재열기 3/3, 활성 호스트 실패 경계 30/30을 통과했다. 체크섬 오류는 복원 시작 전에, 상태 지문 불일치는 비동기 재생 뒤에 거부됐다. 두 경우 기존 작전·대기 명령·커서·조작 상태와 저장·결산 파일을 보존했고 기존 작전은 다음 틱으로 진행했다. 별도 모델이 합성 파일 선택과 증거를 검토했다. [활성 호스트 검증](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/P04-external-atomicity-b2ba73ff-04/focused/result.json)

**P04 외부 저장의 적용 데이터 지문 거부 — `b2ba73ff`.** 유효한 체크섬을 유지하면서 `effective_digest`만 원래 `source_digest`로 바꿨다. 활성 개발 호스트는 비동기 복원을 시작하기 전에 거부했고, 기존 상태·조작·저장 파일을 보존한 채 계속 진행했다. 같은 호스트에서 원본으로 재시도해 복원하고 대기 명령을 적용했다. 25/25와 상위 모델 독립 검토를 통과했다. 공개 제품 가져오기와 실제 파일 선택기 입력은 별도다. [검토 증거](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/P04-external-effective-authority-b2ba73ff-01/REVIEW-HANDOFF.json)

**P07 승인 적벽 v1 보급·증원·철수 — `b2ba73ff`.** 정책 37/37, 개발 시험 77/77, 공개 진입부터 지도 결산까지 승인 호스트 26/26을 통과했다. A 거점 가동 뒤 60초에 보급으로 탄약이 124→138로 늘었고, 증원은 예정 시각 다음 틱에 한 번 진입했다. 명시 철수에서 두 함대가 생환했고 1,854틱의 결산 ID·사유·시각이 호스트와 지도에서 일치했다. 별도 모델이 헤드리스 결과를 검토했다. [보급·증원·철수 검증](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/P07-main-b2ba73ff-20261112/RESULTS.md)

**P07 공개 결산의 원장 잠금 재시도.** 직접 지휘의 조기 철수 결산에서 원장을 잠그고 반환을 두 번 시도했다. 같은 결산·호스트 상태가 유지됐고, 잠금을 해제한 뒤 연속 반환 입력에도 원장은 한 번만 게시됐다. 지도에 같은 결산이 표시됐다. 헤드리스 22/22와 상위 모델 독립 검토를 통과해 테스트 브랜치에 푸시했다. 실제 동시 작성·성공 철수·전원 상실은 별도다. [테스트 커밋](https://github.com/namkunkim/SpaceBattleOfThreeKingdoms/commit/5a7afb1d7cdaa145ea1e90f799e7db3d1be9ff5b) · [검토 근거](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/P07-product-settlement-retry-02ffda96-01/REVIEW-HANDOFF.json)

**P07 결산 재시도 테스트 main 반영.** 검토된 파일 한 개와 원격 head를 대조해 PR #3으로 병합했다. [병합 PR](https://github.com/namkunkim/SpaceBattleOfThreeKingdoms/pull/3)

**P09 월드맵 테스트 종료 정리 — `b2ba73ff` 런타임.** 결정성 검사에서 소유한 세 `AutoResolver`를 마지막 사용 뒤 닫도록 테스트 한 파일을 수정했다. 초기·복귀 프로필 모두 기존 순서와 값 그대로 149/149를 통과했고, 의도된 거부 진단 4건은 유지했다. 종료 잔류는 기준선의 ObjectDB 117개·리소스 18개에서 두 실행 모두 0/0이 됐다. 별도 모델 검토 후 `27ee7e8b` 위의 수정 커밋을 작업 브랜치에 푸시했다. 제품과 오디오 전체 종료 인수는 별도다. [수정 커밋](https://github.com/namkunkim/SpaceBattleOfThreeKingdoms/commit/3d5d41cdb5aca023b719e1f2f9c862bb076adb7c) · [검토 증거](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/I01/p09-current-world-link-lifetime-candidate-20261112-01/REVIEW-HANDOFF.json)

**P09 교체된 루프 재생의 수명 진단 — `b2ba73ff`.** 격리된 Godot Dummy 드라이버에서 11/11을 통과했다. 루프 교체 뒤 현재 플레이어에는 새 재생만 보였고 이전 재생의 약한 참조는 살아 있었다. 유지 대조와 두 재생 및 오디오 리소스 해제를 확인했고 콘솔 종료 잔류 진단은 없었다. 상위 모델이 독립 검토했다. 실제 오디오 장치, 전체 종료와 TRACE 인수는 남았다. [재생 수명 증거](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/I01/p09-ui-loop-retirement-b2ba73ff-02/REVIEW-HANDOFF.json)

**P09 등록된 재생의 종료 추적.** 테스트가 시작 시 등록한 재생은 교체 후에도 계속 추적했다. 격리 Dummy 시험에서 8/8을 통과했다. 이전 재생 참조를 의도적으로 유지하면 해당 ID만 제한 시간까지 남았고, 참조 해제 뒤 목록이 비었다. 첫 파서 실패를 보존했고 상위 모델 독립 검토 후 테스트 브랜치에 푸시했다. 제품의 모든 재생·실장치·TRACE 인수는 남았다. [테스트 커밋](https://github.com/namkunkim/SpaceBattleOfThreeKingdoms/commit/050a1df0097333ceebf9652be3fc8b5ad5f7295e) · [검토 증거](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/I01/p09-observed-retirement-b2ba73ff-01/REVIEW-HANDOFF.json)

**P09 실제 전투 신호의 재생 추적.** `FleetBattle3D`에서 CommandDeck·UiSound까지 연결된 테스트 소유 루프 두 개를 등록했다. Dummy 헤드리스 8/8을 통과했고, 이전 재생을 의도적으로 유지하면 해당 ID만 1,501ms 제한 시점까지 남았다. 참조를 해제한 뒤 두 재생과 소유 객체가 정리됐다. 상위 모델 독립 검토 후 테스트 브랜치에 푸시했다. 자동 재생 전체, 실제 오디오 장치와 TRACE 인수는 남았다. [테스트 커밋](https://github.com/namkunkim/SpaceBattleOfThreeKingdoms/commit/1ef0fc0ef172ce7972e9a9ce71400adf9582dabe) · [검토 증거](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/I01/p09-battle-signal-retirement-050a1df0-01/REVIEW-HANDOFF.json)

**P09 제품 자동 화공의 종료 신호 누락.** 실제 전투 AI가 1틱에 시작한 화공 루프를 수동 관찰했다. 201틱에 코어가 낸 종료 신호는 대상이 아군 접촉 목록에 없어 화면 전달에서 제외됐고, 루프는 씬 정리까지 재생됐다. 정리 뒤 같은 ID의 해제까지 7/7을 검증했다. 초기 실패 원본을 보존했고 상위 모델 독립 검토 후 정확한 테스트 커밋만 푸시했다. 복제 임포트 파일은 격리 F 작업본에 보존했다. [테스트 커밋](https://github.com/namkunkim/SpaceBattleOfThreeKingdoms/commit/fc0d3d9c9bb062494563b52c3da38d175767e6bd) · [검토 증거](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/I01/p09-autonomous-fire-1ef0fc0e-01/REVIEW-HANDOFF.json)

**P09 이미 들린 화공 루프 종료 수정.** 첫 수정 후보는 공개 화재가 겹치면 너무 일찍 멈추는 문제가 있어 푸시하지 않았다. 수정한 후보는 공개 화재 중첩·배치된 이벤트·전투 재시작과 숨은 화재 대조를 포함한 헤드리스 59/59를 통과했다. 불확실한 시작은 기존 전역 종료 동작을 유지한다. 상위 모델 독립 재리뷰 후 작업 브랜치에 푸시했고 `main` 병합은 남았다. [수정 커밋](https://github.com/namkunkim/SpaceBattleOfThreeKingdoms/commit/6b12798cc6e9f4bb5cfa66d22f863a312d6ce93a) · [검토 증거](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/I01/p09-visible-fire-overlap-779d5679-01/REVIEW-HANDOFF.json)

**P09 main 통합 추가 검증.** 정확한 수정 커밋으로 PR #4를 열었다. 병합 직전에 별도 적벽 프롤로그·시작 설정 변경 `e3d76788`이 main에 들어갔다. 제품 오디오 변경의 여섯 파일은 충돌하지 않으나 CommandDeck의 UI 초기화 의존성이 달라져, 새 main과 결합한 집중 검증 뒤 병합한다. [PR #4](https://github.com/namkunkim/SpaceBattleOfThreeKingdoms/pull/4)

**P05 승인 적벽 공간 회귀 — `b2ba73ff`.** E/R 팽창 원과 A/B/C/E 중심 검사는 61/61, 정면 이동 자세는 17/17을 통과했다. 네이티브 자세 CSV 20,698행이 이전 승인 기록과 바이트 단위로 일치했고, 이동 오류와 경로 위반은 없었다. 별도 모델이 원본과 입력 해시를 확인했다. 개별 선체 다각형, 진형 전환 중 점유 영역과 Atlas→전장 좌표의 인수 기준은 남았다. [공간 검증](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/P05-main-b2ba73ff-20261112/RESULTS.md)

**P05 승인 적벽 좌표 근거 — `b2ba73ff`.** Atlas와 진입 지도는 항로도 마커를 공유하며 Atlas 선택은 전장 좌표를 넘기지 않는다. 전술 미리보기는 E–J–A–C를 목표 중심까지 그린다. 실제 C0의 최종 경유지는 접근 거리 245와 교전 보정 `(56,18)`을 적용한 `(1197.59094,490.08563)`으로, 보존 원본과 0.001 단위 이내에 일치했다. 잘못된 좌표·원본 변조 등 5개 대조군이 거부됐고 상위 모델이 독립 검토했다. 일반 지도→전장 변환·선체 기하 인수는 남았다. [좌표 대조](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/P05-atlas-anchor-b2ba73ff-01/RESULTS.md)

**O07 로컬 Win32 교체 거절·복구 — `b2ba73ff`.** 격리 F 슬롯과 릴리스 DLL에서 14개 프로세스가 통과했다. 실제 공유 제한으로 결산·보급 저장의 교체가 거절됐을 때 기존 상태와 저장 파일이 보존됐다. 잠금 해제 뒤 새 프로세스의 재시도·재열기 결과는 기준 바이트와 일치했다. 기본 슬롯 부재 시 이전 세대를 읽기 전용으로 열었고, 소유한 시험 잠금 프로세스가 종료된 뒤에는 잠금 파일이 남아 있어도 슬롯을 열었다. 별도 모델이 검토했다. 전원 상실·운영 전환·외부 지급은 남았다. [로컬 복구 검증](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/O07/main-b2ba73ff-release-recovery-01/RESULT.json)

**P03 제한 호스트 C0·Cn 명령 커서 — `b2ba73ff`.** 같은 규칙과 입력의 다섯 격리 프로세스에서 74/74를 통과했다. 첫 재개가 대기 중인 명령 3번을 한 번 적용했고, 두 번째 저장은 적용 3번·수락 4번을 기록했다. 새 프로세스에서 C0와 저장 Cn을 대조했고 명령 4번만 한 번 적용됐다. 다음 빈 틱에서 반복 적용이 없었으며 기본 슬롯과 이전 세대 해시를 보존했다. 별도 모델이 검토한 범위는 제한 호스트의 로컬 커서다. [커서 검증](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/P03-command-cursor-b2ba73ff-01/RESULT.json)

P03 공개 이어하기의 같은 작전 내 여러 세대 저장·재개를 Windows 헤드리스 3개 프로세스에서 60/60 검증했다. 두 번째 재개에서 대기 명령이 순서대로 한 번씩 적용됐고 다음 빈 틱에서 반복이 없었다. 기본·이전 슬롯 해시를 보존했다. 상위 모델 독립 검토 후 테스트 전용 브랜치에 푸시했다. 작전 간 전역 커서 인수는 남았다. [테스트 커밋](https://github.com/namkunkim/SpaceBattleOfThreeKingdoms/commit/15441ea296054cb91f24b867b718e00847a8f18b) · [검토 증거](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/P03-public-cursor-b2ba73ff-01/REVIEW-HANDOFF.json)

**P03 보존 슬롯으로 공개 이어하기 — `b2ba73ff`.** 실제 저장 회전 후 기본 슬롯이 없는 조건을 격리 프로필에서 구성했다. Windows 헤드리스 프로세스 3개에서 55/55를 통과했다. 보존 슬롯의 대기 명령 두 건이 순서대로 한 번씩 적용됐고 명시적으로 저장했을 때만 기본 슬롯을 복구했다. 다음 프로세스는 복구 슬롯을 우선했고 보존·미게시 파일 바이트를 유지했다. 실제 전원 차단과 작전 간 전역 커서는 별도다. 상위 모델 독립 검토 후 테스트 브랜치로 푸시했다. [테스트 커밋](https://github.com/namkunkim/SpaceBattleOfThreeKingdoms/commit/08dca4b3e24c50ec7b5e7f68854d799e33bfe5d2) · [검토 증거](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/P03-public-fallback-15441ea2-01/REVIEW-HANDOFF.json)

**P03 공개 이어하기 호환성 거부.** 체크섬이 유효한 저장의 봉투 버전, 내부 체크포인트 형식, 규칙 지문을 각각 한 필드만 바꿔 33/33을 검증했다. 세 변형은 각각 오류를 표시하고 자동 백업 사용·슬롯 게시 없이 기존 파일을 보존했다. 정상 슬롯을 복원해 같은 Atlas 버튼으로 재시도하자 대기 명령이 순서대로 한 번 적용됐다. 최초 러너의 검사 수 설정 오류를 보존했고 상위 모델 독립 리뷰 후 테스트 브랜치에 푸시했다. 패키지 마이그레이션·실제 입력·전역 커서는 별도다. [테스트 커밋](https://github.com/namkunkim/SpaceBattleOfThreeKingdoms/commit/b08ed3898507993c7597d212648a92c457faa850) · [검토 증거](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/P03-public-version-b18ac5fa-01/REVIEW-HANDOFF.json)

**P03·O07 저장 중단 진단 — `b2ba73ff`.** 검증된 임시 저장 직후와 테스트 콜백으로 기본 슬롯을 이전 슬롯으로 옮긴 직후에 격리된 Godot 자식 프로세스를 각각 종료했다. 두 경우 새 프로세스는 마지막 확정 저장을 읽었고, 명시적으로 다시 저장한 뒤 새 세대를 열었다. 상위 모델 독립 검토를 통과했다. 두 번째 지점은 기본 경로의 이동을 재현한 것으로, 비계측 기본 경로·네이티브 DLL·전원 차단 인수는 남았다. [저장 중단 증거](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/O07/p03-store-child-cutpoint-b2ba73ff-02/RESULTS.md)

**P06 논리 시계·결산 연속성 부분 검증 — `b2ba73ff`.** 논리 시계 60/60, 원장 저장·재열기 22/22, 개발 Atlas 결산 표시·재시도 8/8을 통과했다. 개발 플래그가 빠진 첫 실행의 실패 기록을 보존했고, 새 프로필에서 플래그를 적용한 결과를 별도 모델이 확인했다. 현재 제품 소스는 결산 뒤 지도로 돌아가 같은 첫 작전을 새로 시작한다. 이전 결산에 연결되는 후속 작전과 전체 A05·A06 인수는 남았다. [부분 검증](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/P06-main-b2ba73ff-20261112/RESULTS.md)

P06 실제 제품 결산 재열기 — `b2ba73ff`. 격리된 Windows 헤드리스 프로세스에서 과거 결산 원장을 재열고 같은 적벽 첫 작전을 0틱에서 새 작전 ID로 시작했다. 빈 프로필 대조군과 요청·규칙 지문·초기 상태가 일치했고 원본과 복사한 원장 바이트를 보존했다. 상위 모델이 검토했다. 이전 결산과 후속 작전을 연결하는 규칙과 A05·A06 종합 인수는 남았다. [재열기 검증](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/P06-main-b2ba73ff-product-reopen-01/RESULTS.md)

**P06 후속 작전·P03 작전 간 커서 미서명 제안.** 기존 제품 결산 재열기와 같은 작전 커서 근거를 결속했다. 후속 진입 자격·정의 버전·승계 상태·커서 소유권·게시와 재시도 규칙을 결정할 선택지와 판별 사례 5개를 정리했다. 제품 정책 승인과 A05·A06 종합 인수는 남았다. [결정안](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/P06-successor-contract-b2ba73ff-01/README.md)

**P06 이어하기와 리플레이의 논리 시계 경계.** 이어하기는 Start 전 18프레임 동안 1틱과 대기 종결 명령을 보존했고, 공개 리플레이의 Play/Pause도 18프레임 동안 1틱을 유지했다. 재개하면 두 경로 모두 2틱·200ms의 전체 종결 프레임과 사건 순서가 중단 없는 원본과 일치했다. 헤드리스 36/36과 상위 모델 독립 검토를 통과했다. 별도 CLI·FX-G 전체·실제 입력은 남았다. [시계 검증](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/P06-clock-boundary-02ffda96-01/REVIEW-HANDOFF.json)

**P08 Android 패키징 부분 검증 — `b2ba73ff`.** 격리 F 환경에서 Godot 4.7.2 임포트와 ARM64 내보내기가 각각 exit 0이었다. 399,854,099바이트 APK의 ZIP 정렬과 구조를 확인했고 서명은 없었다. Godot가 임포트 중 격리 프로필에 디버그 키를 자동 생성해 전체 진단은 exit 1을 반환했다. 원래 프리셋은 복원했고 상위 모델이 패키징 범위를 검토했다. 출시 서명, 실기기와 성능 인수는 남았다. [진단 증거](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/P08-android-b2ba73ff-01/RESULTS.md)

**P08 외부 Android 디버그 서명 진단.** 앞서 확인한 ARM64 APK를 일회용 키로 서명했다. Android SDK에서 v2·v3 서명과 ZIP 정렬을 확인했고, 원본 ZIP 항목 1,818개의 내용·길이·압축 방식이 일치했다. 첫 실행의 검증 출력 파싱 실패를 보존하고 같은 APK를 다시 검사해 통과했다. 일회용 키를 제거했고 상위 모델이 독립 검토했다. Godot 서명 프리셋·출시 서명·실기기 인수는 남았다. [디버그 서명 결과](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/P08-android-b2ba73ff-debug-sign-01/RESULTS.md)

**P08 Godot 서명 디버그 프리셋 — `b2ba73ff`.** 커밋된 Android 프리셋으로 내보내기를 완료했다. 400,040,307바이트 ARM64 APK의 ZIP 정렬과 v2·v3 서명을 SDK에서 확인했다. 서명자는 격리된 일회용 인증서와 일치했고 키 파일을 제거했다. 프리셋 바이트를 보존했고 상위 모델이 독립 검토했다. 이전 무서명 산출물과 생성 데이터가 달라 동일 페이로드 판정은 없으며 출시 서명·설치·실기기 검증은 남았다. [프리셋 검증](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/P08-android-b2ba73ff-godot-sign-01/RESULTS.md)

**P08 서명 ARM64 APK의 ELF 정렬.** 포함된 AArch64 라이브러리 두 개의 `PT_LOAD` 여섯 개가 16KiB 정렬과 주소·오프셋 합동 조건을 충족했다. 잘못된 세그먼트 대조 2건을 거부했고 상위 모델이 원본 APK를 독립 검토했다. 두 파일은 ZIP에서 압축되어 매니페스트가 추출을 요청한다. APK 직접 매핑이나 실기기 실행은 검증하지 않았다. [정적 검사](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/P08-android-b2ba73ff-elf-align-01/REVIEW-HANDOFF.json)

## 현재 상태 요약 — 2026-11-11 KST

**사용자 우선순위: P02·P03 최우선.** 관련 채팅을 5분마다 점검하며 직접 필요한 승인 작업부터 조율한다. 사용자가 K6 정식 검증 재개를 승인했다. 현행 공개 적벽 진입에서 기존 정식 경로를 사용할 수 없어 재검증 기준을 점검 중이다.

- [x] 승인 적벽 v1: 첫 PC 플레이·같은 규칙 버전 저장/재개·결산 복구 검증 완료. 현행 전경 인수는 EXE `67f9cb20…` 한정이다.
- [x] P09 재생 객체 정리: `tests/battle_flow.gd` 한 파일 E 반영, 독립 검토 및 최소 flow 회귀 통과. SHA `afa999ba1e3d6bde19293999aab2f79034a30312b19ce11ea6fa604cda468826`. [반영 증거](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/I01/p09-rp-apply-01a1c966-20261111/RESULTS.md)
- [ ] P09 오디오 종료 보강. Godot 4.7.2 Dummy 스트림의 `battle_flow`·`group_formation` 테스트 종료 경로를 보강했다. 기존 TRACE 순서와 틱을 유지했고 두 테스트는 정상 종료했다. 참조를 의도적으로 유지한 대조군은 2,033ms에 종료 코드 1을 반환했다. 이번 기준선에서 간헐적 잔류가 재현되지 않아 제품 오디오 전반의 종료 인수는 남았다. [독립 검토 범위의 GitHub 변경](https://github.com/namkunkim/SpaceBattleOfThreeKingdoms/commit/bada6d92c091156fa2dce2c243c26b0716d706cb) · [검증 매니페스트](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/I01/p09-audio-fence-ab-20261112-01/REVIEW-MANIFEST.json)
- [ ] O07 운영 전환·외부 지급·전원 상실: 대상/슬롯 지문·전환 승인, 수신자/계약 및 시험 환경 조건이 남았다.
- [ ] 일반 I01/P03~P08: 공통 입력·운영 상태/커밋·공간/작전 정책·출시 대상 인수 조건이 남았다. 승인된 적벽 한 건의 완료를 전체 인수로 확대하지 않는다.
- [x] **`264f47b9` K6 정식 검증 통과.** 5차에서 21행·58작업·27비교와 최종 GUI 증거 승인을 완료했다.
- [ ] **`b2ba73ff` main 제품 경로 K6 정식 검증.** 21행 검증 후보와 절대 참조를 마련했다. 15~18행의 현행 공개 경로 판정, 매니페스트 동결, 새 실제 Windows 입력 검증이 남았다.
- [x] **신규 진입 Windows 후보 전경 시험.** EXE 2f353f27…에서 네 창 크기, 키보드·마우스, 전장 준비 0틱과 아니오 정상 종료를 확인했다. [전경 검증 기록](../../entry/windows-foreground-verification-20261111-ko.md)
- [ ] **신규 진입 작은 창 가독성.** 480×270은 글자와 지도 라벨이 지나치게 작아 미수용. 800폭에서도 가독성이 저하된다. 최소 지원 크기 또는 화면 개선 결정이 남았다.

관련 검증·수정·검토 담당 채팅은 담당 범위 기준 `(DONE)`이다. 전체 P02/I01b는 **미완료**다. 두 우선 체크리스트 재대조 결과 현재 승인 범위에서 독립 착수 가능한 추가 필수 작업은 확인되지 않았다. [인수 부족·담당·필요 입력 대조](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/I01/p02-checklists-closeout-01a1c907-20261111.md)


2026-10-31 KST / 대상: 이 대화와 압축 인계의 캠페인·I01b 진행, 원본 보존, feature 커밋/푸시, 진행·통합 체크리스트 요청.

확인 사실 갱신: 2026-11-11 KST. 기존 41개 요구 ID와 한정 인수·실패 이력을 보존한다. 이 문서와 [P02 필수 작업](P02-PROGRESS-CHECKLIST.md)이 최우선 실행·인수 기준이다. 개발 후보 v1은 완료했고 전체 P02·I01b는 미완료다. HTML 진행표는 갱신하지 않았다.

**전체 캠페인/I01b는 미완료(NOT_READY)**다. 설계 선택 기록, 한정된 구현/검사, 커밋/푸시 완료를 제품 전체 완료로 합산하지 않는다. 상태는 **완료 / 미완료 / 상시준수**로 구분한다. 아래 ‘완료’는 각 행의 인수 범위에만 적용한다. 기존 UI·브랜딩·자산 등의 별도 대기열은 기존 [전체 작업 체크리스트](../CHECKLIST-OPEN.md)에 남긴다.

## 0. 실행 순서 — 11/09 사용자 승인, 11/11 현재 상태

**첫 PC 플레이 → 같은 규칙 버전 저장·재개 → 별도 후속 검증** 순으로 진행한다. 기존 P01~P09와 승인된 설계 결정, 완료 이력은 추적용으로 보존한다.

### 1단계 · 첫 PC 캠페인 플레이 — Windows 개발 후보 v1 확인

- [x] **P02/P03 최소 연결 — 개발 후보 v1.** 실제 PC 진입점 한 곳에서 같은 작전을 시작·진행·종료한다. 해당 경로의 초기 배치·명령·논리시계·표시·결과 반영과 준비 실패 시 기존 상태 보존을 확인한다. 상태 범위는 이 작전에 필요한 함대·손실·자원·목표·시간 정보로 좁힌다.
- [x] **P05/P07 작전 흐름 — 개발 후보 v1.** 실제 맵에서 정면과 우회가 각각 통행 가능하고 보급거점 및 시간 증원이 플레이어의 판단에 영향을 준다. 목표 달성과 명시 철수의 결과를 각각 확인한다. 좌표·진형 외곽·접근은 첫 작전에 쓰이는 범위로 검증한다.
- [x] **P08 최소 PC 확인 — 개발 후보 v1.** Windows 실제 입력으로 정면 목표 달성과 우회 철수를 각각 플레이하고 게임시간·결산을 기록했다. 검증 배속 결과이므로 실제 경과와 약 20분 페이싱 가설은 현행 제품에서 별도로 확인한다. [정면·우회 로그](P02-PROGRESS-CHECKLIST.md#첫-pc-캠페인-플레이--1109-개발-후보-v1-이력)

자동 조율의 첫 지시는 현재 작업의 종료·소유 경로를 확인하고 위 플레이를 막는 가장 작은 실제 PC 연결·공간·작전 동작을 고르는 것이다. 기존 P02/P03 결과는 재사용하며 신규 검증은 선택한 조각의 반례와 관련 회귀에 집중한다.

### 2단계 · 같은 규칙 버전 저장·재개 — 개발 후보 v1

- [x] **P04와 필요한 P03 후속 — 개발 후보 v1.** 같은 규칙 버전에서 현재 작전 상태와 후속 명령을 보존하고 재개한다. 운영 체크포인트 Cn과 명령 커서는 이 범위에 필요한 적용·대기 경계를 확정한다. 같은 후속 입력이 동일하게 적용되고 잘못된 입력은 활성 상태를 보존하며 거부되는지 확인한다. Windows 개발 작전의 외부 파일은 [v1 규격](FIRST-OPERATION-EXTERNAL-SAVE-V1.md)으로 확정했다. 전체 O07 저장 범위는 별도다. [실제 입력과 독립 검증](P02-PROGRESS-CHECKLIST.md)

### 3단계 · 승인 적벽 v1 Windows 복구 배포 인수 — 2026-11-11

- [x] **승인 정면 A04 및 직전 통합 배포.** A04 61/61, 지도 결산 표시 9/9, r5·승인 치수 E 설치 8/8, `d267012a…` 제품 8/8·O07 10/10의 제한 범위를 인수했다. [직전 배포 독립 검토](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/I01/r5-dimensions-canonical-windows-review-01a1c8e0/RESULTS.md)
- [x] **P02/P04 결산 복구.** E WorldLink `7e3b1d42…` 설치, 제한판 `67f9cb20…` 결산 7/7·O07 최소 5/5 및 단일 시험 자식 프로세스 종료 뒤 순차 복구 2회 독립 인수. 같은 결산을 복원했고 원장 1건과 슬롯·진행 백업을 보존했다. 항로도 포함 E 전체 출력 `5a849441…`은 별도다. [설치](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/I01/r5-settlement-e-applied-01a1c908/RESULTS.md) · [배포 독립 검토](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/I01/r5-settlement-independent-01a1c915/DEPLOYMENT-REVIEW.md) · [단일 프로세스 종료 독립 검토](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/I01/r5-settlement-independent-01a1c915/KILL-REVIEW.md)
- [x] **P02/P04/P08 복구 EXE 전경 확인.** `67f9cb20…`에서 15:13:51–15:27:15 KST 실제 정면 출격·113틱 저장/동일 및 새 프로세스 재개·5,603틱 C 점령 자연 종료·지도 결산을 확인했다. 정상 종료 뒤 같은 결산을 복원했다. 중복 표시 0건, 완료 슬롯 거부, 원장 1건, 슬롯·진행 백업 SHA 보존을 확인했다. UI 담당 `01a1c838…`는 (DONE)이다. [전경 결과](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/I01/r5-dimensions-canonical-windows-ui-prep-01a1c838/run-67f9cb20-20261111-01/RESULTS.md)

**P09 종료·TRACE 품질은 미완료다.** `tests/battle_flow.gd`의 테스트 소유 replay 정리만 E에 반영했다(`afa999ba…468826`). 설치 담당 `01a1c966…`과 독립 검토 `01a1c971…`는 (DONE)이다. F 고정 기준선의 적용 파일 회귀에서 flow PASS, 실제 엔진 exit 0, TRACE 2/26/20행, 잔류 0/0을 확인했다. 오디오 조사 `01a1c981…`는 엔진 종료 경계의 잔류를, 장벽 검토 `01a1c98b…`는 stop·교체된 이전 playback을 프레임 표본이 놓치는 반례를 확인하고 (DONE)으로 마감했다. 깨끗한 종료 인수에는 전체 테스트 소유 playback의 관찰 계약이 필요하다. 제품·엔진 수정은 별도 범위 결정이 필요하다. [E 반영·회귀](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/I01/p09-rp-apply-01a1c966-20261111/RESULTS.md) · [독립 검토](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/I01/p09-rp-review-01a1c971-20261111/RESULTS.md) · [엔진 경계](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/I01/p09-audio-boundary-01a1c981-20261111/RESULTS.md) · [수집 반례](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/I01/p09-barrier-scope-01a1c98b-20261111/RESULTS.md)

**P09 외에 현재 승인 범위에서 독립 착수할 필수 작업은 확인되지 않았다.** 승인 적벽 v1의 정면 플레이·동일 버전 저장/재개·결산 복구와 구버전 실행본 보존은 인수했다. 일반 I01b 인수는 아래 입력·승인 조건이 남았다. [항목별 부족 조건과 담당](P02-PROGRESS-CHECKLIST.md#2026-11-11-현재-인수-범위와-남은-필수-작업)

**남은 차단.** 다중호스트 두 번째 게시의 독립 확인은 미완료이며 차단된 시험은 재실행 금지다. K6 정식 검증 재개는 2026-11-12 승인됐다. 현행 기준에서 17행 기대값과 15·16행 전경 입력 증거를 결속하고 재동결·독립 리뷰를 거쳐 실행한다. 검사기 r2는 독립 미통과·E 미적용으로 추가 수정을 보류한다. O07은 기존 담당 범위이며 운영 권위 인계 승인과 외부 지급 수신자·계약·시험 환경, 실기기 전원 상실 조건이 남았다. [후속 마감 보고서](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/I01/p02-checklists-closeout-01a1c907-20261111.md)


### 별도 후속 · 확장과 검증

- [ ] P02의 일반 정의·추가 소비자와 기본 제품 리플레이 진입, P03의 첫 작전 밖 상태·모듈, P07의 호송·통신소·재점령·정비 등 확장 흐름은 별도 조각으로 추적한다. 개발 메뉴의 v1 관람은 인수했다.
- [ ] P06의 A05/A06 종합 인수, P08의 Android export·실기기·폭넓은 사람 플레이와 성능 검증, P09의 종료·TRACE·문서 진단을 별도 후속으로 추적한다. 구버전은 승인 당시 실행본과 데이터로 보존하며 추가 이관 지원과 일반 관람 UI 범위는 별도 결정이다.

## 2026-11-11 P09 진행 이력

당시 판정과 실패 증거를 보존한다. E 미반영 표시는 적용 전 이력이다.

**P09 기존 증거 대조 완료·미완료 조건 유지.** 현행 flow/group 검증 담당 01a1c95b…는 (DONE), P09는 미완료다. 11/11 종료 정리 3파일 SHA 일치 F 고정 소스에서 두 테스트는 기능 PASS, 보완 캡처 실제 엔진 PID 30044/19996 모두 exit 0 및 TRACE 3/1파일 유효 쓰기를 확인했다. 종료 잔류는 첫 실행 flow 54/18·group 2/1, 보완 실행 flow 59/20·group 0/0(ObjectDB/리소스)로 깨끗한 종료 인수는 실패했다. flow의 테스트 소유 replay 객체 정리 누락과 제품 UiSound의 빠른 종료 수명 경계를 별도 최소 수정 후보로 인계한다. 오디오 잔류는 변동하며 엔진 비동기 정리와 테스트 대기 부족의 인과는 미확정이다. 코드 무수정이며 EXE 67f9cb20과 동일 제품으로 주장하지 않는다. 기존 종료 정리 담당 DONE, CRLF/접근 위반 등 다른 P09 조건은 유지한다. [현행 실행·원인 구분](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/I01/p09-flow-group-01a1c95b-20261111/RESULTS.md) [기존 원문 대조](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/I01/p09-trace-exit-review-01a1c954-20261111/RESULTS.md)

**2026-11-11 P09 테스트 전용 장벽 수집 범위 검토 (01a1c98b…, 담당 범위 DONE / 후보 인수 차단).** rp-only flow SHA afa999ba…468826 확인. 현재 노드/stream/playback은 조회할 수 있으나 UiSound에 전체 playback 생성 이력 관찰 계약이 없고, 동기 stop/교체된 이전 playback은 프레임 샘플링에서 누락될 수 있다. 제품 없는 한 프레임 play→stop→play→stop 반례에서 현재 조회는 비었지만 이전 playback 2개가 살아 있고 finished 신호는 0이었다(실제 Godot PID 27412 exit0, 전체 진단0). 이는 누락 반례 PASS이며 flow/group 장벽 인수 아님. 공유 load 리소스와 테스트 소유 합성/노드를 구분했고 전체 수집 완전성은 미입증이므로 불완전 후보를 제출하지 않았다. 제품 패치/E 코드 변경 없음, flow/group 후보 분기·timeout·정상 원샷/루프 보존 검증은 선행 조건 차단으로 미실행, 새 제품 TRACE 없음. P09/P02 미완료 및 기존 BGM/역사 조건 유지, CHECKLIST-OPEN은 루트 담당. [소유권·차단 근거·반례 패치·SHA·PID/exit·전체 로그](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/I01/p09-barrier-scope-01a1c98b-20261111/RESULTS.md)

**2026-11-11 P09 오디오 엔진 경계 원인 분리 (01a1c981…, 담당 범위 DONE / 해결 인수 차단).** 실제 Godot 4.7.2 ed1daf0bf·Dummy에서 제품 없는 WAV/AudioStreamPlayer 최소 재현도 owner·자식 노드 소멸 뒤 6객체가 잔류했다(실제 엔진 43636 exit0). 참조 소멸 관찰 대조는 15프레임·84ms에 모두 해제, 엔진 5560 exit0 및 진단0/0. 고정 대기값 해결은 인수하지 않는다. 정확한 엔진 소스에서 stop은 삭제 상태 요청, 믹싱 후 SafeList 지연 해제이며 종료 시 아직 남은 목록 처리 경계를 확인했다. 제품 UiSound 변경 근거는 없어 후보/E 코드 변경 없음; rp-only SHA afa999ba…468826 유지. 후속 최소 조건은 전체 테스트 소유 참조를 포괄하는 종료 장벽 검증 또는 정확한 엔진 커밋의 목록 계측·종료 정리 후보 검토다. P09/P02 미완료 및 기존 BGM/역사 조건 유지, CHECKLIST-OPEN은 루트 담당. [원인·실제 PID/exit·SHA·차단 조건](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/I01/p09-audio-boundary-01a1c981-20261111/RESULTS.md)

**2026-11-11 P09 rp-only E 반영 완료 (01a1c966…, 담당 범위 DONE).** 독립 검토 01a1c971 PASS 및 루트 지시에 따라 `tests/battle_flow.gd` 한 파일만 적용했다. 적용 전 `00453ca1…7c90b`, 적용 후 `afa999ba…468826` 정확 SHA 확인·F 원본 보존. group/UiSound/대기/실패 probe는 미반영. 이전 고정 F 기준선에 실제 반영 파일만 넣은 최소 flow 회귀는 BATTLE_FLOW_PASS, 실제 엔진 PID 43656 exit0, TRACE 2/26/20행 유효 쓰기, 잔류 0/0. 최신 E 전체 실행과 구분하고 manifest 경로별 차이는 보고서에 보존했다. 오디오 시간 경계는 변동하므로 별도 미해결 유지하며 P09/P02 전체 미완료, CHECKLIST-OPEN은 루트 담당. [적용 diff·SHA·전체 회귀 증거](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/I01/p09-rp-apply-01a1c966-20261111/RESULTS.md)

**2026-11-11 P09 후속 후보 (01a1c966…, 담당 범위 DONE / E 코드 미반영).** 별도 replay 소유권 해제만으로 flow 코어 잔류 54객체/18리소스가 해소되고 오디오 5/2만 남았다. `ownership-only.patch`를 독립 검토 가능한 한 파일 후보로 분리했다. 오디오 소유 노드 해제는 WeakRef로 확인했지만 즉시 종료 및 명시 stop 실험에 재생 잔류가 남았고 100ms 대기는 group 2/1로 실패했다. 제품 UiSound 원본을 유지한 500ms 종료 경계 대조는 flow/group 기능 PASS, 실제 엔진 PID 42800/43420 exit0, TRACE 3/1파일 유효 쓰기, 잔류 모두 0/0이며 최소 오디오 회귀도 0/0이다. 그러나 고정 대기만으로 안정적 해결은 미입증이므로 오디오 종료는 미확정, 500ms 패치는 실험 후보로만 보존한다. E 코드 반영은 루트의 독립 검토 통과와 후속 지시 대기. P09/P02 미완료 및 기존 역사 조건 유지, CHECKLIST-OPEN은 루트 담당. [후보·분리 패치·전후 SHA·전체 증거](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/I01/p09-cleanup-candidate-01a1c966-20261111/RESULTS.md)

**2026-11-11 P09 rp-only 독립 검토 (01a1c971…, 담당 범위 DONE / E 코드 미반영).** `tests/battle_flow.gd` 한 파일 소유권 정리 인수 PASS. 전 SHA `00453ca162c30bcffa8e39dd4b65c5da930a240ba8047bacfbce6cc28147c90b` → 후 SHA `afa999ba1e3d6bde19293999aab2f79034a30312b19ce11ea6fa604cda468826`. 기준 1,842파일 중 flow만 변경, fingerprint 비교·기존 assertion·실패 exit 보존 확인. 선행 코어54객체/18리소스 제거 증거의 로그/TRACE SHA 재확인. 독립 정확 후보 flow 실제 엔진 43964 exit0, TRACE 2/26/20행 및 0/0; F 별도 실패 probe는 WeakRef rp 소멸 후 기존 최종 TEST_FAIL, 실제 엔진 36328 exit1 및 잔류0/0. 이번 대기 없는 0/0도 오디오 안정 해결은 아니며 선행100ms 실패/500ms 대조와 분리한다. 오디오·임의 대기·group/UiSound 변경은 인수 제외. 루트가 구현 채팅에 rp-only E 반영 후속 지시 가능. P09/P02 전체 미완료 및 CHECKLIST-OPEN 루트 담당 유지. [독립 인수 보고서](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/I01/p09-rp-review-01a1c971-20261111/RESULTS.md)

## 2026-11-11 복구·전경 진행 이력

아래 기록은 각 시각의 상태다. 최종 인수와 남은 작업은 위 현재 항목을 따른다.

**P02 현행 복구 배포 전경 검증 완료 (2026-11-11 15:28 KST).** EXE67f9cb20…을 Windows 실제 입력으로 15:13:51–15:27:15 검증했다. 정면 표준 직접지휘 Tick113 저장→동일/새 프로세스113 복원→A활성/C점령→Tick5603(560.3초) 목표달성→지도 복귀를 확인했다. 정상 창 종료 후 새 프로세스의 같은 결산ID/사유/시각 재표시, 완료슬롯 checkpoint_already_settled 거부, 같은 실행 왕복 중복표시 없음, 원장1건·주슬롯/백업SHA 보존을 확인했다. UI 담당 (DONE), 마지막 시험 창 정상 종료. 앞선 입력 대기·전경 진행 기록은 이 결과로 대체한다. 항로도 포함 현 E 전체 배포, 일반 정의 전체·K6·외부 지급·전원상실 인수로 확대하지 않는다. [실제 입력·화면·원장 증거](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/I01/r5-dimensions-canonical-windows-ui-prep-01a1c838/run-67f9cb20-20261111-01/RESULTS.md)

**단일 시험 프로세스 강제 종료 복구 제한 인수 (2026-11-11 15:20 KST).** 합성 완료 결과로 실제 원장 기록·잠금 해제 후 지도 게시 전 소유PID39436 종료(exit1), 순차 재실행2회(exit0) 동일 결과·원장1건·진행슬롯/백업 바이트 보존·왕복 중복표시 없음을 독립 대조했다. 실행·검토 담당 (DONE). 기존 원장백업 동반 종료·자연전투 종료경계·전원상실은 미검증이다. 별도 Windows 실제 플레이는 진행 중이다. [독립 종료 복구 증거](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/I01/r5-settlement-independent-01a1c915/KILL-REVIEW.md)

**시험 프로세스 강제 종료 복구 완료 보고 (2026-11-11 15:16 KST).** 실제 원장 기록·잠금 해제·지도 미게시 뒤 소유 시험PID39436만 종료하고 새 프로세스2회 동일ID/사유/294.9초·원장1건·슬롯/진행백업SHA 보존을 확인했다. 합성 완료DTO와 외부 대기 탐침을 사용했으며 자연전투·전원상실·기존 원장백업 보존은 범위 밖이다. 실행 담당 (DONE), 기존 독립 검토01a1c915에서 증거 대조 중. Windows 실제 UI는 별도 담당이 Tick113 저장/동일전장 복원 후 새 프로세스 재개를 검증 중이다. [강제 종료 증거](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/I01/r5-settlement-kill-01a1c93a/RESULTS.md)

**Windows 실제 검증 재개 승인 (2026-11-11).** 사용자가 지금부터 실행 및 키보드·마우스 사용을 직접 승인했다. 기존 UI 담당01a1c838-6ef7-7dc0-ba62-06e476c74a98을 유일한 전경 담당 (ING)으로 재개했다. 대상은 복구 배포67f9cb20…의 고유 F 프로필이며 약30분 출격/저장/재개/C점령/결산·지도/재실행 결과 재표시를 검증한다. 강제 종료 담당01a1c93a는 별도 headless PID·프로필만 사용한다. 이전 입력 대기 기록은 해소됐으며 K6 정식 보류는 유지한다.

**복구 배포 제한 독립 인수 완료·다음 작업 (2026-11-11 15:08 KST).** EXE67f9cb20…·DLL·PCK1538항목을 독립 대조해 WorldLink 단독 변경 및 규칙지문 동일, 결산7/7·O07최소5/5 로그/파일 보존을 수용했다. 검토 담당 (DONE). 실제 전경은 사용자가 가능한 시간을 나중에 알리기로 하여 입력 대기다. 새 (ING) 01a1c93a-4759-7880-b0f3-c5610e11c491에서 F 시험 프로세스만의 순차 강제 종료 후 복구 검증을 배정했다. 시스템 전원차단·전경입력·K6정식·차단된 다중호스트 시험은 금지한다. [독립 배포 인수](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/I01/r5-settlement-independent-01a1c915/DEPLOYMENT-REVIEW.md)

**전경 인계 최신화 완료 (2026-11-11 15:04 KST).** UI 담당은 복구 배포본67f9cb20…의 EXE/DLL SHA를 대조하고 새 프로세스 결과 복원·같은 프로세스 중복 표시 없음·완료 슬롯 거부·원장/파일 보존 절차를 준비했다. 준비 담당 (DONE). 실제 입력은 미실행이며 복구 관측을 포함한 권장 시간은 연속30분이다(이전25분 계획을 대체). 배포 독립 증거 검토는 진행 중이다. [최신 전경 계획](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/I01/r5-dimensions-canonical-windows-ui-prep-01a1c838/UI-VERIFICATION-PREP.md)

**결산 복구 배포 검증 완료·독립 대조 진행 (2026-11-11 15:00 KST).** WorldLink 단독 EXE67f9cb20…에서 결산복구7/7·O07최소5/5 exit0 보고를 확인했다. 직전d267012a 대비 PCK 변경은 world_link.gdc 한 개, 저장/리플레이 지문은 동일하다. 배포 담당 (DONE); 기존 독립 검토 채팅01a1c915…와 UI 준비 채팅01a1c838…에서 증거 대조·인계 갱신을 진행한다. 항로도 포함 현 E 전체 출력5a849441…는 대조용이며 이번 인수 대상이 아니다. 실제 전경·강제 종료·전원 상실·K6는 미실행이다. [배포 증거](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/I01/r5-settlement-canonical-windows-01a1c7c7/RESULTS.md)

**결산 복구 E 설치 검증 완료 (2026-11-11 14:42 KST).** world_link.gd 승인SHA7e3b1d42… 설치를 오케스트레이터가 재대조했다. F 원본 백업, E 소스 직접 헤드리스3/3·exit0 및 복구/거부/보존 확인. 설치 담당 (DONE), 기존 배포 채팅 01a1c7c7-8c4f-73c0-b1f5-485b7346b766에서 (ING) 새 빌드·패키지 검증을 시작했다. 배포 대조에서 별도 항로도 스크립트·데이터·이미지와 Android 프리셋 변경을 확인했다. P02 복구 인수는 직전 d267012a… 고정 입력+승인 WorldLink만의 F 배포본으로 분리하고 현 E 전체 출력은 대조용으로 유지한다. 현 E의 추가 변경은 되돌리지 않으며 해당 작업 전체를 인수한 것으로 표시하지 않는다. 새 배포 및 실제 강제 종료·전경 인수는 미완료다. [적용 증거](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/I01/r5-settlement-e-applied-01a1c908/RESULTS.md)

**결산 복구 독립 수용·E 반영 진행 (2026-11-11 14:36 KST).** 독립 기준 공백 재현, 후보8/8·추가6/6 모두 exit0. 동일 결과 재표시·바이트 보존·잠금 해제 후 재시도·새 결산 우선 표시를 확인했다. 확정 파일 복제 경계의 한정 수용이며 실제 강제 종료·전원 상실은 미검증이다. 검토 담당 (DONE), 구현 채팅 01a1c908-13c7-72a1-9123-acc63d325f5c를 (ING)으로 재개해 world_link.gd 한 파일의 기준SHA 확인·F 백업·E 설치·검증을 배정했다. 설치 완료·배포 전경 인수는 아직 아니다. [독립 증거](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/I01/r5-settlement-independent-01a1c915/REVIEW.md)

**결산 복구 후보 구현 마감·독립 심사 진행 (2026-11-11 14:28 KST).** 구현 채팅 01a1c908-13c7-72a1-9123-acc63d325f5c는 (DONE). F 후보의 순차 Windows 헤드리스8/8·exit0, 동일 결과 재표시·원장/슬롯/백업 보존을 보고했다. 확정 파일 복제 시험이며 실제 강제 종료·전원 상실은 미검증이다. 새 (ING) 독립 검토 01a1c915-0255-7393-bf97-d5939cd40e17에서 심사 중이며 E 미반영이다. [후보·인계 증거](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/I01/r5-settlement-redisplay-01a1c908/RESULTS.md)

**전경 검증 준비 완료 (2026-11-11 14:24 KST).** 담당 01a1c838-6ef7-7dc0-ba62-06e476c74a98은 준비 범위 (DONE). EXE·DLL SHA 대조, F 격리 프로필, 실제 클릭 순서·관측값·실패 기준을 정리했다. 실제 실행은 미착수이며 예상15–18분·권장 연속25분 입력 시간이 필요하다. 결산 복구 후보가 재빌드되면 새 SHA·지문으로 계획을 갱신한다. [준비 문서](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/I01/r5-dimensions-canonical-windows-ui-prep-01a1c838/UI-VERIFICATION-PREP.md)

## 1. 현재 확정된 요약

- I01a, P0, P1, 기하 기준선 수정, P2a, P2b와 [P2c](I01B-P2C-RESULT-20261101.md), [제한 활성 owner 교체](I01B-ACTIVE-REPLACE-RESULT-20261104.md)의 한정된 성과는 검사·독립 검토·기록을 마쳤다. P2c와 활성교체의 문서/압축도 각각 독립 closeout 수용을 받았다(§8).
- `codex/feature-i01b-not_remove`의 `fb660cea69207fd332e26128643007694910a253`는 25경로 커밋·원격 푸시와 실제 원격 SHA 확인을 마쳤다. 이것은 P2b 작성 전 범위다.
- P2b/P2c/활성교체 이후 미커밋 구분은 당시 감사 범위를 따른다. 11/11 E 작업본에서 확인한 feature HEAD는 `520f142fdbda8d245004076e3f9262b3ef723ad7`이다. 위 25경로의 과거 원격 확인을 이번 작업본 변경이나 문서 갱신의 원격 반영으로 확대하지 않는다.
- 첫 작전 v1 호스트·헤드리스·관람·저장과 승인 정면 복구판 전경·단일 프로세스 복구는 인수했다. 일반 소비자·권위 C0/운영 Cn·전역 명령 커서, 전체 제품 공간과 운영 저장은 남았다.
- P01의 P2c 정식1~3/독립 계획 심사는 완료됐고 제한 구현·최종5b·6 기록까지 마쳤다. 이어 같은 원입력의 활성 owner 내부 runtime 교체도 독립5b 제한 수용·6 closeout을 완료했다. 전체 host/save/cursor/제품 공간 완료를 의미하지 않는다. 과거 사용량 한도 중단과 계획 미착수 표시는 이전 시점 이력이다.

## 2. 진행 방식·보존·소통 요구

| ID | 상태 | 요구사항과 근거 | 인수 조건·다음 적용 |
|---|---|---|---|
| W01 | 상시준수 | 당시 C 원본 유지 및 새 작업트리 금지. 현행 사용자 지정 작업본은 `E:/WorkSpace/SpaceBattleOfThreeKingdoms` | 후속 시작마다 실제 cwd/브랜치/HEAD 확인. C 보존, 새 작업트리 생성하지 않음 |
| W02 | 상시준수 | 다른 작업의 기존 tracked/untracked 변경을 폐기·덮어쓰기·일괄 커밋하지 않음 | 시작 SHA 동결·소유 경로/혼합 hunk 분리·최종 누락/예상외 변경0. [feature 보존 감사](../../../tmp/i01b-feature-push-20261029/final-push-audit.json), [P2b 감사](../../../tmp/i01b-next-20261031/final-delivery-audit.json) |
| W03 | 상시준수 | [워크플로우 플레이북](../../../워크플로우-플레이북.md), [CLAUDE](../../../CLAUDE.md), 적용 AGENTS와 정본 인계를 먼저 읽음 | 1~3 의도/스펙/분해 → 4 구현 → 5-a 검사 → 5-b 독립 심사 → 6 기록. 조율·실행·독립 검토를 분리하고, 구현 검토는 구현과 다른 모델이 수행 |
| W04 | 상시준수 | 코드 재시도 K6, 실패/중단·실제 exit·원문 로그 구분 | 상한 내 수정·재검사, 초과 시 정확한 미완료 보고. PASS/exit0에 SCRIPT ERROR가 있으면 무효. P2b attempt2 무효와 최종5 사용 이력 보존 |
| W05 | 상시준수 | 확정 방향을 재질문하지 않고 불필요한 확인 없이 체크리스트 기반으로 계속 진행 | 사용자 결정이 필요한 미정만 구분. 실제 실행 환경의 파일/네트워크 권한 제한은 정식 권한 요청으로 처리하고 승인·실행 완료를 추정하지 않음 |
| W06 | 상시준수 | 한국어로 현재 작업·검사·남은 일을 간결하게 설명하고 상태 질문에 정확히 답함 | 사용량 한도/도구 장기 응답/권한 대기와 실제 코드 실패를 구별. 같은 대기 상태를 완료라고 보고하지 않음 |
| W07 | 상시준수 | 사용자의 ‘체크리스트 보여줘’, ‘진행 내용 체크리스트 작성’ 요구 | [상위 체크리스트](../CHECKLIST-OPEN.md), [P2b 진행 정본](I01B-P2B-CHECKLIST-20261031.md), 이 통합 문서의 완료·미완료·근거를 함께 갱신 |
| W08 | 상시준수 | 다른 세션 변경·기존 SESSION-HANDOFF를 보존하며 후속 인계 기록을 남김 | 공유 원문 전역 치환/덮어쓰기 없이 결과 문서에 압축 인계. 브랜치 전환/병합/커밋 전 작업자 확인 |
| W09 | 완료 | 명시 요청된 새 세션의 압축 인계를 받아 기존 캠페인 작업을 이어받음 | 원본 정본과 이전 이관 증거를 확인하고 P2b까지 진행·기록. 현재 추가 새 세션 생성이나 작업트리 변경을 요구하는 상태가 아님 |

## 3. 확정 설계 선택 — 기록 반영 완료

이 절은 **사용자 선택이 정본 문서에 반영됐다는 완료**다. 같은 기능의 제품 구현·검증은 다음 절의 별도 미완료 행으로 추적한다. 초기 문서의 OPEN/미선택 이력보다 최신 결정 원본을 적용한다.

| ID | 상태 | 확정 요구·결정 원본 | 인수 조건·다음 적용 |
|---|---|---|---|
| D01 | 완료 | [H0](H0-DECISION.md): 단일 성계 연속작전, 보급로 개방, 정면/우회, 시간 경과 증원 | 설계 범위 기록. 다중 독립 전투로 대체하거나 확정 범위를 다시 묻지 않음 |
| D02 | 완료 | H0: 호송 차단·통신소 지연·재점령까지 설계에 포함, 제작 순서는 분리 | 확장 설계 범위를 누락하지 않되 단계 제작과 제품 완성을 구분 |
| D03 | 완료 | [H1 시간/공간](H1-DECISION.md): 약20 게임분 비교 방향, 실제 플레이·정지·배속 기록, 효과 지형 후 장애물1~2개 비교 | 약20분·치수/속도는 검증 전 후보. 측정 전 확정 수치로 바꾸지 않음 |
| D04 | 완료 | [H1 정책](H1-POLICY-DECISION.md): 승리 시 현재 가동 보급거점 통제, 동일 actor/소유의 점령 중단량 보존 | 확보 이력과 현재 보유/가동을 구분. 구체 점령·회복·비용 수치는 별도 |
| D05 | 완료 | H1 정책: 명시 철수는 별도 부분생환 성과, 목표/지휘 상실 동시는 실패 우선; 지역 집결→유한 정비→복귀, 군 사기는 경고 | 철수를 임의 승리로 승격하거나 자동 회복/파괴함 부활로 구현하지 않음. 전체 동일 틱 순서는 미정 |
| D06 | 완료 | [H1 사건](H1-EVENT-DECISION.md): 본대 출발과 같은 논리시각 통신소 가동 완료는 지연 인정, 출발 후 소급 없음 | 바깥 tick만 같다는 이유로 동시 처리하지 않음. 반복 지연/일정 수치를 임의 결정하지 않음 |
| D07 | 완료 | H1 사건: 유효 지연만큼 공개 시한 연장, 시한과 같은 시각의 유효 목표/탈출 인정 | 단일 논리시계와 기존 지휘 상실 동시 실패 우선 유지 |
| D08 | 완료 | [H2](H2-DECISION.md): 현재 상태+후속 명령, 초기에는 동일 규칙 버전 재개; 관람과 논리 재생 구분 | 전체 필드/커서/원자성/호환/O07 정합화가 실제 구현 인수 조건. 방향 선택만으로 저장 완료를 선언하지 않음 |
| D09 | 완료 | H2: 자기 시설 상실 보고·상대 시설 마지막 확인·적 재고 비공개·필수 일정 공지 | 실제 상태·진영 지식·공개 임무 정보 분리. 모든 현재 적 상태 상시 공개로 바꾸지 않음 |

## 4. 한정된 구현·검사·기록 성과

| ID | 상태 | 완료한 범위와 근거 | 제품 완료로 확대하지 않을 경계 |
|---|---|---|---|
| I01 | 완료 | [I01a](I01A-IMPLEMENTATION-RESULT-20261027.md): 순수 설정 326체크, 60구축/24명명 거부/추가17 회귀 | 실제 runtime/host/save 완성이 아님 |
| I02 | 완료 | [추격 기준선 수정](DATA-RULES-BASELINE-FIX-20261028.md): fallback170 데이터 정본화와 실제 추격10사례 | 원본의 다른 기하 리터럴 실패 이력과 별개 |
| I03 | 완료 | [P0 재고](I01B-PREPARATION-20261028.md): 19모듈·283선언·14앵커, 실제 실행/변조 거부·독립 수용 | 선언 재고는 저장 스키마가 아님 |
| I04 | 완료 | [P1 시계·원본 이관](I01B-P1-RESULT-20261028.md): 10seed×3배속×정지유무60사례, trace50/100/150ms, tick2/end150; 원본 core exit0 확보 | 과거 managed core exit결측과 원본 data_rules 실패는 이력으로 유지. tick×고정값 복원 금지 |
| I05 | 완료 | [기하 기준선](DATA-RULES-GEOMETRY-RESULT-20261028.md): allowlist/skip 확대 없이 JSON 분리, 9종 exit0·기하56·정확비교3588·오류거부3·독립 수용 | 실제 Android export·제품 공간·선체 외곽/중첩 부재 보장 아님 |
| I06 | 완료 | [P2a](I01B-P2A-RESULT-20261028.md): 2프로필×10seed×fresh2의40개 B0관측·2352체크와6종 exit0·독립 수용 | B0≠C0, 선택 필드·초기 빈 contacts 관측, save_policy UNCLASSIFIED |
| I07 | 완료 | [P2b](I01B-P2B-RESULT-20261031.md): contacts와 sup_*10 부분 인메모리 추출/검증/복원, 최종40사례·2202체크·33거부·6종 exit0·독립 수용 | 준비된 target의 비대상 상태는 호출자 선행 책임. 전체 ST11/C0/Cn/checkpoint/실제 adapter가 아님 |
| I08 | 완료 | [P2b 진행 체크리스트](I01B-P2B-CHECKLIST-20261031.md): 0~6 기록과 [독립 심사](REVIEW-I01B-P2B-20261031.md), 최종3594 보존/manifest61 확인 | 3594는 당시 dirty/untracked 분모로 깨끗했던 CHECKLIST는 미포함. CHECKLIST 한 행 외 보존은 별도 원문 복구 SHA 증거 |

## 5. 브랜치·커밋·푸시 요구와 현재 미커밋 구분

| ID | 상태 | 요구사항·현재 근거 | 인수 조건·다음 적용 |
|---|---|---|---|
| G01 | 완료 | 사용자 요청대로 feature 이름에 `not_remove`: `codex/feature-i01b-not_remove` | 브랜치 실존, 마지막 알려진 HEAD `fb660cea69207fd332e26128643007694910a253` |
| G02 | 완료 | 25경로 커밋·origin 푸시·실제 원격 SHA 일치 확인. [최종 푸시 감사](../../../tmp/i01b-feature-push-20261029/final-push-audit.json), [재현·범위](I01B-FEATURE-REPRO-20261029.md) | 7종 정확 등록본 검사+P0, 필수 기존 BundleLayout 의존성 포함, UI/브랜딩/대량 tmp 제외. 원격 확인은 당시 실행 증거이며 오늘 신규 push를 뜻하지 않음 |
| G03 | 완료 | 사용자 feature 지시를 CLAUDE의 기본 main 병합 규칙보다 우선해 적용. 당시 main `8292805143f4561a4f5258d40b7b94adf4ff5802` 유지, index 비어 있음, 기존1091파일 SHA 보존 | main 병합·강제 push·PR 생성 없음 |
| G04 | 상시준수 | 완료된25경로 푸시와 P2b/P2c/활성교체·후속 문서 미커밋을 구분 | 기존 커밋 요청을 이후 모든 작업의 자동 커밋·푸시 승인으로 확대하지 않음. 후속 코드/검사·문서와 이 통합 체크리스트 갱신은 원격 반영 완료라고 표시하지 않음 |

## 6. 요구 ID와 상세 근거 — 전체 I01b NOT_READY

아래 행은 상세 범위와 근거 이력이다. §0의 11/11 판정을 현재 상태로 우선 적용한다. P02 행의 이전 후보 대기·K6 준비 허용 및 O07 이관 HOLD는 해당 시점 기록이다.

| ID | 상태 | 남은 요구 | 완료 인수 조건·다음 작업 |
|---|---|---|---|
| P01 | 완료 | P2c 정식 1~3/독립 계획 심사 | [계획](../../../tmp/i01b-p2c-20261101/PLAN.md)과 [반례 보완 계획 독립 수용](../../../tmp/i01b-p2c-20261101/REVIEW-PLAN-AMENDMENT-EMPTY-FORM-20261101.md), [전용 체크리스트](I01B-P2C-CHECKLIST-20261101.md)가 실제 존재한다. 이후 제한 구현·최종5b/closeout도 완료(§8). 실제 host/전체 저장 인수는 아래 미완료 행으로 유지 |
| P02 | 미완료 | 일반 제품의 공통 소비자·독립 다중호스트 게시 | 개발 후보 v1과 승인 적벽 정면 복구판 전경·순차 복구는 완료했다(§0). 일반 제품·전체 인수는 미완료. **아래는 이전 구현·실패 이력:** [제한 headless](P02-FIRST-HEADLESS-RESULT-20261107.md) 및 [CLI→AutoResolver worker](P02-WORKER-RESULT-20261107.md) 및 [제한 fresh replay CLI](P02-REPLAY-RESULT-20261108.md) 및 [private owner 표시용 사건 회수](P02-VIEWER-EVENTS-RESULT-20261108.md) 구현 한정 수용. [legacy WorldMap 결산 경계](P02-LEGACY-OUTCOME-RESULT-20261108.md)도 한정 수용. [legacy FleetBattle3D 후보 준비](P02-HOST-PREP-RESULT-20261108.md)는 지정 오류와 동기 호출만 한정 수용. [전투 준비 실패 안내·최초 탈출](P02-PREP-ERROR-RESULT-20261108.md)도 지정 실패에서 한정 수용. [진행표](P02-PROGRESS-CHECKLIST.md). Windows 첫 작전 v1은 실제 호스트·headless·관람 공통 adapter, WorldMap 자동 해결 시작·진행·취소·join 및 결산, 저장·재개, 읽기 전용 제품 관람을 통합 인수했다. 첫 작전 밖의 제한 호스트·헤드리스·리플레이는 2틱·150ms 자연 종료와 결산·사건 일치를 확인했다. 개발·레거시 지도 종료 리소스 잔류를 해소했다. 적벽 기하 후보 73개, 제한 운영 슬롯 19개 및 새 프로세스 재개 6개 검사와 K6 Windows 입력 사전 계측을 추가했다. 제한 저장·복원 버튼과 첫 작전 v1 지속 결산의 순차 재시작을 실제 Windows에서 확인했다. Windows 자동 결산 잠금 해제 뒤 같은 결과가 한 번 기록됐다. 일반 I01/K01~08 전체 인수는 미완료다. 승인된 적벽 v1 직접 지휘 정면 정의 한 건은 독립 검증된 5파일을 E 작업본에 적용했다. 이전 파일은 승인 당시 실행본을 보존해 열고 현행의 지문 불일치 거부를 유지한다. 일반 출격 버튼과 추가 정의 및 일반 O07 거래 전체는 미완료다. 네이티브 초기화 K6 첫 정식 실행은 5행 편성 검사에서 실패했다. 새 21행 독립 재심 뒤 허용된 추가 정식 실행 REVIEW-11을 실시했다. 58개 중 28개 통과, 1개 실패, 29개 미실행. 5행은 before·after 통과했다. 15행 before의 입력 계측기는 정확한 전경 HWND 조건에서 멈췄다. 실제 입력 0회, 16행 미실행, 본선 미반영이다. 후속 1회가 허용됐다. 전경 계측·런처·Space 해제 대조를 수정한 격리 사전 검증에서 15·16행 before·after 실제 조작 네 건이 통과했다. 독립 원문 대조는 26회 중 25회 일치했다. 16행 after는 재시험에서 창 제목 대조를 7/7 통과했으나 기존 Space 해제 시간 기준에 실패했다. 수정 기준의 후속 시험은 마지막 클릭 요청 만료로 중단했다. 새 v8 격리 사전 시험에서 Windows 실제 조작 7회와 동일 창 지도 복귀를 확인했고 제품·계측 판정이 통과했다. P02가 네 건의 26회 실제 입력 원문과 REVIEW-13 21행 계획을 독립 승인했다. 정식 1회는 15행 before 준비 확인 300초 만료로 exit 1 및 집계 FAIL. 제품 프로세스 0, 58개 작업 미실행, 독립 사후 판정과 본선 반영은 미완료다. [REVIEW-13 집계](../../../tmp/p03-k6-review-20261109/review13/run-once/aggregate.json) [정식 집계](../../../tmp/p03-k6-review-20261109/second-attempt/run-once/aggregate.json) · [독립 사후 판정](../../../tmp/p03-k6-review-20261109/second-attempt/REVIEW-V6-11-P02-RESULT-INDEPENDENT.md). REVIEW-14의 Windows 사전 확인을 격리 단일 실행기에 연결했고 합성 실행 통합 시험이 통과했다. GUI 입력 시간 만료 검사까지 연결했고, 사용자 요청으로 새 고정 SHA 출력 전에 중단했다. 사용자가 정식 준비 재개를 지시했다. 현재 E의 Atlas·O07을 공통 기준으로 K6 세 격리 lane을 재구성하고 임포트를 통과했다. 그 뒤 Atlas/브리핑 제품 코드가 다시 변경돼 새 동결본을 만들지 않았다. 현재 E 기준 재대조, 동일 SHA 독립 재심과 현행 GUI 실제 검증, Windows 독점 입력 시간 확인이 남았다. 일반 O07은 실제 Windows 강제 종료와 새 프로세스 11/11에서 확정되지 않은 저장을 공개하거나 쓰기 권위를 주지 않는 동작을 확인했다. 후속 Win32 격리 후보는 E: exFAT의 교체 직전·직후 실제 시험 프로세스 강제 종료에서 각각 기존·새 세대를 동일 결산 영수증으로 복원했다(7/7). 이전 잠금 자동 회수·전원 상실 내구성·본선 통합·외부 지급은 미인수다. 독립 재실행 7/7 및 DLL을 포함한 Windows 내보내기는 통과했다. 후속 독립 검토에서 Windows x64 비계측 배포 EXE 시작 15/15 및 계측 EXE의 저장·새 프로세스 재개·지도 복귀를 통과해, 승인된 제품 12개 파일을 E 공유 작업 트리에 반영했다. 후속 격리의 원문 없는 지문 후보에서 같은 소스 개발↔토큰화 EXE 양방향 실제 1틱 재개를 확인했다. 독립 검증에서는 정확한 이전 지문 18개가 확인된 개발 슬롯 한 건만 복제본 이관에 성공했다. 빈 해시 슬롯은 계속 거부된다. 원문 전체가 노출된 조건에서의 목록 검증 및 기본 배포 경로 연동이 미해결이어서 본선 적용은 보류했다. [적용 매니페스트](../../../tmp/o07-win32-independent-review/verification/deployment-followup-prep/deployment-manifest.json) [독립 검토](../../../tmp/o07-win32-map-rebase-review-r2/HOLD-review.md) legacy 불변/중복 변환 금지 |
| P03 | 미완료 | 전체 C0/운영 Cn 상태와 명령 적용·대기/suffix/커서 | 승인된 적벽 v1 공통 초기 상태와 저장·복원 및 A06 제한 ST01~18 사건 참조 거부는 확인했다. [A06 적용](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/I01/a06-st-reference-20261111-01/RESULTS.md). P2c의 제한 fresh 준비와 동일-context 활성 owner 교체는 확인했다. 전체 S/ST·모든 활성 모듈·운영 Cn/global cursor·실제 host 완료 경계는 여전히 후속 인수 대상 |
| P04 | 미완료 | 전체 상태+후속 명령 저장·동일 규칙 버전 재개 및 오류 원자성 | 개발 v1 로컬·외부 저장은 완료했고 최신 EXE는 제한 저장·재개를 인수했다. A06의 주 슬롯 교체 중단 복구와 O07의 로컬 강제 종료 복구는 제한 성과다. 결산 기록 직후 단일 시험 프로세스 종료 및 다음 지도 재표시는 제한 인수했다. 독립 두 번째 호스트 무게시와 일반 운영 지급은 §0 참조. **이전 제한 owner 범위:** 제한 owner의 잘못된 packet/다른 context 거부와 현재 sim 보존은 확인했다. 전체 상태·원장/처리키·외부 저장파일/호환·global cursor는 미완료이며 packet시점 사건복원을 외부 효과의 전역 중복억제로 표시하지 않음. 외부 스키마 미정은 임의로 메우지 않음 |
| P05 | 미완료 | 원 A04 제품 공간 | 승인 적벽 v1 직접 지휘 정면의 E/R 전체 배치 외곽과 A·B·C·E 중심 경계는 61/61로 한정 인수했다. 일반 개별 선체 외곽, 진형 전환·편성 확장은 남았다. **이전 격리·연결 계획:** 실제 좌표·지도/통로·최대 진형 외곽·서비스 반경·정면/우회/퇴로/진입 접근 검증. 산술 fixture·중심 슬롯 비교만으로 PASS 금지. 전용 격리 Godot 경로에서 정면·우회, 보급 영역 접근, 철수·증원 배치 및 실패 보존을 Windows 자동 렌더·헤드리스 각각 19/19(exit 0)로 확인했고 독립 검토가 한정 수용했다. 제품 진입·명령·표시·결산과 가동 보급·시간 증원·목표·철수 결과를 연결해 같은 반례를 재검증해야 한다. [결과](P05-PC-NATIVE-ACCESS-RESULT-20261109.md) · [독립 검토](REVIEW-P05-PC-NATIVE-ACCESS-RESULT-20261109.md). 천하지도 직접 출전 → FleetBattle3D → 천하지도 결산의 최소 연결은 계획 한정 수용됐다. 첫 조각은 P03의 fresh 작전 상태와 P05 공간 판정이며, 공유 파일 작업 순서와 제품 입력 동결 뒤 구현한다. [제품 연결 계획](P05-PC-PRODUCT-INTEGRATION-PLAN-20261109.md) · [독립 심사](REVIEW-P05-PC-PRODUCT-INTEGRATION-PLAN-20261109.md). |
| P06 | 미완료 | 원 A05/A06 종합 검증과 캠페인 연속작전 기능 | [I01 인수](I01-ACCEPTANCE-PREREG-20261026.md)와 [준비 판정](I01-READINESS-DECISION-20261026.md)의 원래 반례를 유지. 부분 시계·부분 상태 검사로 전체 PASS 금지 |
| P07 | 미완료 | 보급로·점령/가동·호송/통신소/재점령·철수·유한 정비의 제품 흐름 | 개발 v1의 정면 목표·우회 철수는 실제 Windows에서 완료했고 승인 정면 A04 및 직전 r5 전경 결산을 확인했다. 일반 확장과 실제 운영 자원 거래는 미완료다. **이전 구현 전 계획:** D01~D09 확정 방향을 실제 상태/사건/목표/자원·정보 경계와 결합하고 별도 제품 인수 검증. 미정 수치/전체 동일 틱 순서는 독립 계약 필요. 첫 PC 작전의 가동 보급·시간 증원·목표/철수 인수 기준 8개는 독립 계획 심사를 통과했다. 실제 정책·상태·PC 표시와 결산 연결 및 제품 실행은 미완료다. [계획](P07-PC-FIRST-OPERATION-PLAN-20261109.md) · [독립 심사](REVIEW-P07-PC-FIRST-OPERATION-PLAN-20261109.md). |
| P08 | 미완료 | Android export·실기기·대표 사람 플레이·성능/페이싱 | 개발 v1 실제 정면·우회와 승인 정면 복구 EXE 전경을 인수했다(§0). 새 EXE에서 재개 클릭 후 자연 종료 첫 관측까지 약 9분 42초였다. Android·실기기·대표 플레이와 페이싱 검증은 남았고 약 20분은 측정 가설이다. |
| P09 | 미완료 | 깨끗한 종료/TRACE 경고 해소 | flow replay 소유권 정리는 E 반영·회귀 통과. 오디오 장벽은 이전 playback 전체 수집 조건에서 차단(§0). **이전 진단:** 기존 ObjectDB/resources-in-use·flow/group TRACE log-open 경고와 전체 diff-check actual exit2의 기존 상위P2c행 CRLF 진단을 유지. 기능 PASS/exit0을 깨끗한 종료·전체 게이트 PASS로 확대하지 않음. 이번 문서 갱신에서 코드 수정·재검사하지 않음. 첫 PC 플레이와 저장·재개 이후 마지막 품질 단계에서 BGM 포함 종료 누수의 원인 확인·수정·검증을 수행한다. BGM 실제 재생 4/4의 격리 시험은 무누수였으나 과거 누수 실행과 정리 순서·참조 수명이 달라 원인과 제품 수정 효과는 미확정이다. [독립 마감](../../../tmp/p03-inchat-host-bgm/REVIEW-CLOSEOUT-6SOL.md) · [차이 분석](../../../tmp/p03-inchat-host-bgm/DIFFERENCE-ANALYSIS.md). |

## 7. 이 통합 문서의 작성·검토와 다음 순서

| ID | 상태 | 이번 문서 작업 | 인수 조건·다음 작업 |
|---|---|---|---|
| C01 | 완료 | 전체 사용자 요청/압축 인계·정본/최종 감사 교차대조, 요구 ID와 상태·근거·인수조건·다음 작업 작성 | 이 파일과 상위 탐색 링크1행만 작성. 코드/테스트 실행·Git ref/원격 변경 없음 |
| C02 | 완료 | 통합 체크리스트 독립 심사·최종 기록 | 독립 검토자가 누락·과장·근거·보완2건을 대조해 수용했고 문서 보존 감사를 완료했다. 상위 탐색 한 행 외 원문과 코드/Git 상태를 보존했다 |

현재 조율 순서와 인수 조건은 §0을 따른다. 개발 후보 v1의 첫 PC 플레이·같은 규칙 저장은 완료했고 현행 제품 인수는 일부 남았다. P01과 아래 제한 성과는 당시 완료 이력이다.

## 8. 2026-11-04 확인된 후속 성과 — 기존 ID/전체 미완료 경계 유지

| 한정 성과 | 기능·독립5b 근거 | 별도 독립 closeout 확인 |
|---|---|---|
| P2c 제한 fresh private runtime | [결과](I01B-P2C-RESULT-20261101.md) · [독립 리뷰](REVIEW-I01B-P2C-20261101.md): 정본 attempt5 actual exit0, 70사례/11553체크/45거부. 오염 cache의 attempt2/3는 정본 성공 증거에서 제외 | [2026-11-02 closeout](../../../tmp/i01b-p2c-20261101/REVIEW-CLOSEOUT-20261102.md): 당시 ZIP254/manifest253 전량 대조·CRC/SHA 일치, baseline3660/source35/격리77 확인 |
| 같은 원입력의 활성 owner 내부 runtime 교체 | [결과](I01B-ACTIVE-REPLACE-RESULT-20261104.md) · [독립 리뷰](REVIEW-I01B-ACTIVE-REPLACE-20261104.md): attempt2 actual exit0, 정상20/20099체크/명명8·거부호출9. P2c/core/data3회귀 exit0, 기존 data 종료 진단 유지 | [2026-11-04 closeout](../../../tmp/i01b-active-replace-20261102/REVIEW-CLOSEOUT-20261104.md): 당시 ZIP105/manifest104·내부 P2c254 CRC/SHA/크기/목록/디스크 일치, baseline3879/source35/입력42/격리77 확인. 전체 diff-check actual exit2 기존진단 보존 |

각 ZIP/manifest와 독립 closeout은 해당 마감 시점의 증거다. 이후 이번 체크리스트 갱신을 압축본 안에 소급 포함했다고 주장하지 않고 두 압축본을 다시 쓰지 않는다. 이번 MD4개 변경 전 SHA/원문 사본·diff·문서5a·보존 감사는 `tmp/i01b-checklist-confirmed-20261104/`에 별도 기록한다. 위 상태 갱신은 전체 I01/I01b/A04~A06 NOT_READY 및 외부 save schema UNCLASSIFIED를 바꾸지 않는다.

## 9. 2026-11-07 P02 첫 실제 headless 연결 — 전체 미완료 유지

공통 runtime-ready 입력 검증·한 번 정규화·private factory와 실제 autoresolve CLI --operation-input 경로만 구현했다. [결과](P02-FIRST-HEADLESS-RESULT-20261107.md) · 비-Astra 독립 5b 재심사 수용 보류 · [전용 체크리스트](P02-FIRST-HEADLESS-CHECKLIST-20261107.md) · [최신 인계](SESSION-HANDOFF-P02-FIRST-HEADLESS-20261107.md).

정본 attempt3/K6 actual exit0·정상8/13417체크·정책9·timeout2·API거부32, 실제 CLI거부14/성공2/legacy1쌍(18프로세스), private/core 회귀 exit0. 전체 명명거부46과 새 단계3/K6를 과거 P2c5/활성교체2와 구분한다. 실패 attempt1/2는 그대로 보존했다. 옵션 --no-chain/--no-m9/--wind는 conflicting_option 대신 unknown_option으로 거부되는 비차단 편차이며, services CLI의 supply 완료 사건 E2E는 미검증이다.

기존3960/source35/격리77·cache·HTML·과거ZIP2 보존과 상위 허용 hunk, 새 ZIP의 분모/CRC/SHA는 [최종 감사](../../../tmp/p02-first-integration-20261105/closeout-correction/audit.json)·[압축 검증](../../../tmp/p02-first-integration-20261105/closeout-correction/archive-verification.json)을 따른다. 비-Astra 독립 마감 판정은 보류 중이며 과거 ZIP/심사전235항 manifest에 최신 문서를 소급 포함하지 않는다.

P02 행과 P03~P09는 미완료다. 전체 I01/I01b/A04~A06 NOT_READY, 외부 save schema UNCLASSIFIED 및 기존 종료진단·전체 diff-check의 기존 P2c 33행 미통과를 기록한다. 이번 한정 코드/실행과 §7~8의 이전 문서 갱신·마감 이력을 구분한다.
