# P03 활성 DecisionBoard 제품 도달 경계 사전등록

작업자 Sol, 별도 검토 Terra. 기존 PLAN.md는 소유 미확인으로 보존한다. 기준 Git과 초기 핵심 입력은 WORKER-START-GIT.txt, WORKER-START-HEAD.txt, WORKER-START-SHA.json. Git 상태에서 P02 GUI shader cache 두 경로의 Windows 길이 경고가 발생해 해당 하위 경로는 감사 분모에서 제외한다. 승인 전 런타임 구현과 실행을 보류한다.

## 조사 근거 및 판정 구분

- 제품 3D 호스트는 기본 적벽 프로필을 읽고 후보를 `BattleSim.new`로 만들며, 게시에서 `sim = candidate.sim`으로 채택한다. 기본 자동 편성은 Organization.load_auto, 명시 편성은 ScenarioProfile.load_profile 후 Organization.apply 경로다. 관련 소스 scripts/FleetBattle3D.gd:21,276–323 및 core/battle/battle_sim.gd:106–108. DecisionBoard 생성 조건은 비어 있지 않은 `rs.rt("decision_cards", {})`다.
- 제한 owner 생성은 비어 있지 않은 scenario를 unsupported_scenario로 거부하며, owner를 구성한 뒤 _bindings도 확인한다. capture는 활성 모듈을 검사한다. restore_completed는 _guard 후 새 후보를 prepare하고 같은 context를 검사해 교체한다. 이 과정에서 기존 owner의 _bindings를 확인하는 분기는 없다. 근거 core/battle/operation_private_state.gd:87,146–187,287,361–383.
- 생산 GDScript 정적 호출 조사에서 restore_completed 직접 호출은 찾지 못했다. 3D 호스트 직접 BattleSim, 제한 자동결산 adapter, fresh replay는 각각 별개다. 동적 호출·미래 배선·사용자 승인 정책의 부재까지 이 조사로 확정하지 않는다.
- 기존 forced fixture에서 얻은 정확 capture 거부와 same-context restore 성공/소실은 RESULT.md와 REVIEW-CLOSEOUT.md를 보존해 인용한다. 정상 제품에서 제한 owner 활성 모듈까지 도달하거나 정책 위반이라는 주장은 관측 범위를 넘는다.

## 명명 검사 3개

1. `production_constructor_decision_board` — 3D 기본 적벽의 실제 loader(자동 편성 경로)를 통해 프로필을 만들고 정본 BattleSim을 직접 생성한다. 데이터 원본의 비어 있지 않은 decision_cards, 생성된 정본 DecisionBoard script identity와 sim 역참조를 검증한다. 호스트 UI 게시·카드 수명은 범위 밖이다.
2. `restricted_adapter_baseline_restore` — 기존 POC fixture 패턴의 입력으로 adapter 생성, ready, DecisionBoard null, 정상 C0 capture, 한 tick advance 및 same-context restore를 확인한다. 정상 교체 후 tick 0과 Decisions null, busy 해제도 확인한다.
3. `restricted_adapter_decision_scenario_rejection` — 2의 동일 입력 복사에서 scenario 하나만 추가하고 1의 적벽 결정 카드 데이터를 사용한다. 정확한 adapter 반환 `{"ok":false,"error":"unsupported_scenario","path":"profile"}`와 owner 미반환, 입력 deep equality를 확인한다. 전체 적벽 프로필의 첫 거부는 주장하지 않는다.

## 5-a 및 독립 수용

전용 .gdignore와 headless script, 이전 Windows Job 방식을 재사용한다. Godot 종료는 실제 코드, stderr/stdout과 로그 오라클로 확인한다. 실행 전후 production/probe 의존성, 정본 class map, Godot 본체와 console의 SHA 및 HEAD를 기록한다. canonical resource_path와 세 검사 모두, 스크립트 오류·엔진 오류·누수 없음이 필요하다. timeout은 실제 실행 실패로 보존하고 전체 K=3 시도 한도, 실행별 원문 로그 및 수정 사유를 남긴다. 5-b 및 closeout은 별도 Terra. 동시 P02 경로는 시작/종료 차이에서 별도 분류한다. 제품·공유 진행표 변경 없이 전용 결과·인계만 쓴다.

전체 P03/I01/I01b/A04~A06 NOT_READY, O07 OPEN, 외부 저장 스키마 UNCLASSIFIED.
