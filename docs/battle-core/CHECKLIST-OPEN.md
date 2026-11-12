# 더 파악해야 할 것 (컨셉 세션 체크리스트)

## K6 정식 검증 재개 — 2026-11-12

사용자가 K6 정식 검증과 필요한 마우스·키보드 사용을 승인했다. GitHub main `5ef3537b`를 기준으로 EntryBoot부터 GUI 15·16행의 경로와 입력 증거, 17·18행의 입력과 판정 기준을 21행·58작업·27비교 실행 계획에 다시 결속한다. 새 실행 입력의 동결과 독립 리뷰가 남았다.

**5ef3537b 집중 검증 — 2026-11-12.** 격리 입력 3종의 임포트가 통과했고, 별도 모델이 실행 5건의 증거·로그 해시와 경로 코드를 독립 검토했다. 공개 적벽 버튼은 EntryBoot와 승인 첫 작전으로 연결됐다(10/10). 구형 카드 준비를 합성한 격리 실행은 17행 완료 전후 각각 16/16, 18행 취소 전후 각각 24/24였다. 17행은 양쪽 11,350틱·1,134,950ms·연합군 승리이며 같은 오답을 양쪽에 넣은 반례를 거부했다. 공개 경로 변경으로 현재 main의 기존 정식 15~18행을 같은 조건에서 실행할 수 없다. 정식 실행기와 실제 Windows 입력은 이 검증에 포함되지 않았다. [집중 검증](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/K6/main-5ef3537b-successor-01/FOCUSED-MAIN-RESULTS.json)

**현행 main K6 경로 검토 — 2026-11-12.** `5ef3537b`의 공개 항로도에서 타이틀로 돌아간 뒤 구형 출격 준비로 진입하면 직접 배치·Space 일시정지·재시작을 확인할 수 있다. 이 경로는 재시작 시 시드를 다시 뽑고 타이틀을 거쳐 지도로 복귀하므로, 기존 16행의 고정 시드와 직접 지도 복귀 조건은 남았다. 승인 첫 작전은 EntryBoot를 통해 별도 호스트에서 시작한다. 구형 자동해결 완료·취소(17·18행)의 공개 진입이 막혀 있어 현행 집중 검증은 격리 시험 결과로 유지한다. 공개 경로의 실제 입력 결과는 아래에 기록했다. 현행 제품 경로에 맞춘 정식 판정 기준은 독립 검토를 거쳐 동결해야 한다. [현행 검증 계획](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/K6/main-5ef3537b-successor-01/PLAN.md)

**현행 main 타이틀 경로 집중 검증.** `5ef3537b`의 기존 저장 사본을 사용하는 새 헤드리스 프로세스에서 EntryBoot → 항로도 → 타이틀 → 구형 브리핑에 진입했다. 합성 viewport 입력으로 0틱 배치 명령 1회, Space 일시정지 두 번, 재시작의 새 시뮬레이션·다른 시드, 타이틀 경유 지도 복귀를 검증했다. 40/40 통과, 종료 코드 0, 저장 SHA 유지다. 정식 K6의 실제 Windows 입력 및 공개 AutoResolver 증거는 남았다. [집중 검증 결과](F:/WorkSpace/campaign-p03-20261111/tmp/k6-title-route-5ef3537b/RESULT.json)

**현행 main 타이틀 경로 Windows 검증 — 1600×900.** 정확한 `5ef3537b`의 Godot DEBUG 실행에서 공개 항로도와 타이틀을 거쳐 브리핑에 진입했다. 실제 우클릭으로 0틱 배치 명령 1회를 기록했고, 실제 Space 일시정지 두 번, 새 시드의 재시작, 타이틀 경유 지도 복귀를 확인했다. 별도 모델이 전체 캡처 17건, 입력·엔진 기록, 저장 SHA 유지와 종료 코드 0을 대조했다. 기존 고정 시드·직접 지도 복귀 조건 및 공개 AutoResolver 경로는 남았다. [Windows 증거](F:/WorkSpace/campaign-p03-20261111/tmp/k6-title-route-5ef3537b/windows1600/RESULT.json)

**현행 main 승인 첫 작전 Windows 검증 — 1600×900.** 정확한 `5ef3537b`의 새 격리 프로필에서 공개 EntryBoot로 적벽을 준비했다. 시작 전 0틱 유지와 명령 버튼 비활성, 명시 시작과 실제 이동 반응을 확인했다. 결산 전에 항로도로 돌아와 공개 버튼으로 재진입하자 다시 0틱에서 시작했고, 두 차례 복귀에 결산 화면·슬롯·원장은 없었다. 별도 모델이 전체 캡처 14건, 실제 입력, 중간·최종 프로필과 종료 코드 0을 대조했다. 내부 명령 수와 구형 AutoResolver는 별도 검증 범위다. [Windows 증거](F:/WorkSpace/campaign-p03-20261111/tmp/k6-approved-product-5ef3537b/windows1600/RESULT.json)

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
- K6 재심 후보 인계(2026-11-11 18:02 KST): [REVIEW-MANIFEST](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/K6/k6-current-product-review-01/REVIEW-MANIFEST.json) SHA42b7190bb1728eb2e9557b3d9e44a20de2aac9746d8633c40db1ba589c913166 확인. 작성자 행17 현행 before/after 및 잘못된 승자/지문 거부, 행18 두 lane24단언, 행15/16 내부 합성입력 경로 확인 보고. 기존 독립 담당01a1be56에 재심 인계했으며 물리입력 인수·정식실행은 미완료다. 최종 체크리스트 바이트/실행기 결속과 Windows 입력75분 창 확인이 남으며 사용자에게 시간대를 문의했다.
- 현행 후보 독립 재심: [판정 보고서](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/K6/P02-42B7190-INDEPENDENT-REVIEW-20261111.md), SHA80eb39de2bb2818cd476bdaaaf6fd33dfd95263782167756f18d37d08b313948 확인. 1028의존성·21/58/27·현행 행17 oracle 및 행18 격리 결과 수용. 다만 양 lane을 동일11351틱으로 바꾼 반례를 비교기가 수용하므로 11350틱/1134950ms 직접 검사 보완을 기존 실행 담당이 진행 중이다. successor 실행기·최종 문서·GUI 실제 입력 결속에 대한 최소 재심과 입력 시간 확정이 남았다. 정식 실행 완료가 아니다.
- [ ] 독립 재심 통과 후 정식 실행. Windows 실제 조작 준비와 필요한 입력 시간을 확인한다. 실패 시 무단 반복하지 않고 결과·원인을 기록한다.
- 신규 진입 구현 01a1c9b9-6356-7953-bb0e-0c1697c15a96와 독립 검토 01a1c9ce-efd1-7db3-8c3e-3bd3ca470280는 R1 수정·재심 범위 (DONE), 단일 통합01a1c9dd-2cc7-7ce1-8bf1-241ca4eb5ad3는 (ING), P02·P03 기준선 회귀 01a1c9c0-1427-7e82-a1a4-071641f31d73는 담당 범위 (DONE). K6는 고정 F 사본을 사용하고 공통 연결부 동시 편집을 금지한다. 차단된 다중호스트 시험 재실행 금지와 부수 검사기 작업 범위 제한은 유지한다.


## P02·P03 Windows 릴리스 검증 — 2026-11-12

**P02 공개 항로도 리플레이 Windows 릴리스 — 2026-11-12.** `60b51f2e` 패키지의 1280×720 창에서 실제 마우스·키보드로 파일 선택기, 취소·재진입, 손상 JSON 오류와 지도 복귀를 확인했다. 승인된 2틱 기록은 종결까지 재생했고, 실제 호스트의 5,107틱 기록은 검증을 마쳐 재생 가능한 0틱 화면에 도달했다. 긴 기록의 종결은 별도 내장 PCK 탐침에서 확인했다. 보존된 캡처 20건 중 14건은 이미지 기록이 잘려 전체 화면 배치 인증은 남았다. 시험 파일 7/7 SHA 일치, 종료 코드 0, 엔진 오류·경고 0이다. [전경 증거](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/P02-windows-product-replay-20261112-60b51f2e/foreground-20261112-095153/FOREGROUND-RESULT.md)

**P03 공개 항로도 재개 Windows 릴리스 — 2026-11-12.** `b2ba73ff` 패키지의 실제 입력으로 저장한 103틱·10.3초를 새 프로세스가 일시정지 상태로 복원했고, 계속 진행한 뒤 117틱을 관측했다. 800×450에서 백업 전용 복원과 기본 슬롯 미생성을 확인했다. 손상 기본 슬롯은 오류를 표시하고 파일을 보존했으며, 격리 시험의 기본 슬롯을 복구한 뒤 같은 창에서 Enter로 재개했다. 네 프로세스 모두 종료 코드 0, 엔진 오류·경고 0이다. 대기 명령 적용은 이전 헤드리스 검증 범위다. [전경 증거](F:/WorkSpace/campaign-p03-atlas-resume-20261112/tmp/p03-windows-b2ba73ff/RESULTS.md)

**P02·P03 통합 Windows 릴리스 — 1600×900.** 사용자 지정 해상도에서 `b2ba73ff` 패키지의 공개 항로도에 리플레이·이어하기·적벽 진입 버튼이 모두 보였고, 전체 파일 선택기 화면을 확인했다. 처음 Escape가 선택기를 닫지 않아 창에 다시 포커스를 준 뒤 Escape로 취소했고 Enter로 다시 열었다. 손상 파일 오류와 지도 복귀, 승인 2틱 리플레이 종결, 저장 103틱 재개와 지도 복귀를 실제 입력으로 확인했다. 독립 검토에서 전체 창 캡처 14건과 조작 기록, 저장·시험 파일의 SHA, 프로세스 정상 종료를 확인했다. [통합 전경 결과](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/P02-P03-layout-b2ba73ff-20261112/RESULTS.md)

**P03 백업 전용 Windows 릴리스 — 1600×900.** 같은 패키지의 새 프로세스에서 실제 클릭 한 번으로 `.previous`만 있는 저장을 103틱·10.3초에 일시정지된 상태로 복원했다. 백업 SHA가 유지됐고 기본 슬롯은 생성되지 않았다. [백업 전용 결과](F:/WorkSpace/campaign-p03-atlas-resume-20261112/tmp/p03-windows-b2ba73ff/foreground-previous-1600/RESULT.json)

