# P07 첫 PC 작전 읽기 근거

2026-11-09 · 작업 트리 정적 대조 · HEAD `0be09755b70378286105972f35ac5b7031715664`. P07 전용 문서 근거이며 제품 시험은 미실행이다. 행 번호는 읽은 원본 기준이다. [계획](P07-PC-FIRST-OPERATION-PLAN-20261109.md)

## 결정·입력 추적

| 근거 | P07에 전달하는 내용 |
|---|---|
| [통합 체크리스트 §0/P05/P07](SESSION-REQUIREMENTS-CHECKLIST-20261031.md#0-현재-실행-순서--2026-11-09-사용자-승인) 9~28·100~102행 | 첫 PC 경로를 먼저 인수하고 같은 규칙 버전 저장·재개는 뒤에 둔다. 실제 공간·가동 보급·시간 증원·결과까지 제품에서 연결해야 한다. |
| [H0](H0-DECISION.md) §1 · [H1 정책](H1-POLICY-DECISION.md) §1 · [H1 사건](H1-EVENT-DECISION.md) §1 | 단일 성계/보급로 개방/정면·우회/시간 증원. 현재 통제·가동, 동일 점령자·소유상태 중단량 보존, 명시 철수와 동시 지휘 상실 우선. 시한과 동일 논리시각의 유효 달성 인정. 통신소 동시 출발/시한 연장과 유한 정비는 승인된 후속 방향. |
| [D05](D05-MISSIONS.md) §2~5 · [D06](D06-OBJECTIVES-MORALE.md) §2~5·8 · [D07](D07-SUPPLY.md) §2~4 · [D08](D08-EVENTS.md) §2~6·8 | 지정 수비·구원 임무와 관측 입력, C01~C06 및 O-WIN/O-WITHDRAW/O-FAIL/O-ACTIVE, R01~R07 및 S01~S07의 공급원/작업/거래 분리, 예정·출발·진입·도착·효과 및 동시 경계. 세부 제안과 채택 결정의 우선순위는 H0/H1 원본으로 확인한다. [H2-03](H2-DECISION.md) 13·30행이 후속으로 자기 시설 상실 보고·상대 시설 마지막 확인·적 재고 비공개·필수 일정 공지를 채택했다. 앞선 IP1 미채택 표기는 이력이다. |
| [P05 native 결과](P05-PC-NATIVE-ACCESS-RESULT-20261109.md) · [독립 검토](REVIEW-P05-PC-NATIVE-ACCESS-RESULT-20261109.md) | 동일 manifest SHA-256 `223eb53c920bd7bd8662962c0196ee2e02056962636ed4306725439d94c48ecd`로 Windows 자동 렌더·headless 각각 19/19, exit 0. 독립 headless도 19/19, 추가 연속 swept 반례 검증. E 진입·귀환, 정면 E–J–A–C와 우회 E–J–B–D–C, A/B 정지·서비스 영역, R 배치·C 접근이 격리 증거다. 고정 C 수비 외곽과 정지 후 회전·직선 보간 경로. 활성 공급원·거래·시간 증원·제품 결산·실제 OS 입력의 증거는 아직 필요하다. |

## 현행 동작과 신규 책임

| 범위 | 원본 경로·행과 실제 동작 | 첫 작전에 연결할 차이 |
|---|---|---|
| 보급 초기화 | [BattleSim](../../../core/battle/battle_sim.gd#L77) 77~78행 combat.supply가 있을 때 SupplyCore 생성. [SupplyCore](../../../core/battle/supply.gd#L24) 24~41행 주기·정지 오차와 설정 기반 정적 기지/진영 및 보급함 재고 초기화. 115~155행 공급원 key·범위/정지/진영·동맹·잔여 작업 검사. | 점령/가동·경합/소유 epoch와 현 재고에 연결한다. 가동을 거치지 않은 정적 A/B를 공급원으로 넣으면 안 된다. P05 기하와 서비스 적격 판정을 따로 책임진다. |
| 보급 시작·중단 | [SupplyCore](../../../core/battle/supply.gd#L158) 158~230행 보급함 손실 재고 조정·정지 검출, 기존 배정 유지 또는 `sup_src=""`·진행 0, 빈자리 정렬·자동 배정, 처리량 누적과 주기 완료. 372~383행 수동 우선/중지 명령은 보급함용. 296~307행 경파 자연회복은 영역 없이 독립. | 점령 진행 보존과 서비스 주기 중단은 다른 계약이다. 시설 가동중단·epoch 변경으로 이전 주기 권리 해제, 승인 후 미완료 자원 처리. 선행 효과를 따로 기록하여 경파 회복이나 우선보급 명령을 시설 서비스로 오인하지 않는다. |
| 보급 지출·완료 | [SupplyCore](../../../core/battle/supply.gd#L245) 245~293행 일반탄약·사용횟수·중파수리·재적재가 완료될 수 있으며 `g` 보급함에서만 차감, 정적 기지 `g == null` 경로는 원천 지출 없음. `supply` 완료 사건에 src·ammo·charges·repair·reload. | 거점 유한 일반 탄약/물자 장부와 지급의 원자적 완료, 실패/중단 및 중복 방지 필요. 기존 기지의 자유 보급은 캠페인 근거로 집계하지 않으며 기존 프로필은 보존한다. |
| 논리시계·증원 | [BattleSim](../../../core/battle/battle_sim.gd#L923) 923~989행 바깥 tick과 하위 걸음에서 증가하는 `st.clock_ms`; strict `>` 임계 후 증원. 모듈 단계는 첫 하위 걸음, no-Victory 섬멸 분기는 예정 전 즉시 생성 가능. 218~257행 프로필 위치에 진영 1 함대 생성, `st.reinf/reinf_ms`, `spawn` 및 `reinforcements`. 214~215행 공통 사건에는 tick만 기록. [ScenarioProfile](../../../core/battle/scenario_profile.gd#L108) 108행 적벽 reinf 빈 배열. | 단일 예약 ID와 하위 논리시각, R 외곽/경계 재검사, 진입 대기→실제 진입 커밋·후속 이동·표시가 필요. 조기 섬멸 대체 경로는 해당 캠페인에서 사용하지 않는다. 전역 순서와 임계 확정은 별도 정책이다. |
| 수치 정본 | [적벽 프로필](../../../data/profiles/red_cliffs_rt.json#L4) 4~13행 POC base 및 combat_m3 정본 참조. [combat_m3](../../../data/profiles/combat_m3.json#L871) 701행 적벽 시한, 871~927행 보급 설정, [POC corridor](../../../data/profiles/poc_corridor.json#L28) 28행 기존 증원 임계. | 정본의 단위와 지원 로직 재사용은 후보. 기존 적벽/POC 값은 P07 일정·비용·범위 채택을 입증하지 않는다. P05 manifest 서비스 영역과 기존 정적 기지 반경도 별도 입력이다. |
| 목표·철수 | [Victory](../../../core/battle/victory.gd#L79) 79~136행 기함·비용·섬멸·군 사기 및 기존 Q84 전원 도달 제한승리, 설정 주기·시한. 139~165행 `st.result` 및 `_end`. [BattleSim](../../../core/battle/battle_sim.gd#L608) 608~620행 `withdraw`는 chain 책략, 664~683행 `retreat`는 전대 명령. [Morale](../../../core/battle/morale.gd#L58) 58~66·169~182행 사기/명령에 따른 탈출 구역과 non-flag 제거. [BattleSim](../../../core/battle/battle_sim.gd#L1215) 1215~1223행 종료 상태·논리 tick/ms·battle_end 게시. | C 점령+현재 아군 가동 시설, 명시 철수 모드+E 실제 생환·확보 이력·N/D, 동시 경계와 세 가지 terminal 종류가 신규 작전 판정이다. 국지 `retreat`, 계책 `withdraw`, 단순 UI 복귀, 기존 Q84를 재명명해 대체하지 않는다. |
| PC 실제 진입과 진행 | [WorldMap](../../../view/world/world_map_screen.gd#L540) 540~569·588~598행 brief 생성, direct 분기. [WorldLink](../../../scripts/world_link.gd#L18) 18~35행 장면 이동·결과 보관 및 인수. [FleetBattle3D](../../../scripts/FleetBattle3D.gd#L176) 176~183·270~345행 준비/게시, raw BattleSim·초기 두 시계·사건 drain. 478~505·529~535·545~567·584~607행 frame·headless 보조 전진, side 0 투영·사건 및 명령. | P02 제품 준비와 게시 위치를 공유하며 동일 P03 작전 owner에 전진·명령·투영·결산이 배선되어야 한다. 자동 resolver/worker는 첫 직접 PC 조각 밖이다. |
| PC 표시·결산 | [BattleProjection](../../../core/battle/battle_projection.gd#L16) 16~20·68~85행 아군 보급/공급원, 상태·결과/roster. [Deck](../../../hud/ui_kit/command_deck.gd#L488) 488~502행 적벽 고정 목표/증원 토글, 1135~1170행 보급함 메뉴. [FleetBattle3D](../../../scripts/FleetBattle3D.gd#L664) 699·728행 증원·종료 사건 소비, 432~436행 진행 중 복귀는 null 결과, 종료 후 BattleOutcome 변환. [ResultScreen](../../../hud/ui_kit/deck_screens.gd#L619) 619~649행 bool 승패와 요약. [BattleOutcome](../../../scripts/world/battle_outcome.gd#L26) 26~65행 raw st 사실과 레거시 결산 변환. [WorldMap](../../../view/world/world_map_screen.gd#L622) 622~654행 천하 지도 결과/표시. | 현재 가동·보급·증원 단계·철수·결과 이유를 side-filter 투영과 ordered event로 공급한다. 두 화면이 한 결산을 읽고 성공/철수/실패를 구별해야 한다. 기존 HUD boolean과 공용 결과 변환의 그대로 사용은 증거 부족. |
| P03 현재 지원 | [Adapter](../../../core/battle/operation_runtime_adapter.gd#L20) 20~30·72~78행 checkpoint 거부, owner 신규 생성. [PrivateState](../../../core/battle/operation_private_state.gd#L79) 79~106행 reinf 및 victory/morale 등 설정 제한. 206~256행 명령·전진·사건/투영 owner 접점, 432행 복원 상태에서 reinf 거부. | 재개와 무관하게 첫 신규 캠페인 owner의 지원 프로필/커밋을 먼저 계약해야 한다. 메모리 복원 증거를 신규 작전 지원으로 계산할 수 없다. |

## 소유권 확인

- P02 채팅 `01a1ac09-125c-71d0-b13b-721727506c85` 최신 읽기 확인은 마지막 K6 미실행·후보 미적용 및 정적 합성 준비 범위다. [P02/P03 공동 소유권](../../../tmp/p02-ninth-20261108/P02-P03-OWNERSHIP-20261109.md) · [공유 경계](../../../tmp/p02-ninth-20261108/P02-P03-BRIDGE-BOUNDARY-20261109.md)
- P03 채팅 `01a1ac0f-b2b6-7891-820d-0701e4f48536` 최신 읽기 확인은 독립 정적 마감까지다. 실제 운영 복원은 미실행이며 지원 프로필·복원 진입점·첫 프레임/사건 게시와 공유 쓰기 창이 선행한다. [P03 정적 준비 결과](../../../tmp/p03-product-restore-readiness-20261109/READINESS.md)
- 향후 실제 쓰기 전에 hunk·입력 closure·기준선 해시·순서·증거 귀속을 다시 맞춘다. 이번 조각에는 공유 코드·데이터·체크리스트 수정, Git 변경, HTML·editor import, 제품/GUI 입력이 없다.