**P02·P03 GitHub main 반영 — 2026-11-12.** 독립 검토 후 `5ef3537b`에서 `b2ba73ff`로 fast-forward했다. 공개 항로도 리플레이와 이어하기가 들어간 커밋이며, 1600×900 통합 Windows 릴리스와 백업 전용 실기 검증에 사용한 정확한 소스다. GitHub main을 다시 읽어 커밋을 확인했다. [통합 커밋](https://github.com/namkunkim/SpaceBattleOfThreeKingdoms/commit/b2ba73ff5b3c18a7ab0885d00cebf0c25be7fed1)

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


## 현재 상태 요약 — 2026-11-11 KST

**사용자 우선순위: P02·P03 최우선.** 관련 채팅을 5분마다 점검하며 직접 필요한 승인 작업부터 조율한다. 사용자가 K6 정식 검증 재개를 승인했다. 현행 공개 적벽 진입에서 기존 정식 경로를 사용할 수 없어 재검증 기준을 점검 중이다.

- [x] 승인 적벽 v1: 첫 PC 플레이·같은 규칙 버전 저장/재개·결산 복구 검증 완료. 현행 전경 인수는 EXE `67f9cb20…` 한정이다.
- [x] P09 재생 객체 정리: `tests/battle_flow.gd` 한 파일 E 반영, 독립 검토 및 최소 flow 회귀 통과. SHA `afa999ba1e3d6bde19293999aab2f79034a30312b19ce11ea6fa604cda468826`. [반영 증거](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/I01/p09-rp-apply-01a1c966-20261111/RESULTS.md)
- [ ] P09 오디오 종료 보강. Godot 4.7.2 Dummy 스트림의 `battle_flow`·`group_formation` 테스트 종료 경로를 보강했다. 기존 TRACE 순서와 틱을 유지했고 두 테스트는 정상 종료했다. 참조를 의도적으로 유지한 대조군은 2,033ms에 종료 코드 1을 반환했다. 이번 기준선에서 간헐적 잔류가 재현되지 않아 제품 오디오 전반의 종료 인수는 남았다. [독립 검토 범위의 GitHub 변경](https://github.com/namkunkim/SpaceBattleOfThreeKingdoms/commit/bada6d92c091156fa2dce2c243c26b0716d706cb) · [검증 매니페스트](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/I01/p09-audio-fence-ab-20261112-01/REVIEW-MANIFEST.json)
- [ ] O07 운영 전환·외부 지급·전원 상실: 대상/슬롯 지문·전환 승인, 수신자/계약 및 시험 환경 조건이 남았다.
- [ ] 일반 I01/P03~P08: 공통 입력·운영 상태/커밋·공간/작전 정책·출시 대상 인수 조건이 남았다. 승인된 적벽 한 건의 완료를 전체 인수로 확대하지 않는다.
- [x] **`264f47b9` K6 정식 검증 통과.** 5차에서 21행·58작업·27비교와 최종 GUI 증거 승인을 완료했다.
- [ ] **`b2ba73ff` main 제품 경로 K6 정식 검증.** EntryBoot와 구형 공개 경로가 달라 현행 제품 경로의 판정 기준 동결이 남았다.
- [x] **신규 진입 Windows 후보 전경 시험.** EXE 2f353f27…에서 네 창 크기, 키보드·마우스, 전장 준비 0틱과 아니오 정상 종료를 확인했다. [전경 검증 기록](../entry/windows-foreground-verification-20261111-ko.md)
- [ ] **신규 진입 작은 창 가독성.** 480×270은 글자와 지도 라벨이 지나치게 작아 미수용. 800폭에서도 가독성이 저하된다. 최소 지원 크기 또는 화면 개선 결정이 남았다.

관련 검증·수정·검토 담당 채팅은 담당 범위 기준 `(DONE)`이다. 전체 P02/I01b는 **미완료**다. 두 우선 체크리스트 재대조 결과 현재 승인 범위에서 독립 착수 가능한 추가 필수 작업은 확인되지 않았다. [인수 부족·담당·필요 입력 대조](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/I01/p02-checklists-closeout-01a1c907-20261111.md)

아래 시각별 기록은 이력이며, 현재 상태는 두 우선 체크리스트와 위 조율 상태를 따른다.

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

갱신: 2026-10-09 (§8 본편 대조 리뷰 추가). 범위는 적벽 시나리오 하나다.
확인하면 `[x]`로 바꾸고, 결과가 문서에 들어간 곳을 적는다. 결정이 필요하면 `BATTLE_DECISIONS.md`에 Q번호로 남긴다.

**표시**
- **지금:** 컨셉 세션이 바로 확인할 수 있다.
- **UI-2:** UI-2 세션의 다음 병합을 기다린다.
- **구현:** M1 이후 구현 세션의 결과를 기다린다.
- **본편:** 본편(Seonghanji) 쪽의 답을 기다린다.

세션 요구사항 통합 추적: [완료·미완료·상시준수 체크리스트](pc-campaign-design/SESSION-REQUIREMENTS-CHECKLIST-20261031.md).

## PC 캠페인 후속 인수 현황 (2026-11-11)

**사용자 우선순위 변경 (2026-11-11):** 최우선 실행·인수 기준은 [P02 필수 작업](pc-campaign-design/P02-PROGRESS-CHECKLIST.md)과 [사용자 요구사항 통합](pc-campaign-design/SESSION-REQUIREMENTS-CHECKLIST-20261031.md)이다. 이 문서는 종합 증거 이력으로 유지한다. 2분 조율 자동화도 두 문서 우선으로 갱신했다.
- (DONE) 01a1c907-1cf5-7680-8dbc-4eb530ab3f99: 두 우선 문서의 11/11 증거 대조·갱신 완료. 다음 필수 작업은 진행 중인 결산 복구와 새 EXE 전경 인수 준비로 확정했다.
- (ING) 01a1c908-13c7-72a1-9123-acc63d325f5c: 결산 기록 직후 종료 시 다음 지도 결과 복구 후보 구현·검증. F 격리 작업, 독립 검토 전 E 미반영.
- 검사기 r2 6fd27664…는 독립 재심에서 무효 비교 분기·세미콜론 뒤 조기 반환의 두 새 반례로 미통과. E 미적용이며 추가 수정은 우선 두 문서의 필수 의존성 확인 전 보류한다. [재심 증거](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/I01/i01-data-rules-r5-hash-format-r2-review-01a1c841/RESULTS.md)
- (DONE) 01a1c838-6ef7-7dc0-ba62-06e476c74a98: 새 EXE 전경 인수 준비 완료. SHA·격리 프로필·클릭 순서·필요 시간을 F에 정리하며 실제 입력은 새 시간 확보 전 실행하지 않는다.
- K6 정식 실행은 계속 보류한다.

### 최신 조율 요약 (2026-11-11 14:06 KST)

- [x] E 반영: r5 저장·결산·메뉴 6파일과 승인 치수 2파일 설치 및 SHA 대조 완료. 기존 실행본·사용자 저장 보존.
- [x] 통합 배포 검증: F EXE d267012a…의 저장·재개·리플레이 8/8, O07 10/10·exit0. 외부 계측 검증이며 새 EXE의 Windows 전경 실제 조작 완료를 뜻하지 않는다.
- [x] 통합 배포 제한 독립 인수 (14:09 KST): 실제 EXE·DLL·내장 패키지·저장 SHA와 제품8/8·O07 10/10 로그를 대조해 수용했다. 담당 (DONE). 초기 접근 위반의 직접 원인은 미확정이며 최종 동일 EXE 실행에서는 재현되지 않았다. 전경 조작·전체 인수 완료는 아니다. [독립 인수 증거](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/I01/r5-dimensions-canonical-windows-review-01a1c8e0/RESULTS.md)
- [ ] 검사기 r2 독립 재심 미통과: 기존 반례·fixture66개는 통과했으나 추가 두 반례를 놓쳤다. 후보 SHA 6fd27664…는 F에만 있으며 E 미적용. 검토 담당 (DONE), 추가 수정은 우선순위 판단 전 보류. [수정 후보 증거](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/I01/i01-data-rules-r5-hash-format-r2-01a1c835/RESULTS.md)
- [ ] 현 E 정적 게이트: 구조23·제품15·exit1. 검사기 후보의 제품13은 미적용 결과이며 전체 I01 통과가 아니다. 잔여13은 시드/identity 설계3건과 교전·이동 규약10건.
- [ ] 남은 제품 조건: 결산 기록 직후 종료 시 결과 재표시 경로, 새 EXE 전경 조작, 독립 동시 게시 미검증 범위, O07 외부 지급 계약·실기기 전원 상실 검증. 기존 차단 실행은 반복하지 않는다.
- [ ] K6 정식 실행: 사용자 지시에 따라 계속 보류.

아래는 시점별 증거 이력이다. 이전 후보의 대기·실패 기록은 최신 완료 기록과 구분한다.

**현재 데이터 검사 상태 (13:45 KST):** r5 포함 기준 제품21건에서 승인 치수6건 제거 후 제품15건·구조23건, exit1이다. 제품15건에는 기존13건과 r5 해시 형식 리터럴9·64 진단2건이 포함된다. 이전13/19/42건 기록은 각 후보·시점의 이력이다.

- [x] **A06 저장 교체 중단 복구 E 반영.** 주 슬롯 부재 시 쓰기도 이전 복구본을 검증해 손상·지원 불가 복구본을 보존하며 거부한다. 설치본 30/30, 체크포인트 40/40, 제한 슬롯 19/19, 결산 18/18, 외부 저장 36/36, 파일 잠금 2/2 통과. [적용 증거](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/I01/a06-local-rotation-20261111-01/RESULTS.md)
- [x] **해시 형식 검사 보완 E 반영.** 공백·주석·줄바꿈을 허용하며 두 해시 위치만 구문으로 식별한다. 저장·리플레이 회귀 통과. 현행 전체 data_rules는 일반 수치 42건/7파일로 exit 1이다. 아래 이전 44건 및 정확 문장 후보 기록은 이전 상태다. [최종 검증](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/O07/i02-data-rules-hash-format-20261111-01/RESULTS.md)
- [x] **A06 수정 후 배포 검증.** 새 Windows 릴리스 SHA 73d14a66…에서 A06 11/11, O07 10/10 모두 exit 0. 이전 82453917… 결산 저장을 복원했고 손상·지원 불가 복구본은 기본·native 게시 양쪽에서 보존하며 거부했다. DLL과 O07·리플레이 지문은 동일하다. [배포 증거](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/O07/a06-canonical-windows-01a1c7c7/RESULTS.md)
- [x] **A06 ST01~18 대조와 사건 참조 검증 E 반영.** 필드·ID 참조표를 작성하고 제한 슬롯의 미해결 함대 참조·잘못된 진영 참조를 라이브 교체 전에 거부하도록 수정했다. E 체크포인트 38/38, 호스트 19/19, 이전 정상 슬롯 새 프로세스 재개 6/6·exit 0. [증거](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/I01/a06-st-reference-20261111-01/RESULTS.md)
- [x] **A06 사건 참조 배포 검증.** 새 EXE SHA 9ba2609d…에서 제한 슬롯 10/10 및 O07 10/10·exit 0. 이전 EXE의 정상 저장을 재개했고 잘못된 사건 참조 네 건을 거부하며 활성 전투·슬롯 바이트와 다음 틱 결과를 보존했다. DLL 및 기존 O07·리플레이 지문 일치. [새 배포 증거](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/O07/a06-st-reference-canonical-windows-01a1c7c7/RESULTS.md)
- [x] **적벽 v1 승인 저장 경계 대조.** 증원·철수 명령 대기·보급 전후·탈출 후 다섯 저장의 기록 23/23, 새 프로세스 복원 61/61·exit 0. 사건 순서·결산 ID와 보급 1회 지급, 파일 SHA 보존을 확인했다. 구버전 보존 실행본 재개와 현행의 다른 규칙 거부를 확인했다. [증거](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/I01/a06-approved-front-20261111-01/RESULTS.md)
- [ ] **적벽 v1 배포 진행 저장 연결.** EXE 9ba2609d…의 진행 체크포인트 캡처가 checkpoint_rules_unavailable을 반환했다. 제품 저장 버튼·지도 재개 연결도 남았다. 승인된 동일 규칙 저장 재개 목표의 구현 공백으로 후속 수정한다. 09:43 KST 현재 F 후보 네 파일의 버튼 시험 28/28은 구현 채팅 보고이며 패키지·새 프로세스 검증은 진행 중이다. 독립 검토 채팅 01a1c80f-3fad-75c3-8e7f-707c869736b0을 배정했다. 후보 SHA·검증 원문·독립 판정 확인 전 인수 및 E 반영 완료로 표시하지 않는다.
- [ ] **제품 저장 후보 배포 검증·독립 재심 진행 (09:49 KST).** F 후보 EXE 82be5efe… 보고서에서 버튼 신호 저장 28/28, 새 프로세스 지도 재개 12/12, 소스 저장 열기 12/12, O07 10/10과 공유 회귀 통과를 확인했다. Windows 전경 클릭은 아니다. 변경 원천 지문 b67d9dff…의 구버전 거부·기존 실행본 보존을 기록했다. 09:51 KST 구현·독립 검토 양쪽에서 결산 후 같은 1,802틱 진행 슬롯을 재개하면 동일 결산 ID가 다시 표시되는 문제를 소스와 Windows EXE에서 재현했다. 현재 후보는 이 결함으로 독립 검토 미통과다. 1차 검토 채팅은 담당 검토 마감으로 (DONE) 처리했으며 제품 인수 완료를 뜻하지 않는다. [독립 재현·SHA 증거](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/I01/a06-product-local-review-20261111-01/RESULTS.md) 09:55 KST 수정 후보 다섯 파일이 고정됐다. 소스 결산 23/23·새 프로세스 12/12 보고를 확인하고 기존 검토 채팅을 (ING)으로 재개해 영속 중복 방지 재심을 배정했다. 09:59 KST 최종 EXE b053d3dc…의 실제 SHA와 16개 실행 종료 코드 0을 대조했다. 후보 보고상 EXE 결산 23/23·새 프로세스 완료 ID 거부 12/12·O07 10/10이며 독립 재심에 최종 EXE 증거를 전달했다. 10:01 KST 독립 재심에서 기존 결산 후 재개 차단은 확인했으나, 같은 저장을 미리 연 두 프로세스의 순차 지도 복귀 시 두 번째도 이미 기록된 결산을 표시하는 결함을 소스·최종 EXE에서 재현했다. 2차 독립 판정은 first_operation_host.gd의 applied=false 미처리에 따른 미통과다. [2차 재심 증거](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/I01/a06-product-terminal-review-20261111-01/RESULTS.md) F에서 최초 기록 전장의 게시 권한과 지도 전환 재시도를 수정 중이며, 10:07 KST 독립 검토에서 동시 consume의 잠금·단일 적용을 확인했다. host 491d6c14… 수정 후보는 두 프로세스 게시 시험 각 11/11, 동시 기록 6쌍 단일 적용을 보고했으며 같은 검토 채팅에 재심을 이어 배정했다. 10:11 KST 독립 재심 턴이 사이버 위험 탐지 systemError로 중단돼, 차단 실행 반복 없이 기존 코드·로그·SHA의 읽기 전용 검토로 후속 범위를 제한했다. 미완료 재현은 통과로 처리하지 않는다. 구현 채팅은 10:17 KST r4 후보 증거 정리를 마감해 (DONE) 처리했다. E 반영을 뜻하지 않는다. [게시 수정 후보](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/I01/a06-product-local-20261111-01/PUBLISH-ONCE-CANDIDATE.md) E 미반영·최종 인수 미완료다. [수정 후보 SHA·검증](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/I01/a06-product-local-20261111-01/FINAL-CANDIDATE.md) [후보 보고서](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/I01/a06-product-local-20261111-01/RESULTS.md)
- [ ] **r4 독립 증거 검토 마감 (10:15 KST).** EXE 562c8040…에서 최초 호스트 지도 실패 후 재시도와 완료 ID 주 슬롯·백업 거부는 독립 확인했다. 두 번째 호스트의 결과 없는 복귀는 구현 측 소스·EXE 각 11/11이나 독립 탐침의 신호 경로 불일치로 시간 초과되어 독립 재현 미완료다. 위험 탐지 중단 이후 새 실행 없이 기존 증거만 검토했다. 검토 채팅은 담당 범위 마감으로 (DONE); 제품 인수와 E 반영은 보류한다. r4 비계측 기본 시작은 이후 10:35 KST Windows 실제 UI에서 확인했다. 캠페인 진입은 아래 연결 공백으로 미검증이다. [r4 완료·미완료 증거](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/I01/a06-product-local-20261111-01/PUBLISH-ONCE-CANDIDATE.md)
- [x] **I01 잔여 데이터 검사 적용 범위 검토.** 42건/7파일의 실제 행·값·승인 키를 대조했다. 구조23건 분리와 승인 치수 참조6건은 구현 가능하며 나머지13건은 시드/identity 설계3건 및 교전·이동 규약10건이다. 13건은 적용 후 산술 예상으로 현재 게이트는 여전히 exit 1이다. 검토 채팅은 (DONE). [항목별 근거](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/I01/i01-data-rules-residual-20261111-01/RESULTS.md)
- [ ] **I01 구조 진단 분리 구현 (10:25 KST).** 새 (ING) 채팅 01a1c835-e0af-7610-9ea6-50b2896b0d53에 검사기 한정 후보와 정적 fixture 검증을 배정했다. 제품 수치19건을 남기고 구조23건만 정확히 분류한다. 제품 코드·저장·r4 및 K6 실행은 범위 밖이다. 10:39 KST 후보 구현은 마감됐으며 Python 정적 재생37fixture 통과·잔여19건·exit1을 보고했다. 10:47 KST 독립 Godot 검사에서 기준42·구조23·잔여19 및 제공37fixture를 재현했지만 MAX_TICKS 값 변경을 놓치는 추가 반례 두 건(백슬래시 줄 연결 +1, 이스케이프 삼중 문자열 속 선언 오인)으로 적용 보류했다. [독립 Godot 반례 증거](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/I01/i01-data-rules-structure-review-01a1c841/RESULTS.md) 검토 채팅은 이 판정 범위 (DONE)이며 수정 후보 재심 시 재개한다. 10:53 KST r2 후보 e0021416…의 두 반례 수정과 Godot44/44 보고를 받아 기존 독립 검토 채팅을 (ING)으로 재개했다. 구조23·제품19·exit1은 유지되며 E 미반영이다. [r2 증거](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/I01/i01-data-rules-structure-r2-01a1c835/RESULTS.md) [후보 증거](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/I01/i01-data-rules-structure-01a1c835/RESULTS.md)
- [ ] **r4 Windows 실제 UI 검증 배정 (10:28 KST).** 사용자 두 시간 입력 사용 승인에 따라 새 (ING) 채팅 01a1c838-6ef7-7dc0-ba62-06e476c74a98를 단독 전경 입력 담당으로 배정했다. 12:27 KST까지 F 격리 프로필의 r4 비계측 시작·실제 저장/재개 버튼·정상 결산 지도 복귀를 확인한다. 차단된 계측 재현은 반복하지 않으며 K6 정식 실행은 보류한다.
- [ ] **배포 기본 메뉴 캠페인 진입 공백 (10:35 KST).** 실제 UI에서 기본 출격 준비는 기존 전투 브리핑으로 연결되며 제품 지도 진입을 찾지 못했다. 같은 EXE의 장면 경로 재지정도 엔진 미지원으로 실패했다. 새 (ING) 채팅 01a1c83e-7e08-7f41-b8e6-b52005e66e3e에 정상 메뉴→기존 캠페인 지도 연결 후보를 배정했다. r5 EXE 5f53225d… 빌드·지문 검증과 소스1,882개 대조가 완료됐다. 10:47 KST 기존 UI 담당 채팅을 (ING)으로 재개해 정상 메뉴 실제 클릭 검증을 인계했다. 기존 r4·사용자 저장 보존, E 미반영, 입력 사용은 12:27 KST까지다. [r5 인계 증거](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/I01/a06-campaign-menu-20261111-01/RESULTS.md)
- [x] **r4 비계측 기본 시작 실기 확인.** F 격리 프로필에서 SHA 일치 EXE를 인수 없이 실행해 기본 메뉴·기존 전투 HUD를 실제 입력으로 확인했다. 담당 채팅은 이 범위 (DONE)이며 I01 저장·재개·결산 지도 복귀 완료를 뜻하지 않는다. 수정 메뉴 EXE가 준비되면 같은 채팅에서 후속한다. [실제 UI 증거](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/I01/a06-r4-normal-ui-20261111-01/RESULTS.md)
- [x] **r5 Windows 실제 저장·재개·철수 결산·지도 복귀.** 10:47–10:56 KST 실제 버튼으로 지도/타이틀 왕복, 정면 출격, Tick70 저장·동일 프로세스 복원·새 프로세스 재개를 확인했다. Tick2949 철수 성공 후 지도에 같은 결과가 표시됐고 원장1건·진행 슬롯SHA 보존을 대조했다. 기존 출격 준비→서막→브리핑도 확인했다. C 점령 승리나 다중 프로세스 독립 시험의 완료를 뜻하지 않는다. UI 담당 범위 (DONE), E 통합은 별도 대기. [실제 입력·캡처·원장 증거](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/I01/a06-r5-normal-ui-20261111-01/RESULTS.md)
- [x] **검사기 r2 독립 통과·E 적용 완료.** tests/data_rules.gd 한 파일의 설치 SHA e002141623c9e72a2291164855fd95559e2987687cad7528d6164d3bb8f75fc0를 오케스트레이터가 대조했다. 이전 파일 F 보존, 설치본 Godot 파싱 exit0, 구조23·제품 수치19·구조/해시 오류0의 정적 게이트 exit1을 확인했다. 구현·독립 검토 담당 범위는 (DONE). 전체 I01 게이트 통과는 아니다. [설치 증거](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/I01/i01-data-rules-structure-r2-applied-01a1c835/RESULTS.md)
- [x] **r5 정면 C 점령 실제 UI 검증.** 표준·직접 지휘로 A 활성화→C 진군 후 Tick6170에 C:ally와 objective_success를 확인했다. 실제 Return to map으로 목표 달성 지도 결산·천하 개요 복귀, 화면과 동일한 원장1건을 대조했다. UI 담당은 (DONE). F 후보 검증이며 E 반영은 별도 대기. [캡처·실행·원장 증거](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/I01/a06-r5-c-objective-ui-20261111-01/RESULTS.md)
- [ ] **r5 E 통합 범위 독립 검토 (11:17 KST).** 새 (ING) 채팅 01a1c864-cd74-7fc3-ab47-9208ef4e4ab0에 저장·결산·메뉴 후보와 실제 UI 증거의 읽기 전용 종합 검토를 배정했다. 정확한 최소 적용 파일·SHA·잔여 검증 조건을 확인하며 차단된 다중 프로세스 시험은 반복하지 않는다. 사용량 제한으로 중단된 뒤 사용자 재개 지시에 따라 같은 채팅에서 읽기 전용 독립 검토를 재개했다. 기존 Windows 입력 허용12:27 KST는 종료됐으며 추가 실제 조작은 하지 않는다.
- [ ] **I01 승인 치수 중복6건 후보 재개.** 새 (ING) 채팅 01a1c8da-6867-7813-a7a6-e56b70579b3e에 기존 승인 space.size 참조를 이용한 최소 F 후보·동작 보존 검증을 배정했다. r5 통합 검토와 별도 후보로 유지하며 E 소스·규칙값·사용자 저장은 변경하지 않는다. 구버전 보존 정책을 적용하고 Windows 입력·K6 실행은 하지 않는다. F 후보 검증은 제품19→13·구조23·exit1, fresh100/100·정책39/39로 마감됐다. 후보2파일은 r5와 직접 중복하지 않는다. 새 독립 검토를 배정했으며 E 적용과 새 배포 지문·구버전 호환 검증은 남았다. [치수 후보 증거](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/I01/i01-data-rules-dimensions-01a1c8da-r2/RESULTS.md)
- [x] **r5 제한 통합 독립 검토 완료.** 현행 E 대상6파일 기준SHA 일치, r5 실제 UI·원장 증거 대조를 마쳤으며 제한 통합 가능 판정이다. 전체 인수는 미완료: 원장 기록 직후 종료시 결과 재표시 경로, 두번째호스트 독립 재현, 설치·배포 확인이 남는다. [독립 판정](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/I01/a06-r5-integration-review-20261111-01a1c864/RESULTS.md)
- [x] **I01 승인 치수6건 독립 검토 통과 (13:39 KST).** 기준·후보 fresh125/125·정책48/48, 치수 정규화·effective_digest·오류 우선순위 일치를 확인했다. 정책 직접 Vector2 호출 오류는 양쪽 기존 한계이며 정상 경로는 정수 배열이다. 검토 담당 (DONE). 기존 구현 채팅을 (ING)으로 재개해 검토된2파일의 E 기준SHA 확인·F 백업·설치 및 통합 검증을 배정했다. E 적용 완료와 배포 인수를 뜻하지 않는다. 새 패키지 저장/리플레이 성공 및 구버전 지문 거부·슬롯/원장 보존 검증은 후속이다. [독립 검토 증거](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/I01/i01-data-rules-dimensions-review-01a1c8e0/RESULTS.md)
- [x] **I01 승인 치수2파일 E 적용·통합 검증 완료 (13:45 KST).** F 원본 보존과 설치SHA2/2를 오케스트레이터가 재확인했다. r5 포함 전후 제품21→15건·구조23·exit1, fresh76/76·정책37/37 통과. 구현 담당 (DONE). 기존 배포 검증 채팅을 (ING)으로 재개해 F 통합 빌드·새 저장/리플레이·구버전 지문 거부 검증을 배정했다. K6 정식·전경 입력은 보류한다. [설치 및 통합 증거](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/I01/i01-data-rules-dimensions-e-applied-01a1c8da/RESULTS.md)
- [ ] **I01 r5 해시 형식 진단2건 후속 (13:47 KST).** 기존 검사기 채팅 01a1c835-e0af-7610-9ea6-50b2896b0d53을 (ING)으로 재개했다. 체크포인트의 version.hash.left(9)·digest.length()!=64를 기존 정확 구문 분류 원칙에 따라 검토하고 F 한정 후보·변조 반례 검증을 수행한다. 배포 빌드와 충돌하지 않도록 E 변경은 금지하며 독립 재심 후 반영한다. 13:53 KST F 후보 9f19c483…의 Godot fixture58/58·구조23/해시형식4/제품13·exit1 보고를 확인했다. 구현 담당 범위 (DONE), 기존 독립 검토 채팅 01a1c841-faa9-7421-a05a-b432c78f0bd2를 (ING)으로 재개했다. E는 기존 검사기를 유지한다. [후보 증거](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/I01/i01-data-rules-r5-hash-format-01a1c835/RESULTS.md)
- [ ] **I01 해시 검사기 후보 재심 반례 발견 (13:57 KST).** 독립 검토에서 기존58fixture는 통과했지만 정상 해시 구문을 미호출 람다·비실행 분기에 두고 실제 폭을1로 변조한 두 파싱 가능 반례를 놓쳤다. 후보 E 적용은 보류하며 기존 구현 채팅을 (ING)으로 재개해 F 수정·회귀를 배정했다. 13:59 KST 독립 미통과 판정이 마감됐고 검토 담당은 (DONE)이다. 실제 게이트는 exit1을 유지했으나 해시 변조 오류가 누락됐다. 수정 후보 재심이 남았다. [독립 반례 증거](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/I01/i01-data-rules-r5-hash-format-review-01a1c841/RESULTS.md)
- [ ] **통합 배포 동적 검증 진행 (13:59 KST).** 담당 채팅은 직전/새 EXE의 b67d9dff→b7189ae8 지문 변경 및 구버전 슬롯 거부·활성 전투/파일 보존을 보고했다. 정상 지도 재개는 양 EXE의 headless 접근 위반으로 아직 미통과이며 씬 전환 대기 탐침을 확인 중이다. 최종 증거와 제품/탐침 원인 분리 전 완료로 표시하지 않는다.
- [x] **r5·승인 치수 통합 배포 매트릭스 완료 (14:01 KST).** F EXE d267012a…에서 제품 저장/새 프로세스 재개/리플레이8/8 및 O07 10/10·exit0 보고서와 검증 범위를 확인했다. 구버전3종 지문 거부 및 활성 전투·입력/주슬롯/백업/원장 보존을 확인했다. 초기 접근 위반은 탐침의 씬 전환 대기 수정 후 같은 EXE에서 재현되지 않았다. 전경 클릭이 아닌 외부 override·버튼 신호 계측이며 재생/외부 가져오기는 개발 메뉴다. 배포 담당 (DONE), 기존 치수 독립 검토 채팅을 (ING)으로 재개해 실파일·로그·비교 논리의 읽기 전용 인수를 배정했다. 전경 새 EXE·결과 기록 직후 종료 복구·차단된 동시 게시·실제 지급·전체 인수는 미완료다. [통합 배포 증거](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/I01/r5-dimensions-canonical-windows-01a1c7c7/RESULTS.md)
- [x] **r5 E 작업본6파일 제한 통합 완료.** 적용 전 기준6/6·설치 후보6/6 일치, F 원본 보존, 오케스트레이터 실파일SHA6/6 재대조를 마쳤다. E/F 공통322파일 중 검사기만 별도 선행 변경이며 r5 지문 원천과 DLL은 일치한다. 담당 (DONE). E 재빌드·실행과 전체 인수는 아직 미완료다. [설치·백업·diff 증거](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/I01/a06-r5-e-integration-20261111-01/RESULTS.md)
- [ ] **A06 일반 인수 후속.** 일반 배포 저장 지원·이전 범위, 전역 커밋과 안정 ID·효과 수명, 운영 지급 수신 계약의 결정이 남는다. 실제 Windows 전경 클릭과 전원 상실은 미검증이며 K6 정식 실행은 보류한다.


- [x] **I01 적벽 v1 제한 인수.** 승인 정의로 직접 출격·자동 결산, 공통 초기 상태와 11,999틱 저장·복원을 검증했다. 지도 종료 시 Godot 참조 순환 정리와 Windows debug 지문 빌더를 E 작업본에 반영했다.
- [x] **I01 적벽 v1 A04 승인 범위.** Windows headless에서 실제 정면 배치·보급·철수와 E/R 내부 배치 가드 및 A·B·C·E 중심 경계 정책을 합쳐 61/61·exit 0. A 보급 탄약 +14, R 진입 125,100ms, E 탈출 후 180,300ms 철수 성공을 확인했다. 정면 C 목표는 5,487틱에 달성했고 미승인 우회 요청과 변조 정의는 거부됐다. [검증 보고서](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/I01/a04-er-center-20261111-01/RESULTS.md)
- [x] **I01 지도 결산 표시 E 작업본 반영.** 독립 검증에서 기준 8/9, 수정·설치본 각 9/9. 두 파일의 기준·후보·설치 SHA를 대조하고 복원 원본을 보존했다. 설치 바이트로 A04 61/61, 체크포인트 40/40, 리플레이 지도 19/19, 저장 호스트, 자동 지도 두 경로와 O07 결산 표시를 통과했다. 동일 철수 재생 출력 SHA를 확인했다. [적용 기록](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/I01/a04-map-settlement-integration-20261111-01/apply-verification.json)
- [x] **I01 적벽 v1 정면 추종·선회 계측.** A 경유 제품 owner 17/17·exit 0, 5,487틱 C 목표, 최대 중심 추종 편차 0, 승인 팽창 원판 최소 통로 여유 2.151752. 제품 진형 전환 명령은 거부됐으며, 일반 전투 코어에서는 발사 앵커 전환 경계 0·49·50틱 3/3을 확인했다. [계측 보고서](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/I01/a04-live-hull-20261111-01/RESULTS.md)
- [ ] **I01/K01~08 일반 제품 인수.** 실제 개별 선체 외곽 판정에는 함종별 논리 외곽, 전체 개별 배치점, 전환 중 위치·방향 및 틱 사이 외곽 계산 규약이 필요하다. 추가 편성·일반 정의, 교전·이동 규약, A06 운영 저장이 남았다. 현행 data_rules는 구조 진단 r2가 E에 적용돼 제품 수치19건·구조23건으로 구분되며 exit1이다. 42건/7파일은 구조 분리 이전 기록이다. 이전 정확 문장 후보의 한계는 공백·주석·줄바꿈을 허용하는 구문 검사로 보완했고 정상·변조 및 저장·리플레이 회귀를 확인했다. [해시 형식 검증](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/O07/i01-data-rules-hash-20261111-01/RESULTS.md) [데이터 검사 원문](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/I01/a04-er-center-20261111-01/data-rules-classified/engine.log)
- [x] **O07 로컬 복구 제한 인수.** 배포 EXE 호스트 진입과 결산 지도 복귀를 격리 검증했다. 로컬 게시 경계 강제 종료 복구 6/6, 배포 DLL의 동일 ID 재시도 2/2가 통과했다.
- [x] **O07 결산 저장·재개 경계.** 현행 E 소스 격리본과 배포용 Win32 DLL의 Windows headless 4/4·exit 0. 정상 슬롯은 호스트와 지도에서 같은 결산 ID·세대 2·영수증 1건으로 재개했고 재결산은 거부됐다. 영수증 다이제스트 또는 결산 키 불일치 두 건을 두 경로에서 거부했으며 주 슬롯과 조회 전용 백업을 보존했다. [검증 보고서](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/O07/o07-terminal-receipt-authority-01a1c7a8/RESULTS.md)
- [x] **O07 Windows 배포 EXE 결산 슬롯 검증.** 기존 릴리스 SHA a9dda414…에서 비계측 호스트 시작 3/3, 동일 바이트 EXE 외부 계측 7/7. 정상 슬롯은 같은 ID·2틱·세대 2·영수증 1건으로 호스트와 지도에서 복원했고, 불일치 두 건은 양쪽에서 거부됐다. 9개 대조 프로필의 주 슬롯·백업 바이트가 동일했고 최종 10개 프로세스가 exit 0이었다. 호스트 재개·지도 복귀는 제품 버튼 신호로 검증했다. [배포 검증 보고서](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/O07/o07-windows-terminal-receipt-01a1c7bb/RESULTS.md)
- [x] **최신 E 기준 Windows 릴리스·O07 회귀.** I01 결산 표시 두 파일이 들어간 새 F 릴리스 SHA 82453917…에서 비계측 3건·외부 계측 7건, 합계 10/10·exit 0. 별도 기본 시작 통과, 9개 대조 프로필 슬롯 바이트 보존. 직전 릴리스와 DLL 및 O07·리플레이 지문이 일치한다. 내보내기 두 로그에 하위 프로젝트 생략 경고가 각각 한 건 있었고 최종 런타임 진단은 0건이었다. [새 릴리스 검증](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/O07/i01-labels-canonical-windows-01a1c7c7/RESULTS.md)
- [ ] **O07 운영 외부 지급 및 실기기 확인.** 실제 수신자·연동 설정, 동일 ID의 영속적 중복 제거 및 다른 효과 충돌 계약, 승인된 시험 환경이 필요하다. 현재 호출은 `external_payment_contract_missing`을 반환한다. 새 비계측 EXE의 전경 재개 클릭과 실제 전원 상실은 미검증이다.
- [x] **K6 I01 지도 변경 비실행 재기준.** F 격리 사본 세 lane에서 I01 두 파일을 모의 적용·복원했고, 14·17행 지도 overlay 다섯 건의 Git 정·역적용 SHA를 대조했다. 기존 lane 인벤토리 10,657개와 의존성 1,006개는 일치했다. 전체 체크리스트도 입력 목록에 있으므로 후속 정식 동결 시 당시 바이트를 결속한다. [재기준 기록](F:/WorkSpace/SpaceBattleOfThreeKingdoms-validation/K6/i01-a04-k6-input-rebase-review-20261111-cd718c9e5a40/REBASE-READBACK.json)
- [ ] **K6 정식 인수.** 현행 18행의 before/after 헤드리스가 각각 24/24로 독립 통과했다. 17행은 이전 격리 시험에서 현행 이동장으로 11,350틱·연합군 승리, 역사 이동장으로 10,550틱·조조군 승리를 재현했다. 현행 기대값을 새 기준에 결속하고 15·16행 실제 입력 검증, 독립 리뷰, 정식 실행 및 본선 반영을 진행한다.

[후속 검증표와 독립 증거](../../tmp/p03-k6-review-20261109/REVIEW-13-COORDINATION-CHECKLIST.md)

## 추가 검토: PC 맵·캠페인 연계 (2026-10-25)

사용자가 새 캠페인 제안과 PC 맵 확장 세션의 연계 검토를 요청한 별도 확장 항목이다. 아래 설계 권고는 기존 적벽 정본의 확정 변경이 아니다.

- [x] PC 실험 결과와 지형 구현 범위를 확인하고 캠페인과의 결합 문제를 검토했다. [통합 세부 검토](PC-CAMPAIGN-INTEGRATION-REVIEW-20261025.md) §2~4.
- [x] 작업을 W01~W12로 분해하고 선행 조건·통과 조건·구현 세 단계·검증 계획을 작성했다. 같은 문서 §3·5·6.
- [x] H0 범위 사용자 선택 기록(2026-10-25): 단일 성계 연속작전·첫 보급로 개방·정면/우회·기본 시간 증원. 호송 차단·통신소 지연·재점령까지 설계에 포함하되 제작 순서는 분리한다. [결정 원본](pc-campaign-design/H0-DECISION.md). O02의 범위 항목만 해소하며 수치·정책·독립 검토/통합 가능성·게임 구현 승인은 별도다.
- [x] H1 방향 사용자 선택 기록(2026-10-25): 게임 속 약20분으로 우선 비교·실제 플레이/정지/배속 별도 기록, 효과 지형으로 기본 흐름 확인 후 물리 장애물1~2개와 우회/엄폐 비교. [결정 원본](pc-campaign-design/H1-DECISION.md). O01/O03 방향만 해소하고 20분은 미검증 후보, 치수/속도·D04 저장/호환·O04/O05 등은 미정이다. H0 확장 설계 범위와 게임 구현 비승인 경계를 유지한다.
- [x] H1 정책3항 사용자 선택 기록(2026-10-25): 현재 보급시설 통제·가동/동일점령자 중단량 보존, 별도 부분생환 철수성과·명시철수모드·목표/지휘 동시 실패우선, 지역집결/유한정비/복귀·군사기 경고. [결정 원본](pc-campaign-design/H1-POLICY-DECISION.md). O04/O05 선택방향만 해소하며 비율/시한/회복수치·나머지 동일틱·저장 O07 및 IP1 채택은 미정이다. 실제 게임 구현·테스트 승인이 아니다.
- [x] H1 사건2항 사용자 선택 기록(2026-10-25): 본대출발과 동일 논리시각 통신소 가동완료 지연 인정·출발후 소급 없음, 유효지연만큼 공개 결산시한 연장·시한동시 유효 목표/탈출 인정. [결정 원본](pc-campaign-design/H1-EVENT-DECISION.md). 지휘상실동시 실패/명시철수성과만 유지, 수치·전체동일틱·O07은 미정.
- [x] H2 사용자 선택·인계 기록(2026-10-26): 미정 포함 설계 조건부 수용과 구현 스펙/측정 계획 준비, 전체 상태+후속 명령·초기 동일 규칙 버전 재개·관람/논리 재생 분리, 자기 시설 상실/상대 마지막 확인·적 재고 비공개·필수 일정 공지를 채택했다. [결정·0번 되먹임 원본](pc-campaign-design/H2-DECISION.md). D01~D10 독립 문서 검토·사용자 판단·[H2 기록 독립 수용](pc-campaign-design/REVIEW-H2.md)·0번 되먹임을 근거로 2026-10-26 R18 설계 검토 루프의 조건부 인계를 완료했다. 후속 구현 스펙·측정 계획과 그 검증은 별도다. O07 세부 계약·수치·전체 동시 순서·O06/O08 및 실제 게임 구현/시험은 미완료다.
- [ ] 구현 착수 전 시간 기준·작전 종료·사기 회복·지도 범위의 미확정 사항을 정리하고, 확정된 사용자 결정과 설계 가정을 구분한다.
  - [x] **I01a 설정 구현·기록 이전 완료(2026-10-27):** 순수 설정/고정 fixture 범위와 326 checks를 `8292805`에 반영하고 이전 작업에서 main 푸시를 확인했다. 실제 host/runtime/save 검증을 뜻하지 않는다. [I01a 결과](pc-campaign-design/I01A-IMPLEMENTATION-RESULT-20261027.md).
  - [x] **기존 data_rules 기준선 실패 해소(2026-10-28 완료, 10-27 착수):** 추격 거리 fallback 170을 POC 데이터 정본으로 옮기고, 누락/override 실제 추격 10사례를 보강했다. data_rules·I01a(326)·hold_distance·commander_ai·core_rules·battle_flow 종료 0. [결과·검증·독립 검토](pc-campaign-design/DATA-RULES-BASELINE-FIX-20261028.md). 독립 5-b 수용. 이번 수정의 커밋·푸시는 하지 않았다.
  - [x] **I01b-P0 준비 재고(2026-10-28):** 기존 K/S/ST 계약 재사용·확정/관측/미정과 의존성을 정리하고, 현재 21소스 SHA·19모듈 283선언·14앵커를 읽기 전용으로 조사했다. 정상/변조 거부 검사와 독립 5-b 수용. [준비·증거·다음 조각](pc-campaign-design/I01B-PREPARATION-20261028.md). 전체 snapshot/O07 완성이 아니다.
  - [x] **I01b-P1 신규 부분 시계 검사(2026-10-28):** 실제 BattleSim/TickClock 10seed×배속3×정지유무 60사례 exit0·tick2/clock150 PASS. 신규 코드와 실제 부분 시계 성과는 독립 5-b 수용. [결과·검토](pc-campaign-design/I01B-P1-RESULT-20261028.md).
  - [x] **I01b-P1 core 종료 증거 보완(원본, 2026-10-28):** 사용자 “원본에서 작업해” 지시 후 실제 core_rules exit0 확보. 원본 clock60/config326/hold/AI/flow도 각각 exit0, P0 도구도 원본 실행 exit0. 기존 관리 작업트리의 core exit=null은 과거 이력이다. [원본 이관 결과](pc-campaign-design/I01B-P1-RESULT-20261028.md).
  - [x] **원본 data_rules 전체 gate 기준선 해소(2026-10-28):** 기존 dirty bundle 기하의 식별자·계수를 전용 JSON으로 분리하고 allowlist/skip·기존 검사 SHA·slots 함수를 보존했다. 원본7종+bundle/group 9종 실제 exit0, 기하56·동결전후 정확비교3588·잘못된 데이터 거부3 통과. 기존1008경로 중 허용2개 외1006 SHA 동일·누락0, 독립5-b 수용. [결과·검증·보존경계](pc-campaign-design/DATA-RULES-GEOMETRY-RESULT-20261028.md). 종료 리소스 진단/TRACE 경고는 남고 Android export는 미실행이다. 과거 이관시 첫 gate 실패 이력은 유지하며 전체 I01b/A04~A06는 NOT_READY다.
  - [x] **I01b-P2a B0 부분 runtime 관측(2026-10-28):** POC/적벽 표준×10seed×fresh2 역순 40관측·신규2352체크와 core/data/config/clock/detection/supply 6종 실제 exit0, 독립5-b 수용. B0≠C0·선택필드 관측이며 save_policy=UNCLASSIFIED, 운영 저장/복원·실제 어댑터·제품 공간은 미완료다. [결과·검토·압축 인계](pc-campaign-design/I01B-P2A-RESULT-20261028.md).
  - [x] **I01b-P2b 부분 복원 구성요소(2026-10-31):** 탐지 기억·보급 sup_*10의 인메모리 capture/검증/준비된 target 복원과 신규40사례·2202체크·33거부, 관련6회귀 실제 exit0 및 독립5-b 수용. 비대상 상태는 caller 선행 책임이며 전체 checkpoint/host·replay/제품 공간과 I01b/A04~A06는 NOT_READY다. [진행 체크리스트](pc-campaign-design/I01B-P2B-CHECKLIST-20261031.md) · [결과·후속 인계](pc-campaign-design/I01B-P2B-RESULT-20261031.md).
  - [x] **I01b-P2c 제한 private runtime(2026-11-01):** 독립 빈 form 반례를 스펙 보완·최소 수정하고 정본 attempt5 70사례/11553체크/45거부·변경 후 최소3회귀 exit0, 선행4정본 회귀 연속성 및 다른 모델 최종5b 수용. 기존3660/source35·가역격리77 최종감사·SHA묶음·압축 인계/6 기록 마감. 전체 I01b/A04~A06 NOT_READY. [결과](pc-campaign-design/I01B-P2C-RESULT-20261101.md) · [독립 심사](pc-campaign-design/REVIEW-I01B-P2C-20261101.md) · [전용 체크리스트](pc-campaign-design/I01B-P2C-CHECKLIST-20261101.md) · [이관 자료](pc-campaign-design/SESSION-HANDOFF-I01B-P2C-20261101.md). [독립 마감 확인](../../tmp/i01b-p2c-20261101/REVIEW-CLOSEOUT-20261102.md).
  - [x] **제한 활성 owner 교체(2026-11-04):** 같은 원입력의 기존 owner handle에서 private runtime을 검증 후 교체하고 실패 시 현재 상태를 보존한다. actual exit0 정상20/20099체크/명명8·거부9, 최소P2c/core/data3회귀 exit0·독립5b 제한 수용·6 기록/감사/압축 마감. 전체 diff-check는 기존P2c행CRLF로 actual exit2이며 전체PASS가 아니다. 전체 I01b/A04~A06 NOT_READY. [결과](pc-campaign-design/I01B-ACTIVE-REPLACE-RESULT-20261104.md) · [독립 심사](pc-campaign-design/REVIEW-I01B-ACTIVE-REPLACE-20261104.md) · [체크리스트](pc-campaign-design/I01B-ACTIVE-REPLACE-CHECKLIST-20261104.md) · [이관](pc-campaign-design/SESSION-HANDOFF-I01B-ACTIVE-REPLACE-20261104.md). [독립 마감 확인](../../tmp/i01b-active-replace-20261102/REVIEW-CLOSEOUT-20261104.md).
  - [ ] **P02 첫 실제 headless opt-in 한정 연결(2026-11-07):** 명시 제한 runtime-ready JSON을 공통 factory/private owner와 실제 autoresolve CLI에 연결했다. 정본 attempt3/K6 정상8/13417체크·정책9·timeout2·명명46(API32+CLI14), CLI2성공/legacy1쌍 exact·P2c/core 회귀 exit0·비-Astra 독립 5b 재심사 수용 보류. 옵션3 진단분류 편차·supply 완료 E2E 미검증을 공개하며 전체 P02/I01/I01b/A04~A06 NOT_READY다. [결과](pc-campaign-design/P02-FIRST-HEADLESS-RESULT-20261107.md) · [체크리스트](pc-campaign-design/P02-FIRST-HEADLESS-CHECKLIST-20261107.md) · [최신 인계](pc-campaign-design/SESSION-HANDOFF-P02-FIRST-HEADLESS-20261107.md). 정정 감사와 압축 검증은 결과 문서를 따른다.
  - [ ] **P02 제한 CLI worker 연결(2026-11-07):** `--operation-worker`를 실제 AutoResolver 별도 스레드에 연결했고 독립 5-b 한정 수용을 받았다. Worker K6 attempt 3에서 실제 프로세스 53개 및 비교 9개 통과. 전체 P02와 제품 WorldMap operation·UI host·replay는 미완료다. [결과](pc-campaign-design/P02-WORKER-RESULT-20261107.md) · [체크리스트](pc-campaign-design/P02-WORKER-CHECKLIST-20261107.md) · [인계](pc-campaign-design/SESSION-HANDOFF-P02-WORKER-20261107.md).
  - [ ] **P02 제한 fresh replay CLI(2026-11-08):** 기존 실행기의 명시 입력·명령 재생 경로가 독립 5-b 한정 수용됐다. 2/K6 74/75 및 3/K6 단일 재실행 통과. 전체 P02 NOT_READY이며 제품 host/UI·WorldMap·replay 인수가 남는다. [결과](pc-campaign-design/P02-REPLAY-RESULT-20261108.md) · [진행표](pc-campaign-design/P02-PROGRESS-CHECKLIST.md) · [최신 인계](pc-campaign-design/SESSION-HANDOFF-P02-REPLAY-20261108.md).
  - [ ] **P02 private owner 표시용 사건 회수(2026-11-08):** 독립 재심에서 한정 수용됐다. 기본 17개, 신규 검사 14행·148개 단언, 격리 회귀 14개와 탐침 3개를 확인했다. 전체 P02는 NOT_READY이며 제품 호스트 연결과 공동 인수는 남는다. [결과](pc-campaign-design/P02-VIEWER-EVENTS-RESULT-20261108.md) · [진행표](pc-campaign-design/P02-PROGRESS-CHECKLIST.md) · [최신 인계](pc-campaign-design/SESSION-HANDOFF-P02-VIEWER-EVENTS-20261108.md).
  - [ ] **P02 legacy WorldMap 결산 경계(2026-11-08)**. 실제 legacy worker 결산 사본과 메인 join 후 게시를 분리하고 독립 5-b 한정 수용을 받았다. 제품 WorldMap operation·FleetBattle3D host·제품 replay는 미완료다. [결과](pc-campaign-design/P02-LEGACY-OUTCOME-RESULT-20261108.md) · [진행표](pc-campaign-design/P02-PROGRESS-CHECKLIST.md) · [인계](pc-campaign-design/SESSION-HANDOFF-P02-LEGACY-OUTCOME-20261108.md).
  - [ ] **P02 legacy FleetBattle3D 후보 준비(2026-11-08)**. 지정 bench patch 두 오류와 제품 동기 호출 경계는 독립 5-b 한정 수용됐다. 제품 operation host와 전체 P02 인수는 남는다. [결과](pc-campaign-design/P02-HOST-PREP-RESULT-20261108.md) · [진행표](pc-campaign-design/P02-PROGRESS-CHECKLIST.md) · [인계](pc-campaign-design/SESSION-HANDOFF-P02-HOST-PREP-20261108.md).
  - [ ] **P02 전투 준비 실패 안내와 최초 탈출(2026-11-08)**. 지정 준비 실패 안내 및 최초 종료·천하 복귀는 독립 5-b 한정 수용됐다. 전체 P02와 제품 operation은 미완료다. [결과](pc-campaign-design/P02-PREP-ERROR-RESULT-20261108.md) · [진행표](pc-campaign-design/P02-PROGRESS-CHECKLIST.md) · [인계](pc-campaign-design/SESSION-HANDOFF-P02-PREP-ERROR-20261108.md).
  - [ ] **I01b 후속 실제 통합:** 원 I01/I01b 및 A04/A05/A06는 NOT_READY다. 실제 어댑터·저장/재개·제품 공간은 후속이며, 원본 기존 dirty를 포함한 검사를 전체 캠페인 완료로 표시하지 않는다.
- [ ] 기존 PC 피처 브랜치와 최신 기준 브랜치의 차이·미커밋 변경·관련 작업 상태를 확인하고 필요한 변경의 통합 범위를 정한다.
- [ ] 1단계 공간·기동 기반 → 2단계 점령·보급 작전 → 3단계 증원·철수·완성 검증 순서로 구현한다. 단계별 검증 결과와 인계 내용을 남긴다.
- [ ] 구현 후 저장·재생·기존 적벽 회귀·PC 화면·사람 플레이를 확인한다. 구현 리뷰와 발견 사항 수정을 마친 후 병합 여부를 판단한다.

2026-10-25 설계 검토 당시에는 실행 코드를 수정하거나 테스트·화면 검증 완료로 표시하지 않았다. 후속 I01a와 기준선 수정 결과는 위 별도 기록을 따른다.

**진행 현황 (2026-10-07)**
- [x] M10 선행(호스트를 적벽 프로필로 연결): main 병합(`ba87606`).
- [x] POC 잔재 정리: main 반영(`9b9564b`, 적벽 화면 규칙 문구를 코어 combat 값에서 생성).
- [x] M10 본편(안개 UI·감속 `TickClock` 배율·`quiet()` 접촉 전용): main 병합(2026-10-07, 병합 후 테스트 7종 통과). 남음: 태블릿 heading 계단 눈 확인, 상실 표시 화면 확인.
- 다음 순서: M10 본편 병합 → §7·§8 UI 항목, 코어 후속(REVIEW-M8 F-1 등). 병렬 가능: 법무 문서, 밸런스 측정, 본편 쪽 작업.

---

## 1. 지금 확인할 수 있는 것

- [x] **data_rules 1번 "core에 규칙 수치 리터럴" 실패 보고(HOLD_MSG_TICKS 50, -1000000)** (2026-10-12): 최신 main 8f5bb30에서 재현 안 됨. `HOLD_MSG_TICKS`·`_hold_msg`는 core에 없고 `data_rules.gd`는 DATA_RULES_PASS(--import 후). 코드 변경 없음.

- [x] **목표 플랫폼이 전투 문서에 반영됐는지** → Q56으로 기록하고 제안서 §2, M10, M11을 고쳤다. 원래 내용은 다음과 같았다
  - 1차 목표는 안드로이드 태블릿과 윈도우 PC이고, 폰은 1차 목표가 아니다(사용자 지시, UI 세션에서 정함).
  - 그런데 `BATTLE_DECISIONS.md`, 제안서 §7.2·§7.4·M11, `EXPERIENCE-DESIGN.md`는 아직 "모바일"과 폰 기준으로 쓰여 있다.
  - 확인할 것:
    - Q51의 "모바일 실제 8~12분"을 태블릿 기준으로 읽어도 되는가
    - P43(48dp)의 기준 기기
    - M11 실기기를 태블릿으로 볼 것인가
- [x] **효과음 사건과 코어 사건이 맞는지** → 빠진 자리 목록은 `REVIEW-UI-v2.md` §11. 코어 사건이 생길 때 붙인다. 원래 내용은 다음과 같았다
  - UI-2가 `hud/ui_kit/ui_sound.gd`에 사건 13종을 만들었다: 버튼, 탭, 확정, 무거운 확정, 거부, 되돌리기, 정지, 경보, 결정, 일제사격, 함선 격침, 전대 파괴, 전대 상실.
  - 대조할 것은 두 가지다.
    - `IMPLEMENTATION-HANDOFF.md` §4의 `events[]`
    - 내러티브의 사건(국면 전환, 사기 구간 변화, 위장 항복 서신, 의심 50·80, 기류 창 개방·종료, 화공 발동·번짐, 결집, 퇴각·항복, 특성 발현 컷인)
  - 빠진 소리 자리를 목록으로 만든다.
- [x] **효과음이 전역 난수를 쓰는지** → 썼다. W-4로 보냈고 `6046b60`에서 고쳐졌다. POC 규칙 자체(`FleetBattle3D.gd`)의 전역 난수는 M1 3단계에서 분리한다
  - `ui_sound.gd`는 `randf_range`로 음높이를 흔든다.
  - POC 규칙도 전역 난수(`randf`, `randi`)를 쓰므로, 소리가 재생될 때마다 규칙 난수열이 밀린다.
  - 그러면 제안서 §9.1 3단계(연출 난수 분리)와 M1 결정론 기준에 걸린다. 연출 전용 생성기를 쓰도록 UI-2에 알릴지 판단한다.
- [x] **시나리오 문서에 낡은 부분이 남았는지** → §6을 갱신했다. §4는 갱신 안내로 두고, 제안서 §4.1은 M2에서 바꾼다. 원래 내용은 다음과 같았다
  - `SCENARIO-RED-CLIFFS-208.md` §4: 초기 간이 시뮬레이션 결과다. 갱신 안내는 있다.
  - `SCENARIO-RED-CLIFFS-208.md` §6 "남은 일": 위장 항복은 이미 설계에 반영됐다.
  - 제안서 §4.1의 데모 편성표: "대체 예정" 표시만 있다.
  - 세 곳을 v0.3 기준으로 정리할지 정한다.
- [x] **시나리오 JSON과 문서가 일치하는지** → 생성기 출력은 커밋된 파일과 같았다. 다만 `realtime_rules`에 화공, 사기 사건, 결정 카드 등이 빠져 있어 보강했다. 원래 내용은 다음과 같았다
  - `make_red_cliffs_208.py`를 다시 돌려 `red_cliffs_208_realtime.json`과 차이가 없는지 본다.
  - 경험 설계에서 채택한 것이 `realtime_rules`에 모두 들어 있는지 본다: 투입 시차, 거리대 대기, 화공 수치, 연환·역병, 결집, 위기 구간, 기류 창, what-if 3장, 조조 성향 3종.

## 2. UI-2 다음 병합에서 볼 것

- [x] V-1·V-5·V-8 반영 확인(3차 리뷰 §9). V-6은 ID 체계가 달라 W-1로 다시 보냄
- [x] 3차 리뷰 W-1~W-7 반영 확인(4차 확인 §12, `6046b60`)
- [x] X-1: 조조군 "지휘관 명단"을 "기록상 종군 장수"로 바꿨는가 → 반영 확인(`befe55a`, `ScenarioRoster.officers()`)
- [x] 설정 탭(화면·진행·소리)의 항목이 결정과 맞는가 → 선택 감속 3택(Q36)과 진동 끄기가 없다. W-7
  - 선택 감속 방식: Q36 "조작 중에만" 선택지와 Q55 유휴 해제
  - 자동 ×4 끄기(Q52)
  - 결정 카드 속도(P45, "설정에서 바꿀 수 있다")
  - "턴제처럼" 프리셋(`EXPERIENCE-DESIGN.md` §7)
  - 진동 끄기
- [x] 폰 전용 HUD 작업이 목표 플랫폼(태블릿)에 맞게 우선순위가 내려갔는가 → `7898d8a`에서 `UI-FLEET-VISUALS.md`의 폰 전용 항목이 삭제되고 모든 컨트롤이 52단위 이상으로 바뀌었다(`tests/touch_targets.gd`). 규칙·결정과 충돌 없음
- [x] 정본 편성 연결: 연합은 JSON과 맞다. 불참 인물도 나온다. 난이도 미적용(W-2)과 조조군 정보 노출(W-3)을 지적했다. 이 항목의 원래 질문은 다음과 같았다. 정본 편성 연결(UI 인수 메모 "다음 할 일" 5번)을 하면 화면에 나오는 것이 `red_cliffs_208_realtime.json`과 맞는가
  - 전대명, 지휘관, 부지휘관, 참모, 함종 구성
  - 배치하지 않는 인물(손권, 태사자 등)이 나오지 않는가

## 2b. 화면 캡처 확인 (2026-10-05, 통합 main d8a86cd)

`tests/capture_ui.gd`로 title·prologue 0~7·brief·battle·select·decision·pause·nohud를 1920x1080·1280x800에서 캡처해 눈으로 확인했다. 레이아웃 깨짐·글자 잘림·겹침(패널끼리)은 없다. 서막 8장 문안은 `NARRATIVE-RED-CLIFFS.md` §11.2 확정본과 한 글자도 다르지 않다(사백 년 삭제, 허도, 성역, 하북).

- [ ] **적 명패가 HUD 패널 밑에 가려짐(M10).** 1920에서 `조인` 명패가 명령 패널 위쪽 가장자리에 반쯤 잘려 보이고, 1280에서는 `편성` 띠 뒤로 들어간다. 패널이 명패를 덮는 가림이지 레이아웃 겹침은 아니다. 고치려면 명패를 패널 안전 영역 밖으로 밀어 넣는 로직이 필요해 작은 수정이 아니다. 캡처 구도(교전 직전 카메라)가 만든 상황이라 실전 빈도는 사람 플레이로 본다.
- [ ] **L1 펼침 정보 패널이 아래쪽 명패를 가림.** 1280 select에서 `마초` 명패가 정보 패널에 가려진다. 위와 같은 종류.
- [x] 선택 패널 접힘(L1)·펼침 캡처는 battle(접힘)과 select(펼침)로 이미 있다. 따로 만들지 않는다.
- 참고: 1280에서 브리핑의 `측면 증원 가능성` 줄이 버튼 줄과 14px 간격이라 빡빡하다(겹침 아님).

## 3. 구현 세션이 생기면 볼 것

M1 병합(`29978b7`) 3차 세션 리뷰: `REVIEW-M1.md`. 컨셉 세션이 `tests/core_rules.gd`(CORE_RULES_PASS)와 `tests/boundary.gd`(BOUNDARY_PASS core=10 screen=41)를 직접 돌려 통과를 확인했다.

- [x] M1 완료 기준(§9.2): 통계 동등성은 1000시드 기준으로 통과(승률·종료 경로 Δ 0, D ≤ 0.123). 5초 공격만 길이 평균 1.4% 짧은 미세 차이가 남았다(원인 미상, 후속). §9.2를 1000시드로 개정
- [x] 연출 난수와 규칙 난수의 분리: `view/fx_layer.gd` 전용 생성기, 코어에 전역 난수·시간 API 0건
- [x] 감속이 틱 폭이 아니라 누산기 소비 속도만 바꾸는가: 코어와 UI 모두 `TickClock.set_speed`(2026-10-07, `G.slow`)
- [~] 투영 v0 필드: `tick`·`clock`·`cp`와 `counts`·`control` 자리까지. `chain_op`·`pending_decisions[].time_left`·곧 열릴 분기는 빈 자리 → `chain_op` M9. `time_left`·곧 열릴 분기는 M7에서 채웠다(`pending_decisions`, `upcoming_decisions`)
- [x] 조용한 구간 판정과 AI 입력이 공개 투영만 쓰는가(정보 경계) → M6에서 투영·사건·AI가 접촉만 쓴다(`M6-NOTES` §1). UI `quiet()`는 접촉만 본다(2026-10-07 완료)
- [x] M2: 코어가 시나리오 JSON의 `difficulty_policy`와 `deploy_delay_s`를 그대로 읽는가 → 수용(`REVIEW-M2.md`, `06be305`). 함종·진형은 M2b로 `data/scenarios/base/`에 스냅숏을 두었다
- [~] M4 기준선: 측정 완료(`docs/core/M4-NOTES.md` §4). 표준 attack 연합 63.5%·길이 9분, none 85.5%·19.5분(20분 시계 40%)으로 RX 예측(15~16분, 파도 3)과 다르다. AI 한계라 M7 기준선에서 재조정. 컨셉 리뷰 대기
- [x] M4 리뷰: 수용(`REVIEW-M4.md`). 6종 테스트 통과, 질문 4건 판정(주유 `charm` 데이터 추가). 후속: 제한적 승리의 "함대 전체 도달" 빈틈(구현, M5 전), 길이·승률은 M7 기준선(AI 대 AI, 1000시드, 난이도 3종)
- [x] M6 리뷰: 수용(`REVIEW-M6.md`). 8종 테스트 통과, 확인 임계 30 채택, 지형 3구역은 본편 데이터와 일치, 투영은 미탐지 0건. 후속: **F-1 추정 사격이 실제 위치로 쏨(정본은 마지막 위치+오차, M7 기준선 전)**, **F-2 안개 판 재생 불가(`replay`에 프로필 없음)**, F-3 접촉 소멸 사건의 실제 위치, F-4·F-5 사건 값·필터, F-6 AI 입력을 투영으로(M7), F-8 지형 켬/끔·임계 30 none 측정(M7 기준선). 승률·길이는 미재현(구현 메모 값 인용)
- [x] M7 리뷰: 수용(`REVIEW-M7.md`). 9종 테스트 통과(commander_ai 포함), 정보 경계·불간섭·마지막 위치 조준·결정 카드 2종·직접/위임 수용, 표준 규모 0.9 잠정 수용, `target_cost_ratio` 표준 1.24 → 1.65 정정(실제 비용비). 후속: **F-1 성향 4명 정본 §4 대조(조인 절의, 조홍 실무, 정보 실무, 황개 절의)**, **F-2 실무 손실 임계 퇴각** — 둘 다 1000시드 기준선 전(구현). **F-1·F-2 완료**(2026-10-05, `M7-NOTES` §6: 표준 80시드 연합 51.2%·14.2분). F-3~F-8은 리뷰 §7
- [x] M8 리뷰(보급과 수리): 수용(`REVIEW-M8.md`). 10종 테스트 통과(`supply_rules` 포함), 편차 6건 수용(제안서 §4.13·§4.4 반영), 새 편차 D-7 자기 보급 수용, 제안값(`still_eps`, 기지 재고 무한·수리 물자 없음) 수용, AI 보급 행동은 보류, 병합 코드 재측정(리뷰 §7.1). 후속: **F-1 수리·회복이 다음 피격 한 번에 사라짐(구현, M10 사람 플레이 테스트 전)**, F-2 AI 보급(대기열), F-3 UI(M10), F-4 `still_eps` 초당 값(낮음)
- [x] M5 리뷰: 수용(`REVIEW-M5.md`). 7종 테스트 통과, 편차 1건(기동% 적용)은 제안서를 고침, 질문 3건 판정, M4 후속 3건 닫힘. 후속: 진형 탭(UI, 투영 키), M7에서 AI 진형 선택·퇴각 선회 재측정

- [x] M9 리뷰(계략과 승계, 강습): 수용(`REVIEW-M9.md`). 12종 테스트 통과(`stratagem_rules`·`succession_rules` 포함), G8-04 판정표와 코드 일치, 편차 16건 수용(호위 반경 100 → 130 조정, 데이터 반영)·새 편차 E-1 수용, 기류 창 데이터 유지(재검토 조건 §5.1), 표준 80시드 재측정 58.8~60.0%·14.2분(화공 발동 24%는 메모 35%와 다름). 후속: 1000시드에서 화공 발동·간파 줄 확인(F-1)·승계 영향 분리(F-6), 상급 위장 가능성 사람 확인(F-3, M10), 카드 문구(F-2)·UI(F-7), 테스트 포맷 오류(F-4, 낮음), 전대 이음 UPSTREAM 기록(F-5)
**M1 기준 보완 (3차 세션, 구현 세션에 전달)**
- 승률 외에 종료 경로(`reason`) 분포가 정책별로 바뀌지 않는지 본다.
- KS 대상에 `reinf_t`(증원 시각)를 넣는다. 거의 상수인 변수(attack5의 `killed`≈893)는 KS가 과민하므로 평균 상대 차이 1% 이내로 본다. §9.2 4번에 반영 대기(구현 결과가 나오면 확정).
- 난수 교체만 / 틱 폭(20→10Hz)까지, 두 단계의 D를 따로 적는다.

- [ ] 영상 공개 회피 조치(대기열, `docs/release/LEGAL-YOUTUBE-RISK.md` §1): ~~HUD 숨김 촬영 토글(구현)~~ 완료 2026-10-05(`F1`), VII 겹침 외형 교체(컨셉 결정 완료 2026-10-05 `docs/ui/HUD-GENRE-CONVENTIONS.md` → UI 세션 V-1~V-8 대기, 구현 뒤 캡처로 §2 점검), ver3 모델은 Meshy로 확인됨(영상 설명란에 출처 표시), 참조 이미지 없음 확인 → 교체 불필요
- [ ] **(대기열) 지휘관 초상 새로 제작** (2026-10-05 사용자 결정: 현 초상 `assets/portraits/commanders_sheet_v1.png`은 임시 아트로 보고 **새로 만든다**. 기존 초상의 역검색·코에이 초상 대조·생성 기록 보존은 하지 않는다. HUD 숨김을 가급적 안 쓰므로 초상이 영상에 노출되는 점은 그대로, `LEGAL-YOUTUBE-RISK.md` ⑥의 "HUD 숨김으로 초상 회피" 전제는 무효)
  - [ ] (2026-10-09 사용자 TODO) 장군·군사(참모) 인물 그림 제작 — 범위는 장군(관우·장비·조운 등)과 군사(제갈량·주유 등) 전원, 위 새 초상 제작과 한 묶음으로 처리
  - [ ] **새 세션에서 검토:** 성한지(`C:\WorkSpace\Seonghanji`) 폴더에 있는 인물 사진·초상을 참고 자료로 쓸지. 볼 것: ① 그 이미지의 출처·권리(직접 제작인지, 생성인지, 외부 이미지인지), ② 화풍·인물 설정이 우주 삼국지 세계관과 맞는지, ③ 참고 범위(그대로 재사용 / 설정·구도만 참고 / 쓰지 않음), ④ 새 초상의 제작 방식(직접 제작·외주·AI 생성)과 생성 기록 보존 방침, ⑤ 교체 순서(주요 인물 먼저). 컨셉 세션 역할이라 코드는 건드리지 않고, 결정은 `BATTLE_DECISIONS.md`에 Q번호로 남긴다
  - (아래는 새로 만들기로 하기 전의 1차 점검 기록. 참고만 한다. 역할 구분: 디자인 품질 지적(d)은 새 초상 제작 때 반영) ① 1차 시각 점검 결과(2026-10-05, Claude 의견, 법률 자문 아님, 원본 직접 대조는 비교 불가): 6인 모두 위험도 낮음. 관우(홍안·녹건녹포·장염), 유비·제갈량 복식은 역사 관습이고, 오=적·위=청흑 배색과 함교 배경은 장르 일반 표현이다. 은영전 고유 요소(금발·베레모·제복)는 보이지 않는다. 남은 일: (a) 6인을 잘라 Google Lens·TinEye로 역검색, (b) 코에이 13·14 공식 초상과 나란히 대조(화풍 계열이 비슷함 — 확인 필요), (c) 제갈량 줄무늬 높은 모자가 기존 디자인과 겹치는지 확인(낮음~중간, 관건 두건형·우선으로 바꾸는 안), (d) 디자인 품질: 유비와 조조의 얼굴형이 거의 같고, 제갈량과 조조가 둘 다 턱 괴는 포즈 → 교체 시 구분, (e) 실존 배우 닮음(초상권)은 판단 안 함 → 사람이 확인
  - 무료 출시·영상 노출 시(2026-10-05, 일반론): 무료여도 침해 여부는 같다(배상·동기만 줄어듦). 유튜브 업로드는 공중송신이고, 수익화하면 상업적 이용으로 본다. Content ID는 정지 이미지를 잘 못 잡아 권리자 수동 신고 위주 → 영상 삭제와 경고(3회면 채널 삭제). 초상권(배우 닮음)은 영리 여부와 무관하고, AI 생성물은 우리 저작권 주장이 어렵다. 조치: (a)(b)는 첫 영상 공개 전에 끝내고, 설명란에 "AI 생성 이미지, 임시 아트"를 표기하고, 생성 기록을 보존하고(③), 신고가 오면 해당 초상만 바로 교체할 수 있게 준비

M3 리뷰(2026-10-04): `REVIEW-M3.md`. 수용. 후속은 방향 배분 잔여 이월(M5), 거리대별 지휘관 능력치(M4), 첫 일제 동기화 측정(M4), P12 두 변형(M4), 지휘 한도 초과 페널티 확인(M5 전).

## 4. 본편 답 (2026-10-04 도착, `UPSTREAM-ISSUES.md` §D)

전부 판정이 왔다. C4는 원문 대조가 남았고(`NARRATIVE-RED-CLIFFS.md` §10), G8-04는 2026-10-04에 확정됐다(V-74). 본편 쪽 코드(A5·A6)와 본편 main 병합이 남았다.


- [x] A1 통솔 값의 정본(데모 대 `characters.json`). 지휘 한도와 시나리오 편성이 달라진다
  - 사전 영향 분석(3차 세션): 생성기는 이미 `characters.json`을 쓴다. 정본이 데모 값으로 바뀌면 차이가 1~5이므로 한도가 +2~+10 달라진다. 한도가 늘면 초과 편성은 없다. 가장 빠듯한 전대는 RC-CAO-SQ-01로 비용 230, 한도 232(여유 2)다. 정본이 `characters.json` 그대로면 변경 없음. 한도가 줄어드는 판정이 나오면 이 전대의 편성부터 다시 본다
- [x] A2·A3 탐지와 추정 사격 임계(본편 데이터 수정 여부)
- [x] A7 채모·장윤 서술(정사 / 연의)
- [x] C4 역사 감수: 사관 서술, what-if 해설, 후일담의 인용(채모의 출사, 연의 회차 번호)
- [x] G8-04 장수 부상·전사·포로 규칙 → 본편 V-74로 확정(2026-10-04). `{조조_상태}` 슬롯과 §4.14를 고쳤다. 포획 반경 120·혼선 2단계는 잠정값이라 M9에서 측정한다(`UPSTREAM-ISSUES.md` §E)
- [x] G8-04 잠정값을 `realtime_rules`에 `status: "proposed"`로 추가(2026-10-04, REVIEW-M2 후속 A): `commander_succession`, `commander_casualties`. 키 경로는 `SCENARIO-RED-CLIFFS-208.md` §실시간 규칙 부분. 구현 세션은 M9 전에 `proposed_paths()`에 두 키를 넣으면 된다

## 5. 구현이 있어야 닫히는 설계 문제

- [x] **서막(첫 진입 배경 서사)** 구현(2026-10-05, 클라우드 UI 세션, 브랜치 `claude/prologue-ui`, 로컬 병합·화면 확인 대기): 문안 `hud/ui_kit/prologue_text.gd` 한 곳, 화면 `deck_screens.gd` PrologueScreen, 진입 `command_deck.open_prologue_or_brief()`, 설정 `prologue_seen`·`reduce_motion`(진행 탭 "동작 줄이기"), §11.3 문구 교체. 남은 것은 아래 대기열 항목. 원래 항목: `NARRATIVE-RED-CLIFFS.md` §11. 타이틀 "출격 준비" → 서막 8장(시대 2 + 적벽 6, 첫 회만, `prologue_seen`) → 브리핑, 타이틀에 "서막" 다시 보기, 건너뛰기·동작 줄이기. 같은 작업에서 §11.3 타이틀·브리핑 문구(성간 삼국·촉한·위·회랑·제독) 교체. 테스트: `tests/ui_flow.gd`에 첫 회 표시·두 번째 건너뜀, `capture_ui.gd`에 `prologue` 장면. 문안 대조는 2026-10-05 완료
- [ ] **(대기열) 서막 후속** (로컬): ① ~~문안 대조~~ 완료(2026-10-05): `prologue_text.gd`를 §11.2에 맞춤(사백 년 삭제, 허도, 성역, 하북). ② 화면 확인 `godot --path . --script tests/capture_ui.gd -- prologue res://out/ui-prologue.png [장 0~7]`(헤드리스는 캡처 불가). ③ "글자 크기 3단계"(EXPERIENCE-DESIGN §7)는 아직 별도 설정이 없어 UI 크기(4단계, content_scale_factor)를 따른다. 글자 크기 설정이 생기면 서막 26pt 본문도 연결. ④ 성도(星圖) 겹치기는 후속(§11.2). ⑤ 천하 지도 연동 브랜치 `claude/sharp-hopper-roo4tn`은 이미 천하 → 출격 연출 → `open_prologue_or_brief()`(있으면) → 브리핑으로 들어온다. 두 브랜치 병합 때 겹치는 곳: `command_deck.gd`(setup 끝 진입 분기, `title_label()`·`to_title()` "천하로"), `deck_screens.gd`(Pause·Result의 title_btn), `FleetBattle3D.gd`(init_game 시드, brief 카메라 1줄). 양쪽 분기를 모두 살린다
- [x] 전투 효과음 연결(2026-10-05): 원샷 12종을 `ui_sound.gd` EVENTS에 넣었다. 코어 사건 연결은 `FleetBattle3D.sfx_event` → 덱 `sound.play`: 일제사격(artillery→laser_heavy, line_fire→laser_light)·missile_launch·missile_hit·fighter_launch·charge→engine_boost. 루프 3종은 `UiSound.set_loop(이름, 0~1)` 재생기(종류마다 하나, 동시 최대 3). 테스트 `tests/ui_sound.gd`
- [ ] **(대기열) 효과음 후속**: ① 코어에 사건이 없어 못 붙인 것: fighter_guns·fighter_dock(함재기 교전·회수), shield_hit·armor_hit(피격 종류), ~~chain_explosion·fire_ignite·fire_loop(화공 M9)~~ M9에서 연결(`sfx_event`, 루프는 새 신호 `sfx_loop`). ② 루프를 부르는 쪽이 없다: engine_loop(함대 이동 중), beam_loop(지속 사격 중)을 렌더러·투영 상태로 `set_loop`에 연결
- [x] **M7 AI 대 AI 1000시드 기준선**(2026-10-05, `M7-NOTES` §7, 측정 커밋 `50a075a` = REVIEW-M8 F-1·M9 이전): 입문 1000 연합 **91.5% ±0.9**·11.9분, 표준 1000 연합 **50.6% ±1.6**(조조 49.4%)·14.4분, 상급 200 연합 **2.5% ±1.1**·14.3분(극한 40시드 4.8%보다 낮아 순서 확인 필요). 목표(표준 조조 60%·15~18분, 입문 무명령 50~70%) 셋 다 미달. 실행 속도가 M7 추정의 2~4배 느렸다(표준 4시간 40분, 코어당 약 40%만 사용)
- [~] **(보류 · 2026-10-06 사용자 결정: 새 측정 없이 기존 측정(2026-10-05 기준선, M9 이전 코드)과 M9 80시드 값을 추정값으로 쓴다. 레버 조정·1000시드 재측정은 사람 플레이 테스트에서 문제가 나올 때만 한다) 1000시드 레버 조정**(구현 세션, `M7-NOTES` §7 제안): 표준 조조 시작 사기 ↑(1순위) → 길이 모자라면 `range_band_hold` ↑. 입문은 위임 아군 `engage_trigger_r` ↓ + 규모 0.7 ↑. 재측정은 F-1·M9가 들어간 main에서 새 기준선(80시드 스윕 → 1000시드 확인)
- [~] **(보류, 위 결정에 따라 측정 생략) 극한 200시드 무명령**: 상급 200시드 2.5%가 극한 40시드 4.8%보다 낮다. 난이도 순서 확인(`TAG=_b200 tools/m7/baseline.sh 극한 200 8`, 약 2시간)
- [x] **REVIEW-M8 F-1 수리·회복 유지** 완료(2026-10-05): `healed_wound`·`healed_mod`를 `_wound` 목표에서 뺌, 선체 그대로, `supply_rules` 확인 추가. 표준 80시드 51.2%·14.2분, 시드별 차이 0/80
- [ ] **(대기열) REVIEW-M8 F-2 AI 보급 행동**: F-1과 1000시드 기준선 뒤 보급 효과를 보고 위임 AI·조조 AI에 `resupply` 임계(중파·탄약 비율)를 더할지 정한다. F-4(`still_eps` 초당 값)는 완료(2026-10-05, `still_eps_px_s`)
- [ ] **(대기열) 적벽 작전 지도(은하맵 홈) Godot 구현**: 시안 `docs/ui/mockup-galaxy-map-v1.html`, 설계 `docs/ui/GALAXY-MAP-REDESIGN.md` §5. 타이틀 → 작전 지도 → 브리핑. 본편 `galaxy-map.json`에서 적벽 전역 스냅숏을 뽑아 쓴다. 강릉 소유(위)는 컨셉 추정이라 확인한다
- [x] 천하 지도 ↔ 적벽 전장 연동(2026-10-05, `WORLD-MAP-LINK.md`): 진입 화면 천하 지도, 출격 연출, 자동 해결(적벽 프로필·스레드), 결과 연출, "천하로" 복귀. `tests/world_link.gd`
- [ ] **(대기열) 천하 연동 후속(M10)**: 직접 지휘 전장을 `brief.profile()`(적벽 편성)으로 바꾸고 카드의 "시연 편성" 문구를 뺀다. 전장 HUD 가장자리 방위 표식(`brief.edge_labels`). `WORLD-MAP-LINK.md` §7
- [ ] **(대기열) 천하 지도 화면 확인(로컬)**: 확대 연출 속도, 글자 크기, 범례·카드 배치, 태블릿 자동 해결 시간(컨테이너 입문 20초·표준 30초)
- [ ] **(대기열) 상위 기술「여걸」 전투 효과 구현** (2026-10-10 사용자 결정, 본편 `6a635d3`·POC `421b8f4`): 본편 여성 인물 19인에게 부여된 특성 "제독·부제독·참모 어느 직책이든 불이익 없이 배정, 배정 함대 사기 +15%"는 지금 데이터 문구뿐이다. 구현: ① 편성 화면 직책 적합도·불이익(`limit_tier` 등)에서 `traits`에 「여걸」이 있으면 면제 ② 그 장수가 배정된 함대의 사기 +15%(`core/battle/morale.gd`). 테스트 1건(유무 비교)
재측정 목표·순서·레버·사람 플레이 테스트는 `BALANCE-PLAN-M4.md`에 정리했다(2026-10-04).

- [x] 표준에서 조조가 확인 등급을 거의 받지 못한다 → M6: 임계 37→30(제안값)으로 100%. 컨셉 확인 대기
- [~] 화공 차단 3종, 의심 가감 요인, 주유 결집, 연환 대형 유지는 제안값이다. M9 → 구현 쪽 판정은 `M9-NOTES` §6 2번(차단·연환은 그대로, 호위 반경 130 이상 제안, 주유 결집은 AI가 쓰지 않아 M10 사람 플레이 테스트에서). 컨셉 확인 대기
- [ ] 표준 화공 시도 승률이 기준선에 따라 22~32%로 흔들린다. M4
- [~] 상급 화공 승률이 화공 시점에 크게 좌우된다(480초 75%, 600초 98%). 기류 창 범위를 다시 볼지 정한다. M4·M9 → M9: 데이터 그대로 둔다(`M9-NOTES` §4.2). 실시간 코어에서는 창이 판 막바지에 열려 발동률이 판 길이에 묶인다(상급 발동 25%, 목표 27.4%). 판 길이 조정 뒤 다시 본다
- [ ] 결정 4~6번(Q51)이 실제 플레이에서 나오는가. 지금은 사건 수로 대신 셌다. M4·M7
- [ ] 선택 시 감속(Q31·Q36)을 실기기에서 판단한다. M11. 기준 기기는 태블릿

## 6. 상품화 대기열 (2026-10-05 상품화 리뷰)

상품 수준 출시에 비어 있는 것이다. 안드로이드 쪽(뒤로 가기, 릴리스 서명·AAB, 아이콘, 실기기)은 `docs/release/ANDROID-DEV-NEEDS.md`가 정본이라 여기 다시 적지 않는다.

**결정 먼저 (사용자, Q번호로 남김)**
- [ ] 유료/무료, 국내 한정 여부 → 스토어 자료·현지화·결제 범위가 정해진다
- [ ] 전투 이어하기 방식: 결정론 재생(`BattleSim.replay` 활용, 싸다) / 상태 스냅숏(견고, 비싸다)
- [ ] BGM 조달: 직접·외주·라이선스 구매·AI 생성(AI면 초상과 같은 권리 검토)

**출시를 막는 것**
- [ ] **윈도우 내보내기 프리셋** — `export_presets.cfg`에 Android만 있다(Q56 절반 빠짐). 아이콘·버전 정보·서명 여부
- [ ] **전투 중 이어하기** — 저장은 설정뿐이다. 판이 약 14분이고 안드로이드는 백그라운드 앱을 죽인다. M12 저장 계약보다 먼저
- [ ] **크레딧·라이선스 고지 화면** — 폰트 OFL(배포물에 라이선스 동봉 필요)·Quaternius CC0·Meshy·생성 이미지 표기
- [ ] **스토어 자료** — 개인정보처리방침 URL(수집 없어도 Play 필수)·데이터 안전 양식·연령 등급(IARC)·스크린샷·소개문

**품질 (출시는 되지만 상품이 아님)**
- [ ] **BGM 없음** — `assets/audio`는 효과음만 있다. 설정에 음악 음량도 추가
- [ ] **생성 배경·VFX 출처 검토** — ImageGen 배경(`red_cliffs_starfield_v1`)·VFX 시트도 초상(§3 대기열)처럼 교체·표기 방침을 정한다. 함선 Quaternius/Meshy 화풍 통일
- [ ] **조작 튜토리얼** — 서막·브리핑은 있지만 진형 상성·탐지·화공 조건을 가르치는 흐름이 없다. 사람 플레이 테스트로 필요 범위를 정한다
- [ ] **진행 기록 저장** — 난이도별 클리어·최고 결과·본 what-if. 시나리오 하나라 재플레이 동기의 바탕
- [ ] **사람 플레이 테스트 0회** — `BALANCE-PLAN-M4.md` 기준으로 진행. 1000시드 기준선은 기다리지 않는다(2026-10-06 결정: 측정 대신 추정값)
- [ ] 접근성 남은 것: 글자 크기 3단계(EXPERIENCE-DESIGN §7), 색약 대응(세력 적·청 배색 외 모양 구분)

**운영**
- [ ] CI가 `core_rules` 하나만 돌린다(`.github/workflows/android.yml`). 테스트 12종 전부, 윈도우 빌드 잡 추가
- [ ] 크래시·오류 수집 — 최소 `user://` 로그 파일과 내보내기 수단
- [ ] 현지화 — `tr()` 0건. 해외 출시를 정하면 문자열 분리를 먼저 한다(국내 한정이면 보류)

## 7. 태블릿 실기기 테스트 지적 (2026-10-05, 사용자)

구현·UI 세션이 처리한다. 각 항목은 원인 확인부터 시작한다.

- [x] **손권 함대가 없음** — 원인(2026-10-05): 호스트 `scripts/FleetBattle3D.gd:141`이 `BattleSim.new(seed)`로 POC 프로필을 써서 손권 전대 3개(주유·정보·황개)가 만들어지지 않는다. 윈도우도 같고 태블릿 전용이 아니다(M3~M9 NOTES의 "적벽 프로필 화면 연결은 M10"). 코어·`ScenarioProfile` 변환은 정상(손권 3·유비 4). 같이 고침: 투영 `faction`이 진영만 봐 손권군이 `shu`로 나오던 것 → `BattleProjection.faction_key()`·`BattleSource.faction()`, 회귀 테스트 `tests/roster.gd`. 정본 대조: 손권 3개 전대는 B6(Q44)의 의도된 차이(본편 demo-setup은 SQ-01뿐). 실제 해소는 아래 M10 선행 항목
  - [x] **(M10 선행) 호스트를 적벽 프로필로 연결** (2026-10-06 완료, ⑤의 POC 규칙 문구·함수 정리는 `SESSION-HANDOFF` "남은 정리"로 이월) — 위 항목의 실제 해소. 막는 것: ① `FleetBattle3D.init_game()` `BattleSim.new(battle_seed, TICK_HZ, ScenarioProfile.load_profile(...난이도))`로 교체 ② `groups = {1: [fleets[0].id], ...}`(`FleetBattle3D.gd:151`) 인덱스 하드코딩을 `group_id`/`fleet_groups` 기반으로 ③ 브리핑 편성표 `ALLY_DEF`·`FOE_DEF`(`deck_screens.gd:256`, 결산 `:591`)를 시나리오 편성(`ScenarioRoster.deployed`)으로 ④ 렌더러가 side 색만 쓰므로 손권군을 세력 색·인장으로 구분(`Factions` 키는 이미 `wu`) ⑤ POC 전제 테스트(`battle_flow`, `smoke`, `capture_ui` 등)와 POC CP·방어진형 코드 정리. 완료 기준: 캡처에 손권 3개 전대가 오(吳) 인장으로 뜨고 `roster` 테스트의 "POC has no class counters" 가정을 시나리오 카운터 확인으로 바꾼다
- [x] **진형이 "방어"뿐** — 진형 탭 구현(코어 7종 카드, `FORMATION-TAB-SPEC.md`). 호스트 연결(`BattleSource.combat`)은 M10. 원래 내용: 호스트 POC 프로필의 방어진형 버튼이 그대로 남은 상태(`SESSION-HANDOFF` M5 메모). M10 진형 탭(`formation_id`·`form_to` 투영 키)으로 10종 선택을 넣는다
- [ ] **전대 그래픽이 조잡** — 검토·구현 거의 끝(`REVIEW-FLEET-VISUAL.md`). 원인은 함선 위치를 뷰가 한 번 만들어 전대 노드에 붙여 강체로 움직이고, 진형 변경이 화면에 반영되지 않은 것이었다. 구현됨: PR0 실루엣 셰이더(윤곽), PR1·2 슬롯 추종·진형 전환, PR3 격침 빈자리, PR4 항적·목적지 고리, PR5 태블릿 실측(밀도 높음도 120fps). 남은 확인:
  - [ ] **태블릿 눈 확인(완료 기준)** — 사용자가 "자연스럽다"고 판단할 때까지. 이동 시작 시 대열 늘어남, 선회 부채꼴, 진형 전환 이동, 줌 인·기본 줌 둘 다
  - [ ] 격침 빈자리 메움을 실제 속도 플레이로 확인(폭발 섬광이 가려 캡처로는 불명확, `out/gap-*.png`)
  - [ ] 항적 세기가 옅음 — 눈 확인 뒤 튜닝
  - [ ] 목적지 고리에 도착 방향 `facing_deg` 미반영
  - [ ] 15분 판 3연속 발열·배터리, 백그라운드 복귀(`ANDROID-DEV-NEEDS.md`와 함께)
  - [ ] 모바일 기본 밀도 값 확정(Q59: 높음 / 크기 유지, PC 보통) 반영 확인
  - [x] M10 실제 투영에서 코어 `heading` 0.1초 틱이 계단으로 보이는지 확인 — 틱당 최대 0.9°로 수치상 문제 없음(2026-10-07), 태블릿 눈 확인만 남음
  - [ ] 더 이상 읽지 않는 `assets/models/fleet_lod`·`user_ver3_runtime` 삭제 여부 결정
- [x] **전대·함대 그룹 지정 불가(태블릿)** — 구현·태블릿 확인 완료(2026-10-06, `SelectionSet`·[다중]·[1]~[5], 정의 `docs/ui/TOUCH-CONTROLS.md`). 원래 내용: 다중 선택(드래그 박스·추가 탭)과 그룹 번호 저장·호출 UI. 터치 48dp 기준, 선택 시 감속(Q31·Q36)과 함께 본다
- [x] **터치 드래그 시 카메라가 전장 밖으로 벗어남** — 고침·태블릿 확인(2026-10-06): `CameraRig.clamp_cam`이 화면 네 모서리를 전장 안에 둔다(전장이 화면보다 작은 축은 가운데). 원래 내용: 팬/줌 경계 클램프 확인
- [x] **함대 1개 선택 후 드래그로 목표 지정이 안 되는 경우 있음** — 새 끌기 규칙으로 해소·태블릿 확인(2026-10-06): 선택된 전대에서 시작한 끌기만 이동·공격, 그 밖에서 시작하면 무시. 원래 내용: 재현 조건부터 찾는다(팬과 목표 드래그 제스처 충돌, 선택 직후 첫 터치, 다중 터치 판정 의심). 위 그룹 지정 UI와 같은 입력 코드라 함께 본다

## 8. UI 추가 항목 (2026-10-05, 사용자 — 본편 대조 리뷰 완료 2026-10-09, 구현 전)
- [ ] **(대기열) 전투 전 편성 화면 + 전대 폐지(Q73~Q82, 2026-10-10)** — 분해 O0~O5와 인수 조건은 `BATTLE_DECISIONS.md` §T-1. **O5 UI 문구 완료(2026-10-10, `tests/ui_wording.gd`, 로컬 화면 확인 대기).** **O0 PC 측정 끝(2026-10-10): 현재 409척 73 FPS → 1,500척(1,523척, 표시 약 735) 31 FPS, 평균 32ms·최악 60ms(Intel Arc 130V, 1920×1071). 밀도 설정은 효과 없음(실제 함종 구성으로 그려 표시 수가 같다). 태블릿 실측 대기: 기기 미연결, 재현은 `tests/bench_density.gd`(`FleetBattle3D.profile_patch` 훅). **O0 판정(사용자, 2026-10-10): 30 FPS 기준 통과.** 태블릿 실측은 O4 화면 확인 때.** **O1 코어 편성 모듈 구현(2026-10-10, `core/battle/organization.gd`·`tests/organization_rules.gd`, autoresolve `--org auto`): 다른 모델 리뷰 + 사용자 승인 대기.** **O2 생성기·시나리오 구현(2026-10-10): fleet_groups 제거·함대 안 승계(부제독 → 참모, 그 함대만 60초 혼선)·Q82 함대 수 목표(cao_fleets + cao_last_fill_bp, 사용자 결정)·고속정 장비 유지·O1b #3 장비 "" 허용. 다른 모델 리뷰 + 사용자 승인 대기. 기본 경로(자동 편성 없음) 조조 비율이 2.36/3.27/4.17로 커짐 → O4가 흐름을 자동 편성으로, O3 기준선.** 다음 착수: O3 ∥ O4. 사양 `docs/ui/FLEET-ORGANIZATION-SCREEN.md`, 목업 `docs/ui/mockup-fleet-organization-v1.html`
  - [x] **렌더링 최적화(O0 후속, 2026-10-10, 세션 "렌더링 최적화: 1,500척 60 FPS")** — 프로파일 결과 병목은 함선 3D가 아니라 **2D 전술 오버레이**(`hud/ui_kit/tactical_overlay.gd`, 1,500척 프레임 33ms 중 약 17ms)였다. 함선은 이미 함종별 MultiMesh라 3D 렌더러를 숨겨도 프레임이 그대로였다. 고친 것: ① 파선을 반복 무늬 텍스처 띠로(`UiDraw._dashed_tex`, 오버레이에서만 `texture_repeat`로 켬 — 탐지 고리 2px 점 수천 조각이 2D 객체 2.7만 개였다) ② 바닥 고리 투영을 프레임당 행렬 하나로(`_proj_begin`) ③ 명패를 도형(삼각형 묶음 1회)·글자·아이콘 단계로 모아 그리기(그리기 호출 약 170개 감소) ④ 틱 없는 프레임은 `_pump`(투영 재생성) 생략 ⑤ 표현 계층이 있으면 숨겨진 POC 함대 `view3d.sync` 생략. 1,500척 프리셋(전후 번갈아 측정, 표는 `out/bench-density.md`): **PC(Arc 130V, 1920×1071) 34~37 → 67~89 FPS, 평균 27~30 → 11~15ms, 최악 43~57 → 34~55ms. 태블릿(SM-X736N, Mali-G925, 2560×1600) 61 → 119 FPS(120Hz 상한), 평균 16.4 → 8.4ms, 최악 35.5 → 32.9ms.** 409척 PC 75~79 → 100~132 FPS. 화면 전후 캡처 비교(점선·명패·지형·안개·오 세력) 동일
    - [ ] **(대기열) 최악 프레임 33ms 미달**: 틱 프레임의 `sim.step()`(코어)이 1,500척에서 틱당 평균 11ms·최대 약 23ms라 최악 프레임을 정한다. 코어 성능 작업(범위 밖)이 필요하다. 화면 쪽 나머지는 틱 프레임에 약 10ms
    - [x] **리뷰(Sonnet, `REVIEW-PERF-1500.md`) 조건부 수용(2026-10-10) → R1·R2 처리 완료(main 7004c1d에 병합: 겹친 명패 통째 그리기·선택 명패 마지막, 그리기 호출 약 560 → 608, `tests/ground_ring_proj.gd` 784점 비교):** R1 겹친 명패 그리는 순서(선택·조사 명패와 안개 접촉을 마지막에), R2 `_ground_ring` 투영 비교 테스트 → 최적화 세션에 요청. R3(POC 숨김이 presentation 의존)·R4(오버레이 texture_repeat로 글자 가장자리 번짐 가능)·R5(`_tri_fan` 임시 배열)는 낮음, 대기. 화면 확인 8항목은 리뷰 문서. 최악 프레임 33ms 미달(PC 34~55ms)은 코어 `sim.step()` 틱 비용(1,500척 평균 약 11ms·최대 약 23ms) → 코어 성능 대기열, **O3 1000시드 실행 시간에도 영향**
    - [x] 태블릿 재측정(2026-10-11, O2 시나리오 1,563척, main `e90dc7b`, 최적화 커밋만 되돌린 빌드와 번갈아 2회): 51~60 → 108~118 FPS, 평균 16.6~19.7 → 8.5~9.3ms, 최악 38~42 → 35~42ms(코어 틱). 표는 `out/bench-density.md`
    - [x] 태블릿 실측(2026-10-10): 위 수치. adb로 `--script`를 넘길 수 없어(GodotApp 비공개) 메인 장면을 벤치로 바꾼 임시 APK로 쟀다(커밋 안 함)
    - 밀도 설정(낮음·보통·높음)은 여전히 표시 수를 바꾸지 않는다(편성 있는 함대는 실제 척 수로 그린다는 리뷰 C-1 결정). PC·태블릿 모두 60 FPS를 넘어 그대로 둔다
  - [x] **O5 리뷰(Opus, `REVIEW-O5.md`) 조건부 수용 → 조건 처리(2026-10-10, 관리 세션):** #1 "서황 함대" → "서황 별군", 생성기에 "함대"로 끝나는 이름 금지 검사. #2 `command_deck.gd:730` "함대 %s"에 상위 묶음(`fleet_groups`) 이름이 들어가는 문제는 **O2의 `fleet_groups` 제거 때 그 라벨도 지운다**(O2 범위에 추가)
  - [x] **(O1b로 처리, REVIEW-O1b 수용 2026-10-10)** **O1 리뷰(Sonnet, `REVIEW-O1.md`) 조건부 수용 → 처리 방향(관리 세션) — 사용자 승인(2026-10-10), O1b는 O1 구현 세션이 진행:** **O1b ①~④ 구현(2026-10-10): `apply`가 검증 실패 시 `{"errors": [...]}` 반환, 새 사유 `missing_fleet`·`bad_fleet`(형식·비정수 count), 장비·중복 함종은 `bad_ship`, 참모는 apply에서 보직 순 정렬, 테스트 추가(`organization_rules` 약 3~6분). **O4c 리뷰(Sonnet, `REVIEW-O4c.md`) 수용(2026-10-12): 높음·중간 없음. 대기(낮음): repair 케이스 테스트 추가(전부 자동 대체·기함·중복·결정론), 전부 자동 대체 시 문구에 fallback 표시, 헤드리스 org_blocked 무표시, 종료 오버레이 "다시 출격" 막힘 시 숨김 로컬 확인, org_screen.gd:329 주석 +8→+9.** ① `apply`가 `validate`를 먼저 실행(잘못된 org·외부 재생 헤더 크래시 방지) ② 프로필에 있는데 org에 없는 함대·모르는 `mission_equipment_id`·중복 함종 항목·비정수 `count` 거부 ③ 테스트: 잘못된 org apply, apply 뒤 승계, 장수 부족, 동점 ID 순서, 끈 함대·자동 편성 전투 종료까지, 재생 지문 여러 시드 ④ 참모 배열 순서 = 승계 순서 = 보직 순서 강습 → 공성 → 보급(관리 세션 기본값). ①~④는 O1 후속(O1b), O4 착수 전에 끝낸다. **O2로 이월:** 함대 승계가 `fleet_groups[].vice_admiral`(옛 부제독)을 쓰는 문제(`command.gd:31-36`)는 `fleet_groups` 제거와 함께 함대 안 승계(부제독 → 참모)로 정리, 끈 함대의 그룹 소멸도 같이 사라짐. 조조 `count_factor` 무시·고속정 장비 RECON 고정도 O2(Q82 함대 수 목표)에서. 낮음: 제독 교체 시 레벨 1 리셋(Q62 레벨 정의와 함께), `traits` 얕은 복사
  - [x] **`ui_wording` 검사 보강(REVIEW-O5 #3~#5, 낮음)**: #3·#4 O4에서 처리(2026-10-10). #5 여러 줄 문자열은 대상 경로에 `"""`가 없어 보류(쓰기 시작하면 파일 단위 판정)
  - [ ] **O4 Godot 편성 화면 구현(2026-10-10, `hud/ui_kit/org_screen.gd`, `tests/organization_ui.gd`): 리뷰 완료(REVIEW-O4 조건부 → O4b, 아래), 화면 확인(PC·태블릿) 대기.** 흐름 브리핑 → 편성 → 전투, "자동 편성으로 시작" 건너뛰기(세 세력 자동 편성, Q83 사용자 확정). 한도 초과·미달은 경고만, 빈 제독·0척은 확정 잠금. 캡처 `out/org-*.png`
  - [x] **O1b 리뷰(Sonnet, `REVIEW-O1b.md`) 수용(2026-10-10).** #1 `tests/autoresolve.gd` `--org auto`에 `has("errors")` 가드 추가(관리 세션). 넘김: #2 apply 반환 규약(성공 = 사본, 실패 = `{"errors"}`)을 O4 호출부에서 지킨다. #3 장비 기준이 `detection.equip_sensor` 키라 빈 문자열 `""`(salvo.gd:44는 "장비 없음"으로 허용)과 새 장비를 거부함 → O2에서 처리(validate가 `""` 허용, 2026-10-10). #4 count 상한 없음(1e30), #5 기함 제독 가용 밖·count 누락 테스트 없음, #6 organization_rules 약 3분 40초 → 낮음, 대기
  - [x] **(사용자 승인 2026-10-11, O2+O2b 완료)** **O2 리뷰(Sonnet, `REVIEW-O2.md`) 조건부 수용 → 사용자 결정(2026-10-11): Q83 기본 경로 자동 편성, Q84 제한적 승리 = 유비군 출전 함대 전부 도달, 조조 함대 수 방식(cao_fleets 8/12/16 + cao_last_fill_bp) 확인.** O2b(O2 구현 세션): Q83 연결, Q84 + 테스트 4a 복구, 제안서 §4.1·§4.14 정정("함대 다섯", "부함장 전대가 새 기함", RC-LIU-FLT-01). **O2b 완료(2026-10-11): `Organization.auto_all(profile, scn)`·`load_auto(def, diff)`, 연결 = `FleetBattle3D.init_game`·`BattleBrief.profile()`(천하 지도 자동 해결). autoresolve 기본 `--org auto`(`historical` = 정사 편성). 기본 경로 비율 1.070/1.590/2.140/2.140(`data_rules`). Q84 `victory._alliance_escaped` = 유비군(anchor_faction) 출전 함대 전부, 4a 복구. 지문 테스트 갱신: `battle_flow` 재생 프로필 = load_auto, `roster` 함종 숫자 = 실제 편성(둘 다 기본 경로 변경에 따른 정당한 갱신). 다른 모델 리뷰 대기.** 낮음 대기: 결산·재생 로스터 조조 16함대 높이(약 1070px, O4 화면 확인), 고속정 장비 `""` 유지 의도, `cao_last` 배열 순서 주석, 비기함 승계 혼선 종료 테스트, O2 이전 재생 지문 호환
  - [x] **O2b 리뷰(Sonnet, `REVIEW-O2b.md`) 수용(2026-10-11).** #1(중간) `FleetBattle3D.gd:151,161` `load_auto`가 빈 사전이면 `profile.ally` 접근 오류 → O4에 빈 프로필 방어 요청. #5 SESSION-HANDOFF 모순 문구 정정(관리 세션). 낮음 대기: #2 `arrived`가 한 번 닿으면 유지(스친 뒤 이탈도 도달), #3 victory 4·4a가 정사 편성만(자동 편성·항복·끈 함대·손권 제외 단독 사례 없음), #4 battle_flow 재생이 기록 편성 대신 load_auto 재호출, #5 `BATTLE-CORE-HANDOFF.md:596`·`DATA-CROSSCHECK.md:181` 옛 문구, #6 autoresolve 기본 auto(정사 비교는 `--org historical`)
  - [x] **O4 리뷰(Sonnet, `REVIEW-O4.md`) 조건부 수용(2026-10-11) → O4b(O4 구현 세션):** **O4b 구현(2026-10-11): #1 거부된 편성은 `org_errors` → 시작·다시 시작이 편성 화면 + 사유(테스트 표준 → 극한), #2 ±는 카드·행 값만 갱신(헤드리스 ± 129ms → 8.3ms), #4 "진형 전환 시간 +8%", #10 카드 끌기 16px 문턱, 사양에 끌어 놓기 보류. 다른 모델 리뷰 + PC·태블릿 화면 확인 대기. 캡처 메인 `out/org-o4b-*.png`(16:10은 창 1071로 잘림).** #1(중간) `FleetBattle3D.gd:155-160` 사용자 편성이 apply에서 거부되면 경고 없이 load_auto로 바꿈 → 편성 화면으로 돌아가 사유 표시(전투로 넘어가지 않음). #2(중간) `org_screen.gd:288-309` 버튼마다 3열 전체 재구성(헤드리스 100~200ms) → 바뀐 열만 갱신. #4 한도 초과 문구 "진형 전환 −8%" → "진형 전환 시간 +8%"(사양). #10 함대 카드가 놓음 이벤트로 선택돼 스크롤 뒤 선택이 바뀔 수 있음 → 끌기 거리 문턱. 낮음 대기: #3 끌어 놓기 없음(목업도 탭-탭, 사양에 보류로 표시), 다른 함대 칸끼리 맞바꿈 불가, #5 키보드 포커스·가상 키보드, #6 출전 끄기 되돌리기 없음, #7 고속정 장비 선택, #8 문구 "유비군" 고정, #9 대상 강조. 캡처는 구현 worktree에만 있고 16:10 해상도는 실제로 안 찍힘(창 1061) → 태블릿 화면 확인 필요
  - [x] **O4b 리뷰(Sonnet, `REVIEW-O4b.md`) 조건부 수용(2026-10-11) → O4c(O4b 세션):** **O4c 구현(2026-10-12): F-1 가드를 `FleetBattle3D.org_blocked()` 한 곳으로(`_start`가 부름 → deck·구 오버레이·`_restart` 전부 막힘, 테스트 `_restart` 경로). F-3 `Organization.repair(org, profile, scn) → {org, changed}`(유비군은 사유 없는 함대 보존, 빠지거나 사유 난 함대만 `auto_fill(..., only)`로 채움, 손권·조조는 Q81대로 전부 자동, 고쳐도 검증 실패면 전부 자동). 편성 화면이 고친 편성으로 `b.org`·전장을 바꾸고 바뀐 함대를 알림(유비군 함대 이름 + AI 세력별 함대 수 + "나머지 유비군 함대는 그대로"). F-4 진형 전환 시간 1/(1−0.08t): +9/+19/+32/+47%(1단계 정확값은 8.7%라 반올림 9, 사양에 근사 표기). 다른 모델 리뷰 대기.** F-1 구 오버레이 "처음부터"·"다시 출격"이 거부 가드를 우회 → 가드 한 곳으로. **F-3 사용자 결정: 거부 시 유효한 함대는 보존, 빠지거나 맞지 않는 함대만 자동 편성으로 채우고 바뀐 함대를 알림, b.org 갱신.** F-4 진형 전환 시간 문구를 1/(1−0.08t)로(+8/+19/+32/+47%). 대기: F-2 게임 흐름에 난이도 변경 경로 없음(거부 경로는 테스트로만 도달, 난이도 연결 때 재확인), F-5 부분 갱신 동치 테스트, F-6 버튼 위 터치 스크롤, F-7 알림 한 줄 잘림
  - [x] **소리 기본값 끔(사용자, 2026-10-12):** 효과음·UI음·배경음악 음량 기본 0(`game_settings.gd`), 마스터 0.8 유지. 기존 `user://settings.cfg`가 있는 기기는 저장값을 그대로 쓴다(새로 깔거나 설정에서 끈다)
  - [ ] **(대기열) `tests/ui_flow.gd` "result screen" 부하 시 실패:** 종료 연출 `G.end_t` 1.6초를 `minf(0.05, delta)`로 깎아 32프레임 이상 필요한데, 테스트는 실제 시간 2.2초만 기다린다. 다른 Godot 측정이 돌 때 변경 없는 코드도 실패(2026-10-12 확인). 테스트를 프레임 수 기준 대기(또는 end 상태까지 대기, 상한)로 바꾼다
  - [x] **C1 지문 대조 리뷰(Sonnet, 관리 세션, `REVIEW-C1-FP.md`) 수용(2026-10-11)**: 7d588e8 대 4a497e3, 입문·표준·상급 × 시드 0~5 × 정책 5종 18판의 종료 지문·사건 해시·종료 틱/사유 전부 같음, 원본 로직 재구현 동치 검증(qualifying 742,960쌍 등) 불일치 0. 낮음: `_range_cap` 전제(사거리 보정은 지형 배율뿐)에 회귀 테스트 없음 → 사거리 보정을 넣을 때 동치 테스트 필수. **사용자 승인(2026-10-11), C1 완료**
  - [ ] **O3 진행 방식(사용자, 2026-10-11): 코어 성능 먼저 + 축소 착수.** 1,500척 자동 해결 1회 약 150초 → 1000시드×4난이도 PC 8병렬 약 21시간(추정). ① 코어 `sim.step()` 최적화 조각(C1, 결정론·지문 불변)을 먼저 연다 ② 그동안 O3는 난이도별 200시드 탐색 측정으로 방향만 잡는다 ③ 최종 1000시드 기준선은 C1 뒤. **O3a 축소(관리 세션, 2026-10-11):** 1,500척 판 1회 CPU 약 300초라 4난이도 약 17시간(추정) → 표준·입문 200시드, 상급 100시드, 극한은 O3b로, 정사 대조 난이도별 48시드
    - [x] **O3a 리뷰(Sonnet, `REVIEW-O3A.md`) 조건부 수용(2026-10-12) → O3a2 추가 측정(결정 불필요분):** 숫자는 원자료로 재현됨. F-1(높음) "하락 대부분은 편성"은 O2·Q84·P7·O4가 섞여 근거 부족 → 문구 낮추기(정사 7함대 제한 대조는 선택). F-2 `_main` 원자료 시드 0~24 덮어쓰기 유실 → 태그에 날짜·커밋. F-3 입문 11개 65~70%는 낙관적 → 11개(last_fill 2~3안)·12개를 시드 0~95에서 실측 비율과 함께. F-4 표준 목표는 화공 없음 → `--no-chain` 한 번, 조조 승에서 시계·동시 종료 분리. F-5 상급·극한 0%는 해상도 문제 → 공격 정책 각 48시드 + 화공 시도 정책으로 대리 지표 먼저. 신뢰구간 Wilson 통일. **사용자 결정은 측정 뒤:** 입문 레버(함대 수 = Q82 변경 / 시작 사기), 상급 구분 레버
      - **O3a2 측정 완료(2026-10-12, `O3A-BASELINE.md` §6, 커밋 49481c7, 5-b 조건부 수용 `REVIEW-O3A2.md`, G-1~G-7 문구 반영):** 입문 11·2500 63.5% · 11·5548 69.8% · 11·10000 61.5% · 12·5548 55.2%(실제 비율 1.43/1.47/1.53/1.60, 96판, 1.43~1.53 차이는 잡음 수준). 표준 `--no-chain` 연합 61.5%, 조조 29.2%(21.0~38.9) → 화공 없음 목표 60% **밖**. 상급·극한 attack/fire 2.1%/0%, 판 약 10분이라 기류 창(첫 명중 뒤 540~600초) 전에 끝나 화공 발동 0 → 이 설정에서 화공 시도 대리 지표 없음(`--wind` 앞당긴 측정, 창 시점 레버 3, 사람 플레이 중 택). F-1 문구 낮춤, F-2 태그 날짜·커밋, Wilson 통일. 결정 대기: 입문 레버, 표준 화공 없음 밖 처리, 상급 구분
    - **C1 완료(2026-10-11, 구현 세션) — Sonnet 리뷰 수용(`REVIEW-C1.md`, 반례 없음) + 지문 대조 수용(`REVIEW-C1-FP.md`), **사용자 승인(2026-10-11)**. 낮음(대기열): `supply.gd` 정렬 비교기가 `_prior`를 비교마다 전 함대 순회 → 정렬 전 캐시:** 결과 불변(시드 0~2 × none·attack의 autoresolve 행 전체 동일, tests 전부 통과)으로 자동 해결 1판 약 75초 → 21초(무부하 PC), 틱 평균 12 → 3.1~3.9ms, 최대 30~46 → 8~12ms. organization_rules는 668초 → 205초. 표·방법은 `out/core-perf.md`(git 무시 폴더, 로컬 기록). 변경: `salvo.qualifying` 거리 사전 차단 + 배열 없는 판정, 접촉 기록 한 번 조회(`_pick_target`·`sight_foe`), `BattleState.by_id` 색인, 보급 정렬 비율 캐시
    - **O3a 완료(2026-10-12, `O3A-BASELINE.md`, 탐색 200시드, 5-b 대기):** 자동 편성·무명령 연합 승률 입문 99.5% · 표준 43.0% ±3.5 · 상급 0/204 · 극한 0/104, 길이 16.1~16.7분(목표 안), 시계 종료 ≤4.8%. 표준은 목표 안, **입문은 너무 쉬움**. 레버 1회(입문 조조 함대): 10개 83.3% · 12개 55.2% → 후보 11개(Q82 입문 비율 변경 = 사용자 결정), 입문 시작 사기, 상급 16→14. 이전 정사 대비 표준 하락(98 → 78.8 → 43)의 대부분은 편성 쪽. 지금 코드의 `--org historical`은 비율 3.27배라 기준선이 아님. organization_rules 입문 2/3 패배는 연합 함대 2개를 끈 시험이라 밸런스 신호 아님(전체 편성 공격 정책 48/48 승). 측정 커밋 b93cbbb(표준)·cb787f8(나머지, 지문 동일 확인). O3b(1000시드)는 사용자 결정·Q63 구현 뒤 **O3a2 완료·리뷰 수용(5e40b9b). 사용자 결정(2026-10-12) Q85 입문 11함대, Q86 표준은 화공 켬 기준, Q87 상급·극한은 사람 플레이로 판단 → O6(생성기 입문 비율 반영) 진행, 사용자 상급·극한 플레이 확인 대기.** **O6 반영·확인(2026-10-12, c30088b): 입문 `target_cost_ratio` 1.47 → 11함대·채움 5589. 96시드 무명령 연합 승률 70.8%(Wilson 61.1~79.0), 길이 중앙 16.8분, 조조 사기 붕괴 70.8·연합 사기 24.0·유비 기함 4.2·동시 1.0, 시계 종료 0%, 비용 손실 연합/조조 20.9/26.7%, 실제 비율 1.470. O3a2 11·5548(69.8%)과 같은 범위(채움 5548→5589라 지문은 다름, 지문 일치 확인 안 함). 점 추정이 목표 50~70% 상한 바로 위.** **O3b·P8(Q63 슬롯)은 별도 관리 세션으로 이관(사용자, 2026-10-12). 편성 관리 세션은 O6·화면 확인까지만.** **편성 관리 세션 종료(2026-10-12): O0~O6 전부 완료·리뷰 수용, 태블릿 APK 368cdb9 설치. 남은 것 = 사용자 화면 확인(편성 화면 PC·태블릿, 종료 오버레이 "다시 출격" 막힘 시 숨김, O5 문구) — 문제 나오면 새 구현 세션.** **O6 교차 리뷰(Opus, `REVIEW-O6.md`) 수용(2026-10-12): 생성 JSON 바이트 일치, 채움 5589 산술·원자료 96판 재집계 일치, 헤드리스 4종 통과. 낮음(대기열, O3b 관리 세션): R-1 점 추정 70.8%가 목표 상한 0.8%p 위 → O3b 1000시드에서 재확인, R-3 summarize 시드 중복 무경고 제거.**
  - [x] **`view/fleet_render/battle_source.gd:47` `combat.formations` SCRIPT ERROR — O4에서 `combat.get("formations", {})`로 처리(2026-10-11)**(REVIEW-O5 #6, O5 무관, `rule_text` 실행 중 반복 출력·테스트는 통과)
> **읽는 법 (Q73, 2026-10-10).** 전대 개념은 폐지됐다. 이 절에서 **"전대"로 쓴 곳은 모두 "함대"로 읽는다**(조종 단위 = 함대). 원문 요구와 리뷰 기록은 이력으로 남기고, 바뀐 규칙은 항목마다 `정정` 줄로 붙였다.

> **본편 대조 리뷰 (2026-10-09, 컨셉·문서 세션).** 아래 항목마다 `본편 대조` 줄을 붙였다. 충돌 시 **사용자 요구가 우선**이고, 변경점은 `BATTLE_DECISIONS.md` §R(Q61~Q72 후보, 이전 값 이력 포함)과 `UPSTREAM-ISSUES.md` §G에 있다. 근거 표기: 본편 = `Seonghanji/` 기준 파일:줄, 이 저장소 = `docs/battle-core/` 기준.
> - **용어 매핑 (먼저 읽는다).** ① **(Q73으로 다시 씀, 2026-10-10)** 조종 단위는 모두 **함대**다. 전대 개념은 폐지됐고 지금의 전대 14개가 곧 함대다(`FleetState`). 내부 키 `squadrons`·`RC-*-SQ-*`·`FleetState`는 이 결정만으로 바꾸지 않는다. 상위 `fleet_groups`(5개)는 없앤다. 이전 값: "코드의 `FleetState`·UI 함대 = 본편 전대, §8의 함대 = `fleet_groups`, 규칙 항목은 전대로 편성 항목만 상위 함대로 읽는다" → 새 값: 함대 = 조종 단위 하나. ② 여러 함대를 함께 움직이는 것은 그룹 선택(`SelectionSet`, Q60)뿐이다. `fleet_groups`와의 혼선은 후자를 없애 해소한다. ③ **특수기술**은 본편에서 "특수 기술 N단계"(기술 트리, 2 화선·4 철쇄, 3·5 미정 - `docs/06-tech/map-ux-concept.md:281-296`, `docs/07-production/requirements.md:139`)를 가리킨다. 장수 개인 능력은 본편에서 **특성**(`characters.json` `traits`)이다. §8의 특수기술 = 장수 특성을 능동 발동으로 쓰는 것으로 정의한다(Q63 후보). ④ 본편 "참모"는 두 뜻이다: 클래스 「참」(참모형, 간파 판정) 대 함대 임무대장(강습·공성·보급). §8 "참모"는 편성 직책이다.
> - **2차 리뷰 (2026-10-09, Opus, 코드 대조).** 항목마다 `2차 리뷰` 줄을 붙였다. 근거는 이 저장소 파일:줄. 요지: ① 진형 미표시는 τ 문제가 아니라 화면이 **바뀌지 않는 POC `form_id`**를 쓰는 버그다. ② 무장 버튼은 범주 매핑이 틀렸고(함재기 = 전열 범주 전체) 대기 중에는 아무 효과가 없다. ③ 1차 리뷰의 "유지 거리 = 교전 거리대 하한 180"은 하한·상한을 뒤바꿨고, 화공 "120까지 접근 필수"는 과장이다(발동 240부터 가능). ④ 아군 겹침은 화공 번짐·호위 의심의 전제(아군 간격 110)를 이미 깼다. 결정 보강은 `BATTLE_DECISIONS.md` §R "2차 리뷰 보강".
> - **구현 순서 평가:** 대체로 타당하다. 다만 ⓐ 진형·무장 버그는 화면·명령 층이라 서로 독립이고, 정보 패널 진형 이름과 기존 사거리 원(480 고정값) 수정은 같은 원인이라 버그 단계로 당긴다. ⓑ 교전 거리와 겹침은 한 번에 넣고 1000시드를 한 번만 잰다. ⓒ 지형은 "기존 3구역 화면 표시"(규칙 무변경)를 앞으로, "통과 불가"(경로 탐색 신설)를 맨 뒤로 나눈다. ⓓ 회피 기동은 교전 거리 다음.


- [ ] **수리·보급 메뉴** — 보급함·수리함이 있을 때 수리 메뉴·보급 메뉴를 제공한다. 보급 레벨에 따라 보충·수리량이 달라진다
  - 본편 대조: 충돌 없음, 사용자 요구가 본편 규칙 위에 얹는 UI. 본편은 보급함(SHP-05) 수리 도크 2기·재고(`Seonghanji/data/red-cliffs-fast-craft-rules.json` `supply_inventory_contract`)와 보급대장(정치) 효과(`ship-specs.md:841`)만 정의하고 "보급 레벨"은 없다. 이 저장소의 보급은 영역 + 60초 정지 자동 처리다(제안서 §4.13, `M8-NOTES`). 요구 반영: "보급 레벨" = 보급함 처리량 단계(100/50/25%, 데이터) + 보급대장 정치로 정의(Q61 후보), 메뉴는 자동 처리를 수동 시작·우선순위 지정으로 바꾸는 층. 수동/자동 병행 여부가 미결.
  - 2차 리뷰: 1차 지적 맞음. 추가: 보급은 손님이 반경 140 안에 **정지**해 있어야 진행되고 움직이면 0으로 돌아간다(`core/battle/supply.gd:8-10`). 회피 기동을 코어 위치 이동으로 넣으면(Q72) 보급이 끝나지 않는다. "수리함"은 코어 함종에 없다(보급함 SHP-05가 겸함). 아군 겹침 허용(R1)은 보급에 유리하다(반경 안에 여럿이 설 수 있음).
- [ ] **장수 특수기술 UI** — 함대·전대에 소속된 장수들의 특수기술을 발동·확인하는 메뉴
  - 본편 대조: **용어 충돌 + 규칙 공백.** 본편에 "특수기술" 능동 발동 체계는 없다. 개인 능력은 특성이며 페이즈에 묶여 자동 발동한다(`combat.md:1279-1299` 표: 신기묘산 ①배치 1회, 만인지적 ④기함 진입 등). 쿨다운·사용자 발동 개념 없음. 시나리오 JSON은 이미 `traits`를 갖고 있다(예: 유비 인덕, 제갈량 신기묘산). 요구 우선: 특수기술 = 특성의 능동 발동형으로 두고, 발동 가능 특성만 목록화하는 Q63 후보. 이미 구현된 능동형은 화공(황개 고육계), 팔진 조건, 기함 진입뿐이다(제안서 §4.11·§4.7).
- [ ] **미사일 사거리 표시** — 함대·전대 선택 시 미사일 공격 범위를 전장에 표시
  - 본편 대조: 용어 불일치. 본편 함선표는 미사일을 무장으로 갖지만(`ship-specs.md` 포격함 미사일 160발) 거리는 광초(미사일 12)이고, 이 저장소는 광초를 폐기하고(Q37) **무기 범주별 사거리**를 쓴다: 포격 260(포격함)·150(공성함), 전열 190/180, 요격 210/200, 뇌격 170(제안서 §4.8 표). "미사일 사거리" = 포격 범주 사거리(+지형 사거리 배율 ×0.8~0.9)로 읽는다. 함재기는 사거리가 아니라 출격 횟수 자원이다. 표시는 범주별 링으로 하고 지형 안에서는 배율을 적용한 값을 보여야 한다(Q64 후보). 제안서 §7 L3 "도착 시 사거리 원"(제안서 :794, :817)과 합친다.
  - 2차 리뷰: **1차가 놓친 것 — 사거리 표시는 이미 있고 틀렸다.** 선택 시 `hud/ui_kit/tactical_overlay.gd:104-117`이 "광선 사거리" 부채꼴(±60°)을 `f.range_r`로, 미사일 파선 원을 POC 상수 `MISSILE_R` 480으로 그린다(`hud/fleet_labels.gd:9,54-55`도 같음). `range_r`는 모든 범주의 **최대** 사거리(포격함이 있으면 260, `core/battle/salvo.gd:251-256`)라 "광선"(전열 180/190)이 아니고, 480은 포격 260의 약 2배다. 사용자가 보는 원이 틀렸으므로 이 수정은 무장 버그와 같은 단계로 당긴다. 함재기도 사거리가 있다: 코어에서 함재기는 전열 범주의 강습모함 플랫폼(`line_fire@SHP-01`, 190, `data/profiles/combat_m3.json:110-118`)이다(1차 "사거리가 아니라 출격 횟수"는 반만 맞음). 지형 사거리 배율은 사격선이 지나는 구역으로 정해져(`core/battle/terrain.gd:64` `range_mul(a, b)`) 방향마다 달라 원이 아니라 다각형이다.
- [ ] **그룹 진형 지원** — 함대·전대 그룹이 지정돼 있으면 그 그룹 단위로 진형을 지정·적용(§7 그룹 지정 UI, M10 진형 탭과 연결)
  - 본편 대조: 충돌 없음. 본편 진형은 요구 통솔·팔진 조건이 **지휘관 개인** 기준이다(`ship-specs.md:742`). 호스트는 이미 ID 배열 명령을 받는다(`SESSION-HANDOFF.md:199` `BattleCommands.formation_to`). 남은 것은 그룹 안 일부가 거부될 때(통솔 미달, 팔진 조건, 전환 중)의 부분 적용 규칙이다. 전환 시간은 코드에서 30초 → 5초로 바뀌었다(`7ff07b1`, Q24 이력). 그룹 진형이 효과가 안 보이는 버그(아래)와 같이 본다.
  - 2차 리뷰: 부분 적용은 **이미 조용히 일어난다.** `formation` 명령은 일부만 성공해도 거부 사건을 내지 않고 실패 사유를 버린다(`core/battle/battle_sim.gd:485-496`, 전원 실패일 때만 `_reject`). 그룹 진형 UI는 전대별 실패 사유(투영 `form_info.block`)를 보여 줘야 한다. 진형 미표시 버그(아래)를 먼저 고치지 않으면 그룹 진형도 화면에서 확인할 수 없다.
- [ ] **행성 방어 지원(전투 규칙)** — 행성 주변 전투에서 수비 측은 행성의 무력 지원을 받는다. 행성의 군사시설이 적 세력을 공격한다. 규칙 결정(사거리·피해·시설별 차이·행성 점령 시 변화)은 `BATTLE_DECISIONS.md` Q번호로 남기고, 표시는 위 사거리 표시와 함께 본다
  - 본편 대조: **본편에 없는 규칙(확장).** 본편은 행성을 공략 대상으로만 둔다: 궤도 요새·행성 방어망은 공성함의 관통포로 열어야 하는 장애물(`ship-specs.md:309-314`, `combat.md:1272`, 공성대장 `combat.md:304`). 수비 측이 행성 화력을 받는 규칙, 시설별 사거리·피해는 없다. 적벽 데이터에도 행성은 `TRN-SHADOW-01` 행성 그림자(지형)뿐이고 행성 본체·군사시설은 없다(`red-cliffs-terrain-rules.json`). 따라서 **적벽 시나리오에는 적용 대상이 없다.** 범위 규칙(적벽만) 때문에 "규칙 틀 + 훗날 적용" 수준으로만 기록한다. 본편과 대칭이 되게 방어망 = 시설 화력, 공성함·공성대장 = 시설 무력화로 연결할 것을 제안(UPSTREAM G4, Q65 후보).
- [ ] **장수 통솔 레벨별 편성(규칙·UI)** — 장수의 통솔 레벨에 따라 전대 또는 함대를 구성할 수 있다. 전대: 전대장 1명 + 참모 2명. 함대: 제독 1명 + 부제독 1명 + 참모 최대 n명(보직별, n은 보직 수). 결정할 것: 통솔 레벨 기준값(전대/함대 구성 가능 조건), 보직 종류·n, 보직별 효과, 편성 UI. 수치 정본은 본편 `data\`에서 확인한다
  - 본편 대조: **부분 충돌(구성·직책).** (1) 본편은 통솔 등급 7단계(특급 95~ → 급외 ~39)로 **지휘 한도**(유지점)를 정한다(`ship-specs.md:761-769`). "통솔 레벨" = 이 등급으로 대응 가능(레벨 용어는 본편에 없고, 제안서 :614·:616 승계의 "레벨"은 :796의 레벨 삭제와 모순, Q62 후보). 편제 대응은 표의 비고뿐이고 "전대장은 훈련 담당, 선택 임명"(`ship-specs.md:813,874`)이라 **통솔로 전대 편성 자격을 막는 본편 규칙은 없다.** 실시간은 `40 + 통솔×2` 한도(시나리오 §2)라 한도 방식이 이미 다르다(UPSTREAM A1). (2) 전대 = 전대장 1 + 참모 2: 본편은 전대장 1명뿐, 시나리오 JSON은 `commander` + `vice_commander` + `staff[]` 3층이고 조조 중군은 부지휘관 허저 + 참모 정욱·가후(`SCENARIO-RED-CLIFFS-208.md:63`)라 **4명**이다 -> 요구에 맞추려면 부지휘관을 참모 칸 1개로 흡수하거나 상한을 3으로 조정해야 한다. 승계(제안서 §4.14)도 부지휘관 -> 첫 참모 순서다. (3) 함대 = 제독 1 + 부제독 1 + 참모 n: **본편과 일치.** 본편 함대 지휘부는 제독·부제독·임무대장 3(강습=무력, 공성=지력, 보급=정치, `ship-specs.md:814,835-841`) -> **n = 3**, 보직은 이 셋. (4) 시나리오 `fleet_groups`는 제독·부제독만 있고 임무대장 필드가 없으며, 제독이 전대장을 겸한다(유비가 본대 전대장). 직책명 불일치: 제독/도독(주유 수군), 부제독/부도독/부함장(제안서 :613·:635). 정리는 Q61·Q62 후보. **요구 우선 변경:** 전대 직책 칸 = 전대장 1 + 참모 2.
  - **정정 (Q73·Q74·Q75, 2026-10-10):** 편성은 한 단계다. **함대 = 제독 1 + 부제독 1 + 참모 최대 3(강습 무력·공성 지력·보급 정치)**. 데이터 대응 `commander` → 제독, `vice_commander` → 부제독, `staff[]` → 참모. 위 원문의 "전대: 전대장 1 + 참모 2 / 함대: 제독+부제독+참모 n" 구분과 본편 대조 (2)·Q61(a)의 부지휘관 흡수 권고는 **대체**(조조 중군 4명은 칸에 그대로 들어간다). 승계 = 부제독 → 참모. 편성 화면(Q75~Q77, 위 대기열 항목)에서 고친다. **미결 질문:** Q62(b) "제독 통솔 2급 이상" 구성 조건을 모든 함대에 적용할지(옛 전대는 제한 없음이었다).
- [ ] **편성별 특수기술 슬롯(규칙·UI)** — 함대는 제독·부제독·참모의 특수기술 중 최대 3개, 전대는 1개만 지원한다. 위 "장수 특수기술 UI"·"통솔 레벨별 편성"과 함께 본다. 결정할 것: 슬롯에 올릴 기술 선택 방식(고정/사용자 지정), 전대 참모 기술 제외 여부, 쿨다운 공유
  - 본편 대조: 충돌 없음(본편에 해당 규칙이 없어 요구가 신설). 일관성 점검: 함대 인원이 제독 1 + 부제독 1 + 임무대장 3 = 5명인데 슬롯 3개라 선택 필요 -> "고정/사용자 지정" 결정이 실제로 필요하다. 전대는 슬롯 1 = 전대장 특성(본편에서도 전대장만 임명, `ship-specs.md:813`)이라 자연스럽고, 전대 참모 제외가 본편과 맞다. 본편 특성은 인물당 1개가 대부분이라(`characters.json`) 슬롯 수와 인원수의 관계가 단순하다. Q63·Q66 후보.
  - **정정 (Q63·Q73, 2026-10-10):** 슬롯은 **함대 최대 3개** 하나뿐이다. 전대 슬롯 1(전대장 고정)은 폐지. 함대 인원이 최대 5명(제독·부제독·참모 3)이라 3개 선택(고정/사용자 지정)은 여전히 결정이 필요하다. "전대 참모 기술 제외"는 사라졌다.
- [ ] **(대기열, Q103 2026-10-14) P8d: 난이도별 적군 특기 수 조절** — 조조군 특기 수를 난이도에 따라 줄인다(낮은 난이도일수록 적게). 방식 후보: 난이도 프로필에 조조 함대당 특기 슬롯 수(예: 입문 0~1 · 표준 2 · 상급/극한 3) 또는 특기를 가진 조조 함대 비율. 생성기 `difficulty_policy`에 키를 두고 `Organization.auto_fill`이 조조 슬롯을 그만큼만 채운다. 연합은 그대로. 인수: `data_rules`(난이도별 값)·`special_skills`(조조 슬롯 수)·`organization_rules`, 입문 시드 0~95 켬/끔 대조. 위험 높음(밸런스) → 다른 모델 리뷰 + 기준선 전후 + 사용자 승인. 근거 `O3B-BASELINE.md` §3·`REVIEW-O3B.md` F-2(세력별 발동 수 기록을 `m9.skills`에 함께 추가)
- [x] **O3c: 측정 시작 시점 main 기준선 재측정**(2026-10-19 사용자 지시): `ac8b780`, 입문·표준 각 1000시드(0~999), 자동 편성·무명령·특기 켬. 입문 연합 71.9%(Wilson 69.0~74.6), 표준 조조 단독 65.6%(62.6~68.5), 중앙 길이 16.52/16.48분, 시계 0/0.8%. 원자료 400개 해시·2000판·독립 재집계 검증. **P8d는 미구현**이며 사용자 지시로 현행 상태를 먼저 측정했다. P8d 이후 재측정·상급/극한은 별도. 측정 중 추가된 `e17e295` AI 수정은 미포함. 상세 `O3C-BASELINE.md`.
- [ ] **(대기열, Q101 2026-10-13) 장수 특기 대상 직접 지정** — 지금은 코어 target_pick 기본값 + 길게 누르는 동안 미리보기. 사람이 대상 함대를 탭해 고르는 단계는 사람 플레이 뒤 필요하면
- [ ] **(대기열, Q90 2026-10-12: P8에서 뺌, 사람 플레이 뒤 재결정) 그룹 총사령·그룹 특수기술(규칙·UI)** — 그룹 구성은 함대+전대 혼합, 함대 여럿, 전대 여럿 모두 가능하다.
  - 총사령: 그룹 소속 리더(함대는 제독, 전대는 전대장) 중 통솔력+지력 또는 통솔력+무력 수치가 가장 높은 인물. 총사령의 함대·전대가 격침되거나 탈출하면 잔존 리더 중 최고 수치로 교체한다
  - 그룹 특수기술: 리더(전대장·제독)들의 기술 중 3개만 제공한다. 소속이 4개 이상이면 리더 능력치 높은 순으로 3개를 고른다
  - 결정할 것: 수치 식 확정(통솔+지력 / 통솔+무력은 둘 중 큰 값인지, 병종·역할별 선택인지), 동점 처리, 교체 시 UI 알림·특수기술 쿨다운 승계, 그룹 기술과 편성별 슬롯(위)의 중복·합산 관계
  - 본편 대조: **용어 충돌 위험.** 본편 "총사령관"은 세력 최고 지휘관(유비·조조)으로 승패 기함의 기준이다(`Seonghanji/docs/DECISIONS.md:103,105` V-74 3·5: 기함 자동 선정 1순위 = 세력 총사령관 전대, 전사·포로 = 즉시 승패). 그룹 총사령은 사용자 선택 묶음 안의 지휘 대표일 뿐이며 승패·기함·승계와 무관해야 한다 -> UI 문구에서 승패 기함과 분리 표기(요구 용어 "총사령"은 유지, 내부 키는 `group_lead`, Q66 후보). 본편에는 통솔+지력/무력 합산 개념이 없으나 스탯 역할(통솔=지휘 한도·초기 사기, 무력=강습, 지력=탐지·계략, `ship-specs.md:835-841`)과 모순되지 않는다. 한 인물이 제독이면서 전대장(유비 등)이라 그룹에 함대 + 그 기함 전대를 함께 넣으면 **같은 사람이 두 번 후보**가 된다 -> 중복 제거 필요. 그룹 특수기술 3개는 슬롯(위)과 별도 풀인지 미결.
  - **정정 (Q66·Q73, 2026-10-10):** 그룹 = 함대 여럿(`SelectionSet`). 총사령 후보 = **그룹 소속 함대의 제독**(전대장·제독 이분과 "함대+전대 혼합"은 폐지). 제독이 전대장을 겸해 두 번 후보가 되는 문제는 사라진다. 식·동점·교체 알림은 Q66 그대로. 그룹 특수기술 3 = 제독들의 기술 중 능력치 순.
- [ ] **전투 진입 시 초기 배치 선택(UI)** — 전투 화면에 들어갈 때 함대·전대 배치를 자동 배치 / 사용자 배치 중 고르게 한다. 결정할 것: 사용자 배치 허용 영역(아군 진입 구역), 배치 확정 버튼·제한 시간, 자동 배치 기준(진형·역할), 결정론 재생(`BattleSim.replay`)에 배치 입력을 기록하는 방법, 태블릿 터치 배치 조작
  - 본편 대조: **중복.** 이미 결정돼 있다. 제안서 §6.1 배치 단계(시간 정지, 진형·방침·프리셋·고속정 장비·허용 구역 안 초기 위치와 방향·함대 묶기, :733-739), 승인 카드의 "전 전대 수동" 토글(:859), 자동 해결 = AI 처리(:739). 본편 정본 "수동 배치" = 편성 편집기의 함종 구성·진형·좌표·함대 그룹(`demo-rc-qa04`, `demo-rc-g3-01`). 실시간에서 새로 정할 것은 "자동 배치 = 시나리오 `initial_position` 그대로"와 허용 구역 크기, 배치 입력의 `replay` 기록(M10 배치 화면 범위). 새 Q는 만들지 않고 M10 배치 화면에 흡수한다(Q70 후보는 허용 구역 수치만).
  - 2차 리뷰: 1차가 놓친 현재 상태: 전투는 이미 **일시정지로 시작**한다(`7ff07b1`, `scripts/FleetBattle3D.gd` `_start`의 `G.hold = true`). 지금의 "사용자 배치"는 정지 중 이동·방향 명령이고, 이 명령은 일반 명령이라 `replay` 기록에 이미 들어간다. 위치를 순간 이동시키는 배치를 넣으면 새 명령 종류(틱 0 전용, 허용 구역 검증)가 필요하다. 허용 구역은 플레이 전장 늘이기(1600×900 → 1700×1150, 가로·세로 배율이 다름, `core/battle/scenario_profile.gd:138-146`) **뒤** 좌표로 정해야 한다. 터치: 순간 배치는 끌기 규칙(선택 전대에서 시작한 끌기 = 이동, §7)과 제스처가 겹치므로 배치 단계에서만 끌기 = 배치로 바꾼다.
- [ ] **전장 지형·장애물(규칙·UI, 기록만)** — 전투 화면 전체가 항행 가능하지 않게 한다. 방사능 지역·소행성대·일반 행성 등 우주 공간의 대상이 전장에 존재하고, 함대 전투가 지형 제약을 받는다. 결정할 것: 지형 종류별 효과(통과 불가/감속/피해/탐지 방해/사격선 차단), 배치 방법(시나리오 정의/절차 생성), 경로 탐색·충돌 처리, 화공(적벽 시나리오)·행성 방어 지원·초기 배치(위 항목)와의 관계, 지형 표시·미니맵·터치 판독성, 결정론 재생·1000시드 균형 기준선 영향
  - 본편 대조: **부분 충돌(적벽 지형 정본 불변).** 적벽 정본 지형은 3구역뿐이며 모두 통과 가능한 비용형이다: 성운(x1.33), 잔해대(x1.54), 행성 그림자(x1.11)(`red-cliffs-terrain-rules.json`, 제안서 §4.10, `REVIEW-M6.md:54`가 일치 확인). 통과 불가·방사능 피해·행성 본체·소행성대는 본편에 없다(소행성대 ~ 잔해대로 매핑 가능, 방사능·행성 본체는 신설). 지형이 항행 불가가 되면 화공 접근(황개 접근점, 제안서 :533)·진형 슬롯·경유점이 영향을 받고 M6 일치 검증과 1000시드 기준선이 깨진다. **요구 우선:** 신규 종류는 "시나리오 정의 확장 종류"로 추가하되 적벽 기본 3구역은 불변으로 두고, 신규 종류를 쓰는 것은 차이 목록 B항에 등재한 뒤에만 켠다. Q67 후보. 본편 `terrain.json`은 전략 지도용이라 전장 지형과 독립(`red-cliffs-terrain-rules.json` statement).
  - 2차 리뷰: **1차가 놓친 것 — 기존 3구역이 화면에 안 그려진다.** `view/`·`hud/`에 지형 그리기가 없다(지형 참조는 `hud/ui_kit/formation_tab.gd`의 진형 허용뿐). 사용자가 "전장이 다 항행 가능"하다고 느끼는 데는 이것도 원인일 수 있다. 1단계 = 기존 3구역 표시(규칙 무변경, 기준선 영향 없음). 통과 불가는 **경로 탐색이 없어서** 큰 작업이다: 이동·AI 이동·화공 접근이 모두 직선이다(`core/battle/battle_sim.gd:896-905`, `core/battle/stratagem.gd:469-472` 황개는 바람 콘 안 직선 접근). 콘 안에 통과 불가 지형이 있으면 화공이 막힌다. M6 일치: 플레이 빌드는 전장을 가로 ×1.06·세로 ×1.28로 늘리며 지형 사각형도 함께 늘린다(`core/battle/scenario_profile.gd:145-146`) — 사거리·탐지 거리는 그대로라 플레이 화면의 지형·거리 비율은 이미 정본과 다르다(헤드리스 기준선은 원래 크기).
- [ ] **선택 함대 정보 패널(UI)** — 전투 화면에서 선택한 함대의 정보를 볼 수 있게 한다. 표시 후보: HP/CP 등 기존 HUD 수치, 이동 속도, 편성(제독·부제독·참모)과 특수기술, 진형, 사거리. 결정할 것: 표시 항목 우선순위, 패널 위치·크기(터치 48dp, 가림 최소화), 다중 선택·그룹 선택 시 표시, 적 함대 정보 공개 범위(탐지 상태), 기존 HUD(`hud/`)와의 중복 정리
  - 본편 대조: 부분 충돌(항목 중 CP, 적 공개 범위). (1) "HP/CP"의 CP는 폐지됐다(Q21): 상단 CP 바와 CP 명령 3종 삭제, 대체는 탄약·에너지·열(제안서 §4.8) -> 패널 항목은 선체/사기/열/탄약으로 읽는다. (2) 적 정보 공개 범위는 **이미 결정**: 확인 접촉은 이름·역할·초상·방향·전력 구간(4구간)만, 추정·상실은 마지막 위치·오차·신뢰도뿐이고 정확한 척 수·사기·선체는 비공개(제안서 :480). 본편 관측 3단계에서도 제독 이름은 "판독"에서만 공개(`screens.md:1094`)라, 편성(제독·부제독·참모)과 특수기술은 **아군만** 표시한다. (3) 정보 패널 진형 이름이 POC `FORM_NAMES`(`SESSION-HANDOFF.md:203`)라 7종 이름으로 교체 필요. (4) 다중·그룹 선택 시 표시 규칙은 §8 그룹 총사령 항목과 같이 정한다.
  - 2차 리뷰: 투영 경계는 지켜지고 있다(`core/battle/battle_projection.gd:82-108`, 확인 접촉도 함종·척 수·진형 비공개). 그러나 **화면이 가짜 정밀 값을 그린다:** 적 확인 접촉은 척 수를 `28 × 전력 구간/4`로 만들어(`view/battle_view_model.gd:269`) 정보 패널에 "21 / 28척"처럼 정확한 수로 보이고(`hud/ui_kit/command_deck.gd` `_info_single` 함선 막대), 진형 이름은 접촉의 `form_id` 기본값 0이라 모든 적이 "적 · 횡진"으로 나온다(`command_deck.gd:647`). 새 패널은 적에게 구간 표기(예: "전력 3/4")만 쓰고 진형·속도·사거리를 비운다. 적 사거리·속도를 보이려면 투영에 새 키가 필요하므로 공개 범위 결정(제안서 :480) 위반이다. 아군 진형 이름은 `formation_id`(투영에 이미 있음)로 바꾼다.
- [ ] **돌격함 없는 함대의 교전 거리 유지(전투 규칙, 기록만)** — 함대에 돌격함이 없으면 교전 중인 두 함대가 서로 거리를 유지한다(근접 돌입 안 함). 돌격함이 있으면 돌입·근접 가능. 결정할 것: 유지 거리 기준(사거리 비율/무기별), 양측 모두 돌격함 없을 때의 처리, 돌격함 일부 보유 시 전대 단위 적용 여부, 함대 겹침 허용 규칙과의 관계, AI·플레이어 이동 명령 충돌 처리, 1000시드 균형 기준선 영향
  - 본편 대조: **용어 부재 + 규칙 충돌.** 본편 함종 8종에 "돌격함"은 없다(`data/ship-types.json` SHP-01~08). 돌격 성격의 함종은 **강습모함**(SHP-01, 강습 계수 2.0, 강습정 16) 하나이고, 본편·이 저장소 모두 "강습은 강습모함 보유 + 강습 거리대 진입"이 전제다(제안서 :539, `combat.md` §6). -> 돌격함 = 강습모함으로 정의(신규 함종을 만들지 않음, Q68 후보). **충돌:** (a) Q28·Q42·제안서 §4.15 돌격은 **모든 전대**가 쓰는 접근 모드(열 40%, 사기 안정) -> 강습모함이 없으면 강습 거리대 접근 금지로 좁힌다(요구 우선, Q28 이력). (b) 거리 유지 기준: 기존 AI 거리대 대기 포화 240 -> 교전 170 -> 강습 100(제안서 :586)과 강습 거리대 80(:230,:539) 값이 다르므로 유지 거리 = 교전 거리대(전열 사거리 180/190) 하한으로 제안. (c) 예외 필요: 황개 화공대(뇌격 고속정, 강습모함 0)는 화공을 위해 120까지 접근해야 하고(:533), 요격 고속정 호표 고속대도 근접한다 -> 화공·뇌격은 거리 유지 예외로 명시. 강습모함 보유 전대는 시나리오에서 조조 중군(2)·조인 선봉(1)·주유 중군(1)뿐이라 연합은 거의 전 전대가 유지 거리 대상이다 -> 1000시드 기준선 재측정 필수.
  - 2차 리뷰: **(b) 수치 해석 오류.** 교전 거리대는 강습 80 초과 ~ 전열 사거리(180/190) 이하다(`core/battle/salvo.gd:264-272`). 180은 **상한**이지 하한이 아니다. 그리고 거리 유지는 코드에 절반 이미 있다: 표적 추격은 `최대 사거리 × 0.8`에서 멈추고(`core/battle/battle_sim.gd:853`, `chase_range_share` 0.8 → 포격함(260) 전대 208, 요격함(210) 전대 168, 전열(180)만 144), 근접을 만드는 것은 세 가지뿐이다: 돌격(추격 거리를 강습 80으로, `battle_sim.gd:854-855`), AI 거리대 일정의 마지막 단계 강습 100(`core/battle/ai/commander_ai.gd:166-178`, 데이터 `range_band_hold.assault_distance`), 이동 명령. 최소 구현 = 강습모함 없는 전대는 ① 돌격 거부(`battle_sim.gd:684` `_cmd_charge_salvo`·`salvo.gd:454` `charge_block`에 강습모함 조건, AI `_charge` `commander_ai.gd:245`도 같이), ② AI 목표 거리 하한을 기존 데이터 `engagement_distance` 170으로(새 상수 없이), ③ 적 근처로 가는 이동 명령은 유지 거리에서 멈춤. **(c) 예외 범위 과대.** 화공 발동은 240부터 된다(`trigger_range`, `data/scenarios/red_cliffs_208_realtime.json:1116`). 120은 위력 최대점일 뿐이다(240 = 0.25, 180 ≈ 0.33, 120 = 0.4, `core/battle/stratagem.gd:157-166`). 또 황개의 접근은 투항(휴전) 중 `ai_move`라(`stratagem.gd:421-473`) "교전 중" 규칙 밖이다 → 예외는 "화공 운용 전대의 투항·발동 접근"으로 좁힌다. 뇌격(170)·요격(200/210) 고속정은 사거리가 유지 거리 170 이상이라 예외가 필요 없다 — 1차의 "뇌격 예외"는 요구를 불필요하게 약화시킨다. **연합 쪽 유비군에는 강습모함이 0척**(`RC-LIU-*` 편성)이라 유비군은 돌격을 전혀 못 쓴다 — 사용자 확인 필요. **15~18분 목표:** 이것은 헤드리스(이동 ×1) 기준이다. 플레이 빌드는 이동 ×150·선회 ×15(`core/battle/scenario_profile.gd:131-136`, `7ff07b1`)라 이미 다른 체제다. 1000시드 재측정은 보류 중이다(`e50e017`).
- [ ] **진형 효과가 화면에 안 보임(버그, 사용자 보고 2026-10-09)** — 진형을 바꿔도 효과(대형 변화·보정)가 보이지 않는다. 원인 확인부터: 진형 전환이 시뮬에 반영되는지, 렌더 보간(§7 전대 그래픽)이 없는 건지, 효과 수치가 너무 작은 건지 구분한다
  - 본편 대조: 본편 쪽 충돌 없음. **문서 측 원인 후보:** 진형 효과는 대형 모양이 아니라 화력·방어·탐지·기동 % 보정과 노출 함종 배분이다(제안서 §4.7, Q34). 코어 전환 시간은 `7ff07b1`에서 30초 -> 5초(통솔 미달 60초 -> 5초)로 바뀌었으나 결정 문서가 갱신되지 않았다(Q24, 제안서 :105,:434, `FORMATION-TAB-SPEC.md:17`). 화면 쪽은 전환 시간을 코어 `form_left_s`와 별개의 τ 수렴으로 그린다(`REVIEW-FLEET-VISUAL.md:51`) -> 5초 전환과 3~4초 수렴이 겹쳐 "변화 없음"으로 보일 수 있다. 확인 순서는 위 항목 그대로(코어 반영 -> 렌더 -> 수치 크기).
  - 2차 리뷰: **원인 확정(코드), 1차 가설(5초 대 τ 3~4초)은 틀렸다.** 코어는 반영된다(`core/battle/salvo.gd:152-162` 전환 완료 시 `shape` 갱신, 투영 `formation` 키 = `f.shape`, `core/battle/battle_projection.gd:119`). 화면은 이 키를 읽지 않는다: 뷰 모델이 POC `form_id`(생성 순번, `core/battle/battle_sim.gd:223`)를 **처음 한 번만** 복사하고(`view/battle_view_model.gd:133`, 갱신 분기에 없음) `view/fleet_render/battle_source.gd:34-35`가 `form_id % 10`을 렌더러 `formation`으로 넘긴다. 그래서 `fleet_renderer.gd:628`의 진형 변화 검사가 영원히 거짓이다. 정보 패널 이름도 같은 `form_id`라(`hud/ui_kit/command_deck.gd:647`) 바뀌지 않는다. τ는 지금 0.3초다(`view/fleet_render/fleet_renderer.gd:46-50`, `REVIEW-FLEET-VISUAL.md:51`의 3~4초는 낡음). 수정 = 뷰 모델에서 투영 `formation`을 틱마다 갱신 + `battle_source`가 그것을 넘김 + 패널 이름을 `formation_id`로. 화면 층만 바뀌어 기준선 영향 없음. 추가 위험: 전환 5초가 생성기에는 30/60으로 남아 있다(`tools/scenario/make_combat_m3.py:189-190`). 다시 생성하면 되돌아간다.
- [ ] **무장 기본 기술(미사일·함재기) 선택이 적용되지 않음(버그, 사용자 보고 2026-10-09)** — 선택해도 발동·전환되지 않는다. 원인 확인부터: UI 입력이 명령으로 투영되는지, 시뮬이 무장 선택을 받는지, 사거리·탄약 조건에서 막히는지. 위 "미사일 사거리 표시"·"선택 함대 정보 패널"과 함께 본다
  - 본편 대조: **전제가 바뀌었다.** 미사일·함재기 명령은 CP 폐지(Q21)로 삭제됐고 무장 선택은 **무기 배분 프리셋(균형·장거리 집중·요격망 우선·근접 타격)**과 공격 보류로 대체됐다(제안서 §4.8 :459-462, 데이터 `red-cliffs-weapon-allocation-rules.json`). 그런데 `7ff07b1`이 "미사일·함재기" 메뉴를 되살리며 의미를 **일제사격 당기기**(다음 주기를 현재 틱으로, `salvo.pull`)로 바꿨다. 즉 UI 라벨 "미사일/함재기" != 배분 프리셋이고, 이 버튼은 자원(탄약·에너지·열·함재기 복귀)이 모자라거나 사격각/사거리 밖이면 쏘지 못한다(제안서 :456 보류 사유). "선택해도 적용 안 됨"의 문서 측 가설: 사용자는 모드 전환(선택)을 기대하지만 구현은 1회 사격 당기기다. 용어를 정하는 Q69 후보.
  - 2차 리뷰: 가설에 더해 **코드 결함 4개** 확인. ① 범주 매핑이 틀렸다: 함재기 범주 = `line_fire`(`data/profiles/combat_m3.json:110-118` `carrier.category`)라 "함재기"는 전함 광선까지 전열 범주 전체를 당기고, "미사일"은 포격·요격·뇌격 모두를 당긴다(`core/battle/salvo.gd:446-451`). 1차의 "미사일 = 포격"과 다르다. ② 대기 중에는 효과가 0이다: 표적이 없으면 다음 주기 시각을 미루지 않아(`salvo.gd:477-483`) 이미 "준비" 상태이고, 당기기는 아무것도 바꾸지 않는다. 사거리 안이면 60초 주기(`combat_m3.json:14`)로 어차피 쏜다. ③ 거부·피드백이 없다: salvo 규칙에서 `missile`/`fighter`는 무조건 성공 대사("미사일, 일제 발사!")만 낸다(`core/battle/battle_sim.gd:514-518`). ④ 버튼 재사용 대기 표시는 POC `missile_cd`/`fighter_cd`(salvo에서 늘 0)를 읽는다(`hud/ui_kit/command_deck.gd:987-991`). **Q69 전제 정정:** 무기 배분 프리셋은 코어에 구현돼 있지 않다(`core/`에 allocation 참조 없음, `combat_m3.json`에도 미포함, 원본 `data/scenarios/base/red-cliffs-weapon-allocation-rules.json`만 있음). "프리셋 UI를 따로 둔다"는 UI가 아니라 코어+데이터 작업이다. 사용자 요구("선택")를 살리려면 지속 모드(프리셋 또는 범주 우선)가 맞다.
- [x] **정찰 고속정 → 레이더 탐지 거리(전투 규칙, 기록만)** — 별도의 정찰 고속전대는 두지 않는다. 대신 함대 내 정찰 고속정 수에 따라 레이더 탐지 거리가 길어진다. 결정할 것: 수-거리 곡선(선형/체감/상한), 정찰정 격침 시 탐지 거리 감소, 탐지 상태 표시·적 정보 공개 범위(위 "선택 함대 정보 패널")와의 관계, 기존 탐지 규칙·본편 `data\` 수치 확인
  - 본편 대조: **충돌 있음(별도 정찰 전대 존재).** 시나리오가 "조운 정찰 고속정대"(`RC-LIU-FC-01`, 정찰 고속정 6척, 유비 연합 전단 소속, `SCENARIO-RED-CLIFFS-208.md:49`, `red_cliffs_208_realtime.json`)를 **별도 전대**로 두고 제안서 :212도 `RC-LIU-FC-01`을 별도 전대로 적는다 -> "별도 정찰 고속전대는 두지 않는다"와 충돌. 본편 데모 setup도 "유비 정찰 고속정대"(`RC-LIU-FC-01`)를 별도 전대로 두므로 **본편 정의와도 충돌**한다(요구 우선, UPSTREAM G3). 한편 정찰은 고속정 **임무장비**(`FAST-EQ-RECON`, 센서 6, EW 1)이며 한 전대에 장비 1종만 싣는다(`red-cliffs-fast-craft-rules.json` `mission_equipment`, `red-cliffs-sensor-ew-rules.json` `fast_equipment_sensor_points`). 요구 우선 변경: 조운 정찰 고속정대를 독립 전대에서 빼고 정찰 고속정을 유비 본대(또는 관우 수군) 편성에 흡수 -> 시나리오 편성·승계·기함 보호·사기 그룹 영향(UPSTREAM G3 제안). **"탐지 거리"도 본편에 직접 값이 없다:** 탐지는 점수 방식이며 `점수 = 센서 합x(1+진형%) + 지력 구간 - 표적 전자전 - floor(거리/25) + 지형`, 확인 >= 30, 추정 >= 15(제안서 :466-470)라 최대 거리는 파생값이다(센서 1점 = 거리 25). 정찰 고속정 수 -> 거리 곡선은 센서 합에 정찰 장비 점수를 척 수로 더하는 방식이 본편과 정합(현재 전대당 6점인지 척당인지 구현 확인 필요). 정찰정 격침 시 감소는 "현재 척 수로 계산"(제안서 :325,:484)과 일치. 진영 공유 탐지(Q46) 때문에 거리는 전대 개별이 아니라 진영 합성이다 -> "레이더 탐지 거리"를 전대별 원으로 그릴지 진영 합성으로 그릴지 결정(Q71 후보).
  - 2차 리뷰: **1차의 "구현 확인 필요"는 답이 있다: 척당이다.** `core/battle/detection.gd:80-83`이 정찰 장비 점수를 현재 고속정 척 수 × 6으로 더하고 시나리오 배율 3으로 나눈다(조운대 18척 → +36점 = 확인 반경 +900px 상당의 점수, 선형·상한 없음). 즉 "정찰정 수에 비례해 탐지가 늘고 격침 시 준다"는 코어에 이미 있다. 남은 결정은 곡선(선형 유지/체감/상한)과 편성 이동뿐이다. 편성 제약: 전대당 임무장비 1종(`f.equip` 하나)이라 정찰정을 흡수할 전대는 다른 장비 고속정이 없어야 한다 — 유비 본대(`RC-LIU-SQ-01`)는 고속정이 없어 흡수 가능, 황개 화공대(뇌격)·조조 중군(요격)은 불가. 탐지 원은 이미 아군 전대마다 늘 그려진다(`hud/ui_kit/tactical_overlay.gd:90-102`). 이 원은 표적 전자전·은폐를 빼지 않아 실제 탐지보다 넓게 보인다.
- [ ] **함대 겹침·돌격 규칙(전투 규칙, 기록만)** — 위 "돌격함 없는 함대의 교전 거리 유지"를 구체화한다.
  - 돌격함이 없으면 교전 중인 함대끼리 겹쳐서 싸우지 않는다. 아군 함대끼리는 겹칠 수 있고, 적 함대는 서로를 회피한다
  - 예외: 함대에 돌격함이 있고 함대 내 장수에게 돌격 기술이 있으면, 적 함대와 겹칠 때 돌격 기술로 적 기함에 타격을 줄 수 있다
  - 결정할 것: 돌격 발동 조건(수동/자동, 겹침 판정 거리), 기함 타격 피해·반격·쿨다운, 돌격 후 겹침 해소(관통/이탈), 돌격함 비율 기준, 기존 "함대 겹침 허용" 결정(적·아군 구분 추가)과의 정합, 1000시드 균형 기준선 영향
  - 본편 대조: 본편에 겹침 규칙 자체가 없다(2D 판정에서 거리·사격각만 사용, 충돌 처리 없음). 이 저장소 기존 결정은 **문서에는 없고** 코드·메모에만 있다: `7ff07b1` "겹침 반발 제거"(`battle_sim.gd:926` `_separate`는 이제 경계 클램프만)와 사용자 메모 "아군·적 함대 겹침 허용"(2026-10-09 오후). 이번 §8(2026-10-09 23시)이 이를 **수정**한다: 아군끼리 겹침 허용, 적과는 회피(돌격 예외). 이전 값(적·아군 모두 겹침 허용, 반발 없음)과 이력은 `BATTLE_DECISIONS.md` §R의 R1에 남겼고, 메모의 "적·아군 모두 허용"은 이번 요구로 낡았다. **중복:** "기함 타격" = 이미 구현된 기함 진입(호위 판정 뒤 무력 대결, 성공 시 표적 사기 -4000, 지휘관 보정 소멸, 제안서 :546)이며 전제는 강습모함 + 강습 거리대. 돌격 기술 = 본편 특성의 강습 페이즈 발동(관우 만인지적 "기함 진입 시 적장 단독 제압", 문앙 단기당천, 여포 무쌍, `combat.md:1292-1297`)과 동일 계통 -> 별도 기술 신설 대신 이 특성들로 한정하는 안(Q68 후보). 아군 겹침은 호위 반경 130 판정(제안서 :513)과 충돌하지 않지만 화면 판독성(명패·태그 겹침 `CHECKLIST-OPEN.md:68`)은 별도.
  - 2차 리뷰: **"호위 130과 충돌하지 않는다"는 틀렸다.** 130은 기함 호위가 아니라 황개 위장 항복의 의심 가산(반경 130 안 연합 전대 1개당 초당 +0.3, `core/battle/stratagem.gd:321-323`)이고, 제안서 :513은 "아군 전대 간격 110보다 커야" 걸린다고 **아군 간격을 전제**한다. 같은 전제가 연환 대형(제안서 :517, 120~180 간격, `core/battle/ai/commander_ai.gd:256` "가까워지는 쪽은 전대 간격 규칙이 막는다")과 번짐 반경 150에도 있다. `7ff07b1`이 지운 값은 `ally_gap` 110·`foe_gap` 90·`separate_k_ref` 4.0(`data/profiles/poc_corridor.json`)이고, 1000시드 기준선(`a937a5e`, 2026-10-05)은 이 간격이 **있는** 상태에서 쟀다. 아군 겹침 허용 = 조조 밀집 전대가 서로 붙어 번짐이 쉬워지고(화공 성공률 목표 27.4% 이탈), 호위 의심이 쌓이기 쉬움 → 이미 기준선 밖이다. **적 회피 구현 방식 위험:** 반발을 없앤 이유가 "튕김 방지"였다(`core/battle/battle_sim.gd:927` 주석). `foe_gap` 밀어내기를 되살리면 튕김이 돌아온다. 특히 플레이는 이동 ×150(전대 157~341px/초)에 AI 주기 550ms(`poc_corridor.json:26`)·여유 20(`data/profiles/ai_m7.json:39`)이라 한 주기에 90~190px 움직여 거리 유지가 진동한다. 회피는 위치 밀어내기 대신 **이동 단계에서 유지 거리 안으로 들어가는 걸음을 막는 정지 조건**으로 넣는다. 그룹 이동(Q60 `speed_cap`): 그룹 중 한 전대만 회피로 멈추면 대형이 갈라진다 → 그룹 단위로 함께 멈출지 정해야 한다.
  - **P3 구현(브랜치 `p3-weapon-charges`, 2026-10-10, 5-b 리뷰·기준선 승인 대기):** 미사일=포격 범주·함재기=`fighter` 범주(SHP-01만, 전열에서 분리), 기본 3회가 탄약·에너지·열을 대체, 자동 사격도 1주기=1회, 보급 영역 정지 완료마다 round(3×처리량) = 3/2/1회 보충(기지 3, 재고 소모 없음), 버튼 "n/3" 표시, 거부 사유 `missile_charges·fighter_none·*_no_target` 토스트. 데이터는 `combat_m3.json` `charges`(생성기 `make_combat_m3.py`). 1000시드 기준선은 바뀐다.
- [ ] **레이저 회피 기동(전투 규칙·연출, 기록만)** — 교전 중 적·아군 함대는 레이저 공격에 대해 회피 기동을 한다. 결정할 것: 회피가 명중률 보정(시뮬)인지 위치 이동(시뮬+렌더)인지, 레이저 외 무장(미사일·함재기)과의 차이, 진형·함종·속도별 회피 효율, 회피 중 이동 명령·교전 거리 유지(위 항목)와의 충돌, 결정론 재생·1000시드 균형 기준선 영향, 전대 안 개체별 흔들림 연출(§7 전대 그래픽)과의 연결
  - 본편 대조: 충돌 없음, 본편에 회피 개념이 없다. 사격 모델은 명중률 식(방향 +10/0/-15%, 진형 방어%, 지형 사격각)이라 회피를 명중률 보정으로 넣으면 기존 방향·진형 보정과 이중 계산 위험. 위치 이동으로 넣으면 결정론 재생(`BattleSim.replay`)·기동 명령·거리 유지·진형 슬롯과 충돌. 요구 우선으로 진행하되 "연출 전용(코어 판정 무변경) + 기동% 가산" 최소안을 먼저 제안(Q72 후보). 무장별 차이: 레이저(전열·요격)는 회피 대상, 미사일(포격 범주)·함재기는 유도/출격이라 제외하는 안.
  - 2차 리뷰: **"연출 전용"은 사용자가 준 선택지(명중률 보정 / 위치 이동) 밖이라 요구를 약화시킨다.** 1차 단계로 둘 수는 있으나 Q72는 두 선택지로 묻는다. 권고는 "명중률 보정(코어) + 흔들림(화면 전용)": 위치 이동을 코어에 넣으면 보급 정지 판정(`core/battle/supply.gd:8-10`)·도착 판정·거리 유지가 깨진다. 함정: 함재기가 코어에서 전열 범주(`line_fire@SHP-01`, `data/profiles/combat_m3.json:110-118`)라 범주 단위로 "레이저 회피"를 걸면 함재기도 회피 대상이 된다 → 플랫폼 단위로 강습모함을 뺀다. 이중 계산은 명중률 식의 방어항(`core/battle/salvo.gd:286-297` 진형 방어% + 방향)에 더하는 한 항으로 넣고 상·하한 클램프 안에 두면 막힌다.
- [ ] **§8 구현 분해 P1~P10와 진행 현황 (2026-10-10, main `dc5f209`까지)** — 사용자 결정(Q68·R1·Q69)과 조각별 의존성·위험도·5-b 기준은 `BATTLE_DECISIONS.md` §S. 착수 순서: P1·P2 → P3 → P4(1000시드 재측정 1회) → P5·P6a → P7·P9. 리뷰는 `REVIEW-P1/P2/P6A/P9A/P12.md`. 로컬 화면 확인 대기.

  | 조각 | 상태 |
  |---|---|
  | P1 진형 표시 | 병합 완료. F-1/F-2 해소(2026-10-13, p1-form-target, 전환 중 목표 모양 즉시·전환 시간 보간, `REVIEW-P1-FORM-TARGET.md`). 로컬 화면 확인 대기 |
  | P2 사거리 고리 | 병합 완료 |
  | P6a 지형 3구역 표시 | 병합 완료 (G-1/G-2 수정 포함) |
  | P9a 정보 패널 | 병합 완료 (F-1~F-3 수정 포함) |
  | p12 후속 정리 | 병합 완료 (F-1/F-2/F-4 수정 포함) |
  | P3 무장 자원화 | ✅ 병합(2026-10-11, bde6b11). 5-b `REVIEW-P3.md`. 표준 승률 98%→78~85% 수용, 자기 보급 금지+재고 소모. 후속: ~~재고 소모량 사용자 확인~~ 현행 확정(S-2 d), 1000시드 기준선 재측정 |
  | P4 교전 거리·겹침 | ✅ 병합(88b1f7d+). 5-b `REVIEW-P4.md` 수정 후 병합(H1·H2·T1·M1~M3 반영). AI 대 AI 지문 동일. 1000시드 재측정은 편성 후 한 번에. 로컬 화면 확인 대기 |
  | P5 회피 기동 | ✅ 병합. 5-b `REVIEW-P5.md` 수정 후 병합(H1 플레이 배율 보정·M1 아군 흔들림 `under_fire`·L3 도움말). 명중률 -최대5%p(bp_per_speed 130, max_bp 500, proposed, 사용자 승인). AI 대 AI 영향 ±1판. 로컬 화면 확인 대기 |
  | P9 후속(그룹 진형 표시·초기 배치) | ✅ 병합(2026-10-12, 995ed83). 반경=전장 짧은 변 15%(proposed), 방향 틱 0 즉시, 배치 중 적 표시 후속(L7). `SESSION-HANDOFF.md` "P9 후속". 로컬 화면 확인 대기(배치 막대·허용 원·터치 끌기). 5-b 수정 반영(`REVIEW-P9-FOLLOWUP.md`). **후속(대기열): 배치 중 적 표시** - 틱 0에 탐지 평가를 한 번 돌려 "탐지된 적만" 보여 줄지(코어 변경, 지문 영향 확인 필요, 사용자 결정으로 이번엔 안 함, L7) |
  | P7 수리·보급 메뉴 | ✅ 병합(2026-10-11). 5-b `REVIEW-P7.md`: 수동 명령 미사용 시 16판 지문·승패 동일, 공개 경계 통과. 후속: 보급함 처리 자리 1 유지 확정(S-2 c, 본편 SHP-05 정합은 O3a 뒤), F-4(먼저 지정 잔존)·F-5(결정 카드 겹침)·F-8·F-9(위임 중 AI)·F-11(_prior 성능), 로컬 화면 확인 |
  | P8 편성·슬롯·총사령 | **재분해 완료(2026-10-12, `BATTLE_DECISIONS.md` §U, Q88~Q91).** P8-0 특수기술 정의 → P8a 코어 → P8b 편성 화면 ∥ P8c 전투 UI. Q66 그룹 총사령은 대기열(Q90). Q62(b)는 D3로 닫힘. `fleet_groups` 제거는 O2에서 끝남. P8-0 ✅ 병합(2026-10-12, 41a4281, `SPECIAL-SKILLS.md`, 5-b `REVIEW-P8-0.md` 조건부 수용 → P8-0b 처리, Q92~Q95). P8a ✅ 병합(2026-10-12, P9 후속과 병합 뒤 special_skills·placement·data_rules·core_rules·roster·organization_ui·formation_ui·fog_ui·battle_flow·autoresolve 통과). 5-b `REVIEW-P8A.md` 조건부 수용 → P8a-b 처리, Q96~Q98. 표준 200시드 탐색: 특기 끔 42.5%(35.9~49.4) / 켬 38.0%(31.6~44.9), 길이 16.7~16.8분, 판당 발동 24.8회, 차이 유의하지 않음. 끔 42.5%는 O3a 자동 편성 표준 43.0%와 같다(78~85%는 O2 이전 정사 편성 값이라 P5 영향 아님). 미발동 기술: 일신시담·악래·호치·귀모·만인지적(유비 SHP-01 0척) → O3b 뒤 확인. P8b ✅ 병합(5-b `REVIEW-P8B.md` 조건부 수용 → P8b-b: refill_slots 단위 시험, 목록 2열; 칸 비우기는 넣지 않음, 직접 고른 칸 유지는 의도). P8c ✅ 병합(5-b `REVIEW-P8C.md` 조건부 수용 → P8c-b, Q99 길게 눌러 발동·Q100 위임 거부 시 유지·Q101 자동 대상+미리보기·Q102 결정 카드 중 숨김). **P8 구현 완료.** 남은 것: 로컬 화면 확인(PC·태블릿, 리뷰 문서 체크리스트). O3b ✅ 측정(2026-10-14, `O3B-BASELINE.md`, 5-b `REVIEW-O3B.md` 조건부 수용: 숫자 재현, 입문 하락 원인 = 특기, 단 P10 이전 시나리오) → Q103 P8d·O3c 대기열 |
  | P10 정찰 편성 이동(G3) | **P10 병합 완료, P10b 검증·5-b 수용(2026-10-16, `p10b-auto-scout`, 코드c471ee2, `REVIEW-P10b.md`).** RECON 정찰정 예약, 실제 연합 한도 기반 비용비1.470/1.590/2.139(±0.05), 조조9/10/14. 지정19종통과·boundary기존3/신규0, 표준4시드 전후·M2분리 완료. Android export·서명·검증 및 PC 화면 확인 완료. 태블릿 실기기 사용자 확인 완료(이상 없음). main 병합 완료(b9648f8). 구현gpt-6.1-sol/리뷰gpt-6-astra 실제확인. 원자료evidence/p10b-20261016. 행성 방어 지원 보류 |
  | P6b 통과 불가 지형 | 대기 (맨 뒤) |

  - 후속 (리뷰 발견):
    - ~~P1 F-1~~ 해소(S-2 a, 브랜치 `p1-form-target`, 병합 대기): 투영 `formation_to`·`form_to_pts`로 명령 즉시 목표 모양. 제안서 §4.7 반영
    - ~~P1 F-2~~ 해소(같은 브랜치: `FleetView.form`을 매 갱신 `form_to_pts`로 복사, `formation_display` 확인). F-3: 적 접촉 선택 시 패널 메타가 `"적 · "`로 끝남. F-4: 추정으로 떨어진 접촉에 마지막 "전력 b/B"가 남음
    - P2 F-1~F-3: 광선 고리가 탐지 확인 고리와 같은 색·실선, 지도 "미사일/광선" 대 패널 "포격/직사" 용어 불일치, 이름표 11px·배경 없음. 하위 사거리(공성함 150·요격 200)와 지형 사거리 배율은 미반영
    - P6a G-3(중간): `tactical_overlay.gd`가 코어 상태(`battle.sim.terrain`)를 직접 읽는다 → 지형 구역을 투영으로 옮기고 `_detect_rings`도 함께. G-4~G-8: 겹친 구역 이름표 위치, 이름표 화면 안 clamp, 필터(`move_cost_bp > BP`)와 구역 효과 요약(P9a 쪽), 배경 그림과 구역 위치 불일치(P6b), 테스트 동어반복
    - P9a F-4(중간): 적 접촉에 렌더러 난수 "가짜 편성"을 표시. ~~F-6~~ 닫힘(S-2 b): 마지막 이름·초상 기억 표시, 제안서 정정 완료. F-8(중간, 요구): 특수기술(traits) 표시
    - p12 F-5: 확인 고리 파선의 성능 → 태블릿 FPS 확인
    - `tests/boundary.gd`(`battle_source.gd` `BattleRules.BP`)는 병합 전 main에서도 실패하는 기존 문제다
- [x] **tests/organization_rules.gd 확인 요청(2026-10-11, P3 병합 뒤)** — 병합한 main에서 580초+ 제한에 걸려 끝나지 않고, P3 없는 origin/main(22f7e81 이후)에서도 70초에 rc=1이다(통과 문구 없음). P3 리뷰 때(main bd7a47b+P3 병합 트리)는 통과했으니 O2 변경 이후이거나, P3로 전투가 길어져(11.5→13.4분) END_MAX 30000틱 시험이 느려진 것일 수 있다. 편성 세션(O2·O4)이 두 경우를 구분해 달라.
  - 확인(관리 세션, 2026-10-11, main ce73d0e = P3 + O2b): **`--import` 뒤 통과(ORGANIZATION_RULES_OK, rc 0), 668초.** 실패가 아니라 느린 것이다. 대부분이 `_to_end`(입문, 세 세력 자동 편성 약 1,500척으로 3시드 전투 종료 + 재생 = 6회 전투)다. 22f7e81에서 70초 rc=1은 새 `class_name`(Organization)이 클래스 캐시에 없을 때 나는 파싱 오류로 보인다(REVIEW-O1 참고, `--import` 먼저). 처리: 게이트 시간 제한을 900초로 잡거나, C1(코어 성능) 뒤 다시 잰다. ~~밸런스 신호: 입문·공격 정책 연합 사기 붕괴 2/3~~ → **신호 아님(O3a 확인, 2026-10-12):** `_to_end`가 연합 함대 2개(RC-LIU-SQ-03, RC-SUN-SQ-02)를 끈 편성이라 약하다. 같은 정책을 전체 자동 편성으로 돌리면 48/48 승
- [x] **(2026-10-13 S-2로 ①②③ 완료, ④⑤ 확정: 처리 자리 1 유지, P3 소모량 현행. 구현은 `p1-form-target` 병합 대기) 사용자 결정 7건 반영 후속(2026-10-11, BATTLE_DECISIONS §S-1)** — ① 제안서 :480(추정·상실 이름·초상 기억)·§4.7(전환 진행 표시) 정정 ② 진형 전환 목표 모양 투영 키 구현(P1 F-1 해소, 구현 세션) ③ ~~특수기술 슬롯 자동 고정+편성 화면 교체는 P8 재분해에 반영~~ → 반영(§U P8a·P8b) ④ 처리 자리 본편 정합은 O3a 뒤 재검토 ⑤ P5는 Q72 기본값으로 진행 가능(P4 뒤)

- [ ] **P4 후속(낮음, REVIEW-P4)** — 측면 스침 이동도 명령 전체 취소 / 막힌 함대가 같은 그룹 다른 함대 이동 명령 삭제 / 강습모함 없는 함대도 돌격 버튼이 활성으로 보임 / `decision_flow` emphasis volley 부하 시 불안정 의심(병합 후 무부하 통과) / 정지 토스트 쿨다운은 data_rules 리터럴 금지로 뺌(명령 취소 시 1회)

- [ ] **P5 후속(낮음, REVIEW-P5)** — M2 흔들림 조건이 코어 회피 조건과 다름(정지·포격 표적도 흔들림) / M3 서서 교전 시 회피 0(설계, 사람 기동 시 영향은 스크립트 이동 장면으로 별도 측정) / L1 편성 속도 기준(speed_cap·지형 감속 미반영) / L2 `moving`과 보급 정지 기준 차이 / L4 흔들림 폭 0.9 화면 확인 / 강습모함 표적도 회피 받음(:705 해석 확인) / 1000시드 재측정은 편성 후

### P10b 완료 기준 (2026-10-14, 비용비 우선 사용자 결정)

- [x] 중단 worktree의 staged/unstaged 변경을 확인·보존하고 실제 연합 한도 기준으로 복구, Q82 보충 기록.
- [x] 정찰(RECON) 고속정만 시나리오 수부터 예약, 어뢰·요격 고속정의 기존 자동 편성은 유지. 보강 organization_rules 재통과, 최종 생성 JSON SHA-256 재현 일치.
- [x] 최종안 20종 단독 순차(2026-10-16, 19종 PASS/OK·exit0, boundary 기준선과 같은3건/신규0): battle_flow, data_rules, organization_rules, roster, smoke, succession_rules, victory_rules, detection_rules, organization_ui, special_skills, core_rules, fog_ui, formation_ui, world_link, hold_distance, commander_ai, stratagem_rules, supply_rules, ui_wording, boundary(기존 대비 신규 0).
- [x] 표준 자동 편성 AI 대 AI 시드 0~3, none/attack 전후 재측정. none 1/4→1/4, attack 0/4→2/4, 지문8/8변경. 원자료 `evidence/p10b-20261016/`, n=4로 승률 결론 내리지 않는다.
- [x] M2 예약 off/on×none/attack×4시드·120초, 다른15함대 동일. 1초 확인 대상1→5개, 발생 자체는 예약 없이도 있음. 유비 MIX 대체 포함·1초 관측 한계 기록. 비용비 ±0.05 유지.
- [x] Android export·서명·APK검증(종료0, 87,339,336bytes), PC 편성/시작직후레이더 캡처·직접검토 완료. APK·PC 이미지 근거는 evidence/p10b-20261016.
- [x] 태블릿 실기기 편성·정찰18척·레이더·초기안개/접촉: 사용자 직접 "태블릿에서 확인했고 이상 없음"(2026-10-16). 자동 측정·성능 수치로 주장하지 않는다.
- [x] 독립 다른 모델5-b `REVIEW-P10b.md`: F-1 수정 재시험 통과, Android·PC·사용자 태블릿 확인으로 필수 조건 충족. 리뷰 수용 후 병합 가능.
- [x] Q82·SESSION-HANDOFF·REVIEW-P10 대응·CHECKLIST 결과/남은조건 갱신. O3b 중복 없음, P6b 미착수(마지막·착수 전 사용자 한 줄 확인).

## 9. 함대 기동 PoC 본 게임 적용 (2026-10-18, 계획 `PLAN-POC-APPLY.md`)
- [x] A 이동 늘림(STRETCH) 제거 (fleet_follow·fx_follow_formation PASS, formation_display는 헤드리스 폰트 오류로 변경 전에도 실패)
- [x] B 접적 평행 이동·도착 후 진형 정렬·제자리 반전(코어, Q105·Q106, flip_rules PASS, 기존 테스트 회귀 없음. 남음: 1000시드 재측정 → 대기열, PC 화면 확인)
- [x] C 가시 범위·정찰 레이더(코어, Q107 병용, view_range PASS, 회귀 없음. 선택 함대 가시 영역 그리기·1000시드 재측정은 남음)
- [x] D 적 AI 교전 거리·물러나지 않기 (Q108, commander_ai PASS. 1000시드 재측정은 대기열)
- [x] E 묶음 진형 재배치 (Q109, bundle_layout PASS. 남음: 중첩·통째 회전·여러 줄 접기 후속)
- [x] F 마우스·터치·줌 차이 보정 (이미 있는 것 외 +·−·Home 줌 키만 추가, mouse_input PASS)
- [ ] G 문서·PC 화면 확인 완료, 1000시드 재측정은 O3c 입문·표준 완료(2026-10-19). 다른 모델 리뷰·태블릿 확인 등 남은 항목은 유지.

- [x] **방공·함재기 대응 규칙 구현·main 반영**(2026-10-19, Q112·Q111): 함재기·미사일에 비율 기반 방공, 아군 함대별 자동 대응 기본 꺼짐·적 켜짐. 적 규모 검토 및 입문·표준 각1000시드 측정 완료. 수치는 proposed 유지. 독립 리뷰·실기기 및 특화 편성 보존은 아래 후속 참조.

### 방공·대응 발진 진행 (2026-10-19, feature/air-defense)

- [x] 사용자 결정: 이번 범위는 방공·대응 발진. 방공은 함재기·미사일만(뇌격 제외). 플레이어 함대별 자동 대응 켜기/끄기, 기본 꺼짐; 적 기본 자동. Q112·Q111.
- [x] 구현: 비율 기반 방공(제안값·상한 15%p), 다음 틱 대응 1회, 연쇄·같은 틱 중복 방지, 무장 탭 설정·상태·설명.
- [x] 기능·회귀 16종 PASS/OK(exit 0), 실제 버튼 켜짐/꺼짐 왕복, 편성 3시드 종료·재생 지문 일치, 생성기 설정 일치. 상세 `AIR-DEFENSE-VALIDATION.md`.
- [ ] 자동 편성의 특화 함대 개성 보존: 별도 범위로 보류(황개·조순), 비용비·난이도 재검토 필요.
- [x] O3c 입문·표준 각 1000시드 밸런스 재측정 완료, main 반영(`ac8b780`). 결과·원자료 검증: `O3C-BASELINE.md`.
- [ ] 다른 모델 독립 리뷰·PC 외관/태블릿 확인은 남음.

- [ ] **후속 기준선 범위:** O3c는 `ac8b780` 고정 측정이며, 측정 도중 원격 main에 추가된 `e17e295` AI 수정의 밸런스 영향은 미측정. AI 변경 안정화 후 필요 시 별도 고정 커밋으로 재측정한다.
